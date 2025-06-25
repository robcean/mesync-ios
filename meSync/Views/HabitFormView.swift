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
    
    // Editing state
    private var editingHabit: HabitData? {
        if case .habitForm(let habit) = quickAddState {
            return habit
        }
        return nil
    }
    
    private var isEditing: Bool {
        editingHabit != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Name Field
                    nameField
                    
                    // Description Field
                    descriptionField
                    
                    // Date and Time Picker
                    dateTimeField
                    
                    // Frequency Section
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
                }
                .standardHorizontalPadding()
                .padding(.vertical, AppSpacing.lg)
            }
            
            // Action Buttons
            actionButtons
        }
        .background(AppColors.background)
        .onAppear {
            setupForm()
            
            // Focus on name field when form appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFocused = true
            }
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState.cancel()
                }
            }
            .captionStyle()
            .foregroundStyle(AppColors.secondaryText)
            
            Spacer()
            
            Text(quickAddState.formTitle)
                .subtitleStyle()
                .foregroundStyle(AppColors.primaryText)
            
            Spacer()
            
            Button("Save") {
                saveHabit()
            }
            .captionStyle()
            .foregroundStyle(canSave ? AppColors.primary : AppColors.tertiaryText)
            .disabled(!canSave)
        }
        .standardHorizontalPadding()
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(AppColors.secondaryText.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Form Fields
    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Name")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            TextField("Enter habit name", text: $habitData.name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Description")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            TextEditor(text: $habitData.habitDescription)
                .frame(minHeight: 80)
                .padding(AppSpacing.sm)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.secondaryText.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var dateTimeField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Date and Time")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            DatePicker("Select date and time", selection: $habitData.remindAt, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
        }
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Repeat")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
            VStack(spacing: AppSpacing.xs) {
                frequencyButton(for: .noRepetition)
                frequencyButton(for: .daily)
                frequencyButton(for: .weekly)
                frequencyButton(for: .monthly)
                frequencyButton(for: .custom)
            }
        }
    }
    
    private func frequencyButton(for frequency: HabitFrequency) -> some View {
        Button(action: {
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
        }) {
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
                in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        selectedFrequency == frequency ? AppColors.primary.opacity(0.3) : AppColors.secondaryText.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .pressableStyle()
    }
    
    private var dailyIntervalField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Every")
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
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
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
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
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
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
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
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
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
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
                    .captionStyle()
                    .foregroundStyle(AppColors.secondaryText)
                
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
                .captionStyle()
                .foregroundStyle(AppColors.secondaryText)
            
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
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
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
        VStack(spacing: AppSpacing.sm) {
            // Delete button (only when editing)
            if isEditing {
                Button("Delete Habit") {
                    deleteHabit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
                .foregroundStyle(.red)
                .pressableStyle()
            }
        }
        .standardHorizontalPadding()
        .padding(.vertical, AppSpacing.lg)
        .background(AppColors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(AppColors.secondaryText.opacity(0.2)),
            alignment: .top
        )
    }
    
    // MARK: - Computed Properties
    private var canSave: Bool {
        !habitData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    
    private func saveHabit() {
        guard canSave else { return }
        
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
        guard let editingHabit = editingHabit else { return }
        
        modelContext.delete(editingHabit)
        
        do {
            try modelContext.save()
            print("Habit deleted successfully")
        } catch {
            print("Error deleting habit: \(error)")
        }
        
        // Close form
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