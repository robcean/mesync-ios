//
//  HabitFormView.swift
//  meSync
//
//  Formulario para crear y editar hábitos
//

import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    
    // Habit data
    @State private var habitData = HabitData()
    @State private var selectedFrequency: HabitFrequency = .noRepetition
    
    // Daily repetition
    @State private var dailyInterval: Int = 1
    
    // Weekly repetition
    @State private var weeklyInterval: Int = 1
    @State private var selectedWeekdays: Set<Int> = []
    
    // Monthly repetition
    @State private var monthlyInterval: Int = 1
    @State private var selectedDayOfMonth: Int = 1
    
    // Custom repetition
    @State private var customDays: Set<Int> = []
    
    // Focus management
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // Computed properties
    private var isEditing: Bool {
        quickAddState.isEditing
    }
    
    private var formTitle: String {
        quickAddState.formTitle
    }
    
    private var shouldShowDeleteButton: Bool {
        isEditing || !habitData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    formFields
                    dateTimeSection
                    frequencySection
                    
                    // Conditional fields based on frequency
                    if selectedFrequency == .daily {
                        dailyIntervalField
                    } else if selectedFrequency == .weekly {
                        weeklyFields
                    } else if selectedFrequency == .monthly {
                        monthlyFields
                    } else if selectedFrequency == .custom {
                        customFields
                    }
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .standardPadding()
            }
            
            // Action Buttons
            actionButtons
        }
        .onAppear {
            setupForm()
            
            // Focus on name field when form appears
            isNameFocused = true
        }
        .onChange(of: selectedFrequency) { oldValue, newValue in
            habitData.frequency = newValue
        }
        .onChange(of: dailyInterval) { oldValue, newValue in
            habitData.dailyInterval = newValue
        }
        .onChange(of: weeklyInterval) { oldValue, newValue in
            habitData.weeklyInterval = newValue
        }
        .onChange(of: selectedWeekdays) { oldValue, newValue in
            habitData.selectedWeekdays = Array(newValue).sorted()
        }
        .onChange(of: monthlyInterval) { oldValue, newValue in
            habitData.monthlyInterval = newValue
        }
        .onChange(of: selectedDayOfMonth) { oldValue, newValue in
            habitData.selectedDayOfMonth = max(1, min(31, newValue))
        }
        .onChange(of: customDays) { oldValue, newValue in
            habitData.customDays = Array(newValue).sorted()
        }
    }
    
    // MARK: - Form Header
    private var formHeader: some View {
        HStack {
            Text(formTitle)
                .sectionTitleStyle()
            
            Spacer()
        }
        .headerContainerStyle()
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: AppSpacing.lg) {
            // Name Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Name")
                    .subtitleStyle()
                
                TextField("Enter habit name", text: $habitData.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description")
                    .subtitleStyle()
                
                DynamicHeightTextEditor(
                    text: $habitData.habitDescription,
                    placeholder: "Enter habit description"
                )
                .focused($isDescriptionFocused)
            }
        }
    }
    
    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Date and Time")
                .subtitleStyle()
            
            DatePicker(
                "Select date and time",
                selection: $habitData.remindAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Repeat")
                .subtitleStyle()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach([HabitFrequency.noRepetition, .daily, .weekly, .monthly, .custom], id: \.self) { frequency in
                        frequencyChip(for: frequency)
                    }
                }
                .padding(.horizontal, 1) // Small padding to ensure content isn't cut off
            }
        }
    }
    
    private func frequencyChip(for frequency: HabitFrequency) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFrequency = frequency
                
                // Auto-select current day when choosing weekly
                if frequency == .weekly && selectedWeekdays.isEmpty {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: Date())
                    let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to Monday=1 format
                    selectedWeekdays.insert(adjustedWeekday)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedFrequency == frequency ? .white : AppColors.tertiaryText)
                
                Text(frequency.rawValue)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(selectedFrequency == frequency ? .white : AppColors.primaryText)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                selectedFrequency == frequency ? AppColors.primary : AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(
                        selectedFrequency == frequency ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    private func frequencyButton(for frequency: HabitFrequency) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFrequency = frequency
                
                // Auto-select current day when choosing weekly
                if frequency == .weekly && selectedWeekdays.isEmpty {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: Date())
                    let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert to Monday=1 format
                    selectedWeekdays.insert(adjustedWeekday)
                }
            }
        } label: {
            HStack {
                Image(systemName: selectedFrequency == frequency ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedFrequency == frequency ? AppColors.primary : AppColors.tertiaryText)
                
                Text(frequency.rawValue)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                selectedFrequency == frequency ? AppColors.primary.opacity(0.1) : AppColors.cardBackground,
                in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(
                        selectedFrequency == frequency ? AppColors.primary : AppColors.secondaryText.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    private var dailyIntervalField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Every")
                .subtitleStyle()
            
            HStack {
                TextField("1", value: $dailyInterval, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                
                Text(dailyInterval == 1 ? "day" : "days")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Weekly Fields
    private var weeklyFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Weekly interval
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Every")
                    .subtitleStyle()
                
                HStack {
                    TextField("1", value: $weeklyInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text(weeklyInterval == 1 ? "week" : "weeks")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
            
            // Weekday selector
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("On days")
                    .subtitleStyle()
                
                weekdaySelector
            }
        }
    }
    
    private var weekdaySelector: some View {
        let weekdays = [
            (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"),
            (5, "Fri"), (6, "Sat"), (7, "Sun")
        ]
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(weekdays, id: \.0) { day, label in
                Button(action: {
                    if selectedWeekdays.contains(day) {
                        selectedWeekdays.remove(day)
                    } else {
                        selectedWeekdays.insert(day)
                    }
                }) {
                    Text(label)
                        .font(AppTypography.caption)
                        .foregroundStyle(selectedWeekdays.contains(day) ? .white : AppColors.primaryText)
                        .frame(width: 40, height: 32)
                        .background(
                            selectedWeekdays.contains(day) ? AppColors.primary : AppColors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                .stroke(
                                    selectedWeekdays.contains(day) ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .pressableStyle()
            }
        }
    }
    
    // MARK: - Monthly Fields
    private var monthlyFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Monthly interval
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Every")
                    .subtitleStyle()
                
                HStack {
                    TextField("1", value: $monthlyInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text(monthlyInterval == 1 ? "month" : "months")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
            
            // Day of month selector
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("On day")
                    .subtitleStyle()
                
                HStack {
                    TextField("1", value: $selectedDayOfMonth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    
                    Text("of the month")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Custom Fields
    private var customFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Select days of the month")
                .subtitleStyle()
            
            customDaySelector
        }
    }
    
    private var customDaySelector: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
            ForEach(1...31, id: \.self) { day in
                Button(action: {
                    if customDays.contains(day) {
                        customDays.remove(day)
                    } else {
                        customDays.insert(day)
                    }
                }) {
                    Text("\(day)")
                        .font(AppTypography.caption)
                        .foregroundStyle(customDays.contains(day) ? .white : AppColors.primaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            customDays.contains(day) ? AppColors.primary : AppColors.cardBackground,
                            in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                .stroke(
                                    customDays.contains(day) ? AppColors.primary : AppColors.secondaryText.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .pressableStyle()
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                // Cancel Button
                Button("Cancel") {
                    cancelAction()
                }
                .secondaryActionButtonStyle()
                .pressableStyle()
                
                // Save Button
                Button("Save") {
                    saveHabit()
                }
                .primaryActionButtonStyle()
                .pressableStyle()
            }
            
            // Delete Button (conditional)
            if shouldShowDeleteButton {
                Button("Delete") {
                    deleteHabit()
                }
                .destructiveButtonStyle()
                .pressableStyle()
            }
        }
        .standardPadding()
        .background(AppColors.headerMaterial)
    }
    
    // MARK: - Actions
    private func cancelAction() {
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.cancel()
        }
    }
    
    // MARK: - Methods
    private func setupForm() {
        if let editingHabit = editingHabit {
            // Editing existing habit
            habitData = editingHabit
            selectedFrequency = editingHabit.frequency
            dailyInterval = editingHabit.dailyInterval
            weeklyInterval = editingHabit.weeklyInterval
            selectedWeekdays = Set(editingHabit.selectedWeekdays)
            monthlyInterval = editingHabit.monthlyInterval
            selectedDayOfMonth = editingHabit.selectedDayOfMonth
            customDays = Set(editingHabit.customDays)
        } else {
            // Creating new habit
            habitData = HabitData()
            selectedFrequency = .noRepetition
            dailyInterval = 1
            weeklyInterval = 1
            selectedWeekdays = []
            monthlyInterval = 1
            selectedDayOfMonth = 1
            customDays = []
        }
    }
    
    // MARK: - Editing state helper
    private var editingHabit: HabitData? {
        if case .habitForm(let habit) = quickAddState {
            return habit
        }
        return nil
    }
    
    private func saveHabit() {
        // Validate required fields
        guard !habitData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // TODO: Show validation error
            return
        }
        
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        
        // Update habit data with current values
        habitData.frequency = selectedFrequency
        habitData.dailyInterval = dailyInterval
        habitData.weeklyInterval = weeklyInterval
        habitData.selectedWeekdays = Array(selectedWeekdays).sorted()
        habitData.monthlyInterval = monthlyInterval
        habitData.selectedDayOfMonth = selectedDayOfMonth
        habitData.customDays = Array(customDays).sorted()
        
        if isEditing {
            // Update existing habit
            do {
                try modelContext.save()
                print("Habit updated successfully")
            } catch {
                print("Error updating habit: \(error)")
            }
        } else {
            // Create new habit
            modelContext.insert(habitData)
            
            do {
                try modelContext.save()
                print("Habit created successfully")
            } catch {
                print("Error creating habit: \(error)")
            }
        }
        
        // Close form
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteHabit() {
        guard isEditing else { return }
        
        if let editingHabit = editingHabit {
            // Delete from SwiftData
            modelContext.delete(editingHabit)
            
            // Save context
            do {
                try modelContext.save()
                print("Habit deleted successfully")
            } catch {
                print("Error deleting habit: \(error)")
                // TODO: Show error alert
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .habitForm()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: HabitData.self, configurations: config)
    
    HabitFormView(quickAddState: $quickAddState)
        .modelContainer(container)
} 