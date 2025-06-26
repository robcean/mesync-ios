//
//  ProgressView.swift
//  meSync
//
//  Vista para mostrar el progreso histórico de items completados y saltados
//

import SwiftUI
import SwiftData

struct ProgressView: View {
    @Query(sort: \TaskData.dueDate) private var tasks: [TaskData]
    @Query(sort: \HabitData.remindAt) private var habits: [HabitData]
    @Query(sort: \MedicationData.name) private var medications: [MedicationData]
    
    // UI State
    @State private var selectedDate = Date()
    @State private var selectedFilter: FilterType = .all
    @State private var currentPage = 0
    @State private var searchText = ""
    private let itemsPerPage = 40
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case habits = "Habits"
        case tasks = "Tasks"
        case medications = "Medications"
    }
    
    // MARK: - Date Range (Last 7 days)
    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Top controls
            topControlsSection
            
            // Items list
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    let items = paginatedItems
                    
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(items, id: \.id) { item in
                            ProgressItemCard(item: item)
                        }
                        
                        // Pagination controls
                        if totalPages > 1 {
                            paginationControls
                        }
                    }
                }
                .standardPadding()
                .padding(.top, AppSpacing.md)
            }
        }
        .background(AppColors.background)
        .onChange(of: selectedDate) { _, _ in
            currentPage = 0  // Reset to first page when date changes
        }
        .onChange(of: selectedFilter) { _, _ in
            currentPage = 0  // Reset to first page when filter changes
        }
        .onChange(of: searchText) { _, _ in
            currentPage = 0  // Reset to first page when search changes
        }
    }
    
    // MARK: - Pagination
    private var paginatedItems: [any ItemProtocol] {
        let allItems = filteredItems
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allItems.count)
        
        guard startIndex < allItems.count else { return [] }
        return Array(allItems[startIndex..<endIndex])
    }
    
    private var totalPages: Int {
        let totalItems = filteredItems.count
        return (totalItems + itemsPerPage - 1) / itemsPerPage
    }
    
    private var paginationControls: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                withAnimation {
                    currentPage = max(0, currentPage - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16))
                    .foregroundStyle(currentPage > 0 ? AppColors.primary : AppColors.tertiaryText)
            }
            .disabled(currentPage == 0)
            
            Text("\(currentPage + 1) of \(totalPages)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
            
            Button {
                withAnimation {
                    currentPage = min(totalPages - 1, currentPage + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(currentPage < totalPages - 1 ? AppColors.primary : AppColors.tertiaryText)
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .padding(.vertical, AppSpacing.lg)
    }
    
    // MARK: - Top Controls Section
    private var topControlsSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Date picker row
            HStack {
                Text("Showing history for:")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        filterChip(for: filter)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.secondaryText)
                    .font(.system(size: 16))
                
                TextField("Search items...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.secondaryText)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.bottom, AppSpacing.md)
        .background(AppColors.background)
    }
    
    
    private func filterChip(for filter: FilterType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if selectedFilter == filter {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                
                Text(filter.rawValue)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(selectedFilter == filter ? .white : AppColors.primaryText)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                selectedFilter == filter ? AppColors.primary : AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(
                        selectedFilter == filter ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    
    // MARK: - Filtered Items
    private var filteredItems: [any ItemProtocol] {
        let calendar = Calendar.current
        var allCompletedItems: [any ItemProtocol] = []
        
        // Generate habit instances for the full 7-day range
        let habitInstances = generateHabitInstances()
        
        // Generate medication instances for the full 7-day range
        let medicationInstances = generateMedicationInstances()
        
        // Filter by selected date and completion status
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        // Filter tasks
        if selectedFilter == .all || selectedFilter == .tasks {
            let filteredTasks = tasks.filter { task in
                // Only include completed or skipped tasks
                (task.isCompleted || task.isSkipped) &&
                // Check if the task's due date falls on the selected date
                task.dueDate >= dayStart && task.dueDate < dayEnd
            }
            allCompletedItems.append(contentsOf: filteredTasks)
        }
        
        // Filter habit instances
        if selectedFilter == .all || selectedFilter == .habits {
            // All instances are already filtered and only completed/skipped ones are included
            allCompletedItems.append(contentsOf: habitInstances)
        }
        
        // Filter medication instances
        if selectedFilter == .all || selectedFilter == .medications {
            // All instances are already filtered and only completed/skipped ones are included
            allCompletedItems.append(contentsOf: medicationInstances)
        }
        
        // Apply search filter if needed
        let searchFilteredItems: [any ItemProtocol]
        if searchText.isEmpty {
            searchFilteredItems = allCompletedItems
        } else {
            let lowercaseSearch = searchText.lowercased()
            searchFilteredItems = allCompletedItems.filter { item in
                item.name.lowercased().contains(lowercaseSearch) ||
                item.itemDescription.lowercased().contains(lowercaseSearch)
            }
        }
        
        // Sort by action timestamp (most recent first)
        return searchFilteredItems.sorted { item1, item2 in
            let time1 = item1.actionTimestamp ?? item1.scheduledTime
            let time2 = item2.actionTimestamp ?? item2.scheduledTime
            return time1 > time2
        }
    }
    
    // MARK: - Dynamic Generation (Extended for 7 days)
    private func generateHabitInstances() -> [HabitInstance] {
        var instances: [HabitInstance] = []
        
        // Only generate instances for the selected date to avoid duplicates and improve performance
        for habit in habits {
            if shouldHabitOccurOn(habit: habit, date: selectedDate) {
                let instance = HabitInstance(from: habit, for: selectedDate)
                
                // Only include if it's completed or skipped (checking the original habit)
                if habit.isCompleted || habit.isSkipped {
                    instance.isCompleted = habit.isCompleted
                    instance.isSkipped = habit.isSkipped
                    instances.append(instance)
                }
            }
        }
        
        return instances
    }
    
    private func generateMedicationInstances() -> [MedicationInstance] {
        var instances: [MedicationInstance] = []
        
        // Only generate instances for the selected date to avoid duplicates and improve performance
        for medication in medications {
            // Only include medications that are completed or skipped
            if medication.isCompleted || medication.isSkipped {
                // Generate instances for each scheduled dose time
                for doseNumber in 1...medication.timesPerDay {
                    let instance = MedicationInstance(
                        from: medication,
                        for: selectedDate,
                        doseNumber: doseNumber
                    )
                    instance.isCompleted = medication.isCompleted
                    instance.isSkipped = medication.isSkipped
                    instances.append(instance)
                }
            }
        }
        
        return instances
    }
    
    private func shouldHabitOccurOn(habit: HabitData, date: Date) -> Bool {
        let calendar = Calendar.current
        let habitStartDate = calendar.startOfDay(for: habit.remindAt)
        let targetDate = calendar.startOfDay(for: date)
        
        guard targetDate >= habitStartDate else { return false }
        
        switch habit.frequency {
        case .noRepetition:
            return calendar.isDate(targetDate, inSameDayAs: habitStartDate)
            
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: habitStartDate, to: targetDate).day ?? 0
            return daysDifference % habit.dailyInterval == 0
            
        case .weekly:
            let weekday = calendar.component(.weekday, from: targetDate)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            
            if habit.selectedWeekdays.contains(adjustedWeekday) {
                let weeksDifference = calendar.dateComponents([.weekOfYear], from: habitStartDate, to: targetDate).weekOfYear ?? 0
                return weeksDifference % habit.weeklyInterval == 0
            }
            return false
            
        case .monthly:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            if dayOfMonth == habit.selectedDayOfMonth {
                let monthsDifference = calendar.dateComponents([.month], from: habitStartDate, to: targetDate).month ?? 0
                return monthsDifference % habit.monthlyInterval == 0
            }
            return false
            
        case .custom:
            let dayOfMonth = calendar.component(.day, from: targetDate)
            return habit.customDays.contains(dayOfMonth)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No completed or skipped items")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text(dateFormatter.string(from: selectedDate))
                .captionStyle()
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Helper Methods
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - Progress Item Card
struct ProgressItemCard: View {
    let item: any ItemProtocol
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Status icon (completed or skipped)
            statusIcon
            
            // Item type icon
            itemTypeIcon
            
            // Main content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)
                
                HStack(spacing: AppSpacing.sm) {
                    // Action time
                    if let actionTime = actionTimeString {
                        Text(actionTime)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    // Item type
                    Text("• \(itemTypeString)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(borderColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Status Icon
    @ViewBuilder
    private var statusIcon: some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
        } else if item.isSkipped {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
        }
    }
    
    // MARK: - Item Type Icon
    @ViewBuilder
    private var itemTypeIcon: some View {
        Group {
            if item is TaskData {
                Image(systemName: "checkmark.square")
                    .foregroundStyle(taskPriorityColor)
            } else if item is HabitData || item is HabitInstance {
                Image(systemName: "repeat")
                    .foregroundStyle(.green)
            } else if item is MedicationData || item is MedicationInstance {
                Image(systemName: "pills.fill")
                    .foregroundStyle(.blue)
            }
        }
        .font(.system(size: 20))
        .frame(width: 30, height: 30)
    }
    
    // MARK: - Computed Properties
    private var actionTimeString: String? {
        guard let timestamp = item.actionTimestamp else {
            return "Scheduled: \(timeFormatter.string(from: item.scheduledTime))"
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: timestamp, to: now)
        
        if let hours = components.hour, hours > 0 {
            return "\(item.isCompleted ? "Completed" : "Skipped") \(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(item.isCompleted ? "Completed" : "Skipped") \(minutes)m ago"
        } else {
            return "\(item.isCompleted ? "Completed" : "Skipped") just now"
        }
    }
    
    private var itemTypeString: String {
        if item is TaskData {
            return "Task"
        } else if item is HabitData || item is HabitInstance {
            return "Habit"
        } else if item is MedicationData || item is MedicationInstance {
            return "Medication"
        }
        return ""
    }
    
    private var taskPriorityColor: Color {
        if let task = item as? TaskData {
            switch task.priority {
            case .urgent: return .purple
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        return AppColors.primary
    }
    
    private var cardBackground: Color {
        if item.isCompleted {
            return Color.green.opacity(0.1)
        } else if item.isSkipped {
            return Color.orange.opacity(0.1)
        }
        return AppColors.cardBackground
    }
    
    private var borderColor: Color {
        if item.isCompleted {
            return .green
        } else if item.isSkipped {
            return .orange
        }
        return AppColors.secondaryText
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}

// MARK: - Preview
#Preview {
    ProgressView()
}