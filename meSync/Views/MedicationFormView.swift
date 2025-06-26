//
//  MedicationFormView.swift
//  meSync
//
//  Formulario para crear y editar medicamentos
//

import SwiftUI
import SwiftData

struct MedicationFormView: View {
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    
    // Form data
    @State private var medicationData: MedicationData
    @State private var selectedFrequency: MedicationFrequency
    @State private var timesPerDay: Int
    @State private var reminderTimes: [Date] = []
    
    // UI State
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var isInstructionsFocused: Bool
    @State private var showTakeNowAlert = false
    
    // Computed properties
    private var isEditing: Bool {
        quickAddState.isEditing
    }
    
    private var formTitle: String {
        quickAddState.formTitle
    }
    
    private var shouldShowDeleteButton: Bool {
        isEditing || !medicationData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initializer
    init(quickAddState: Binding<QuickAddState>) {
        self._quickAddState = quickAddState
        
        // Extract editing medication data if available
        if case .medicationForm(let editingMedication) = quickAddState.wrappedValue,
           let medication = editingMedication {
            self._medicationData = State(initialValue: medication)
            self._selectedFrequency = State(initialValue: medication.frequency)
            self._timesPerDay = State(initialValue: medication.timesPerDay)
            self._reminderTimes = State(initialValue: medication.reminderTimes)
        } else {
            // Always create a fresh instance for new medications
            self._medicationData = State(initialValue: MedicationData())
            self._selectedFrequency = State(initialValue: .daily)
            self._timesPerDay = State(initialValue: 1)
            self._reminderTimes = State(initialValue: [Date()])
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Take Now Button (only when editing)
                    if isEditing {
                        takeNowButton
                    }
                    
                    formFields
                    timesPerDaySection
                    reminderTimesSection
                    
                    // Unscheduled doses history (only when editing and has doses)
                    if isEditing && !medicationData.unscheduledDoses.isEmpty {
                        unscheduledDosesSection
                    }
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .standardPadding()
            }
            
            // Action Buttons
            actionButtons
        }
        .onAppear {
            // Always sync frequency on appear
            selectedFrequency = medicationData.frequency
            timesPerDay = medicationData.timesPerDay
            
            // Initialize reminder times if empty
            if reminderTimes.isEmpty {
                reminderTimes = Array(repeating: Date(), count: timesPerDay)
            }
            
            // Focus on name field when form appears
            isNameFocused = true
        }
        .onChange(of: timesPerDay) { oldValue, newValue in
            medicationData.timesPerDay = newValue
            updateReminderTimes(for: newValue)
        }
        .overlay(alignment: .top) {
            if showTakeNowAlert {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    
                    Text("Dose recorded successfully")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color.green, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                .padding(.top, AppSpacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
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
                
                TextField("Enter medication name", text: $medicationData.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description")
                    .subtitleStyle()
                
                DynamicHeightTextEditor(
                    text: $medicationData.medicationDescription,
                    placeholder: "What is this medication for?"
                )
                .focused($isDescriptionFocused)
            }
            
            // Instructions Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Instructions")
                    .subtitleStyle()
                
                DynamicHeightTextEditor(
                    text: $medicationData.instructions,
                    placeholder: "How to take this medication"
                )
                .focused($isInstructionsFocused)
            }
        }
    }
    
    // MARK: - Take Now Button
    private var takeNowButton: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                takeNowAction()
            } label: {
                HStack {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 20))
                    
                    Text("Take Now")
                        .font(AppTypography.bodyMedium)
                    
                    Spacer()
                    
                    Text("Record unscheduled dose")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .foregroundStyle(.white)
                .padding(AppSpacing.lg)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
            .pressableStyle()
            
            if let lastDose = medicationData.unscheduledDoses.last {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    
                    Text("Last unscheduled dose: \(lastDose, formatter: timeFormatter)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Unscheduled Doses Section
    private var unscheduledDosesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Unscheduled Doses Today")
                .subtitleStyle()
            
            VStack(spacing: AppSpacing.sm) {
                let todayDoses = medicationData.unscheduledDoses.filter { Calendar.current.isDateInToday($0) }
                
                ForEach(todayDoses.sorted(by: >), id: \.self) { dose in
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(AppColors.tertiaryText)
                        
                        Text(dose, formatter: timeFormatter)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.primaryText)
                        
                        Spacer()
                        
                        Text("Extra dose")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
            }
        }
    }
    
    // MARK: - Times Per Day Section
    private var timesPerDaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Times per day")
                .subtitleStyle()
            
            HStack(spacing: AppSpacing.md) {
                ForEach([1, 2, 3, 4], id: \.self) { times in
                    timesPerDayButton(for: times)
                }
            }
        }
    }
    
    private func timesPerDayButton(for times: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                timesPerDay = times
            }
        } label: {
            Text(times == 4 ? "4+" : "\(times)")
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundStyle(timesPerDay == times ? .white : AppColors.primaryText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    timesPerDay == times ? AppColors.primary : AppColors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
        .pressableStyle()
    }
    
    // MARK: - Reminder Times Section
    private var reminderTimesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Reminder times")
                .subtitleStyle()
            
            VStack(spacing: AppSpacing.md) {
                ForEach(0..<timesPerDay, id: \.self) { index in
                    HStack {
                        Text("Dose \(index + 1)")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.secondaryText)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: binding(for: index),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
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
                    saveAction()
                }
                .primaryActionButtonStyle()
                .pressableStyle()
            }
            
            // Delete Button (conditional)
            if shouldShowDeleteButton {
                Button("Delete") {
                    deleteAction()
                }
                .destructiveButtonStyle()
                .pressableStyle()
            }
        }
        .standardPadding()
        .background(AppColors.headerMaterial)
    }
    
    // MARK: - Date Formatter
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
    
    // MARK: - Actions
    private func takeNowAction() {
        // Record the unscheduled dose
        medicationData.unscheduledDoses.append(Date())
        
        // Save to SwiftData
        do {
            try modelContext.save()
            print("Unscheduled dose recorded successfully")
        } catch {
            print("Error recording unscheduled dose: \(error)")
            // TODO: Show error alert
        }
        
        // Show visual feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            showTakeNowAlert = true
        }
        
        // Close the form after a short delay to show the alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                quickAddState.hide()
            }
        }
    }
    
    private func cancelAction() {
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        isInstructionsFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.cancel()
        }
    }
    
    private func saveAction() {
        // Validate required fields
        guard !medicationData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // TODO: Show validation error
            return
        }
        
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        isInstructionsFocused = false
        
        // Update medication data
        medicationData.frequency = selectedFrequency
        medicationData.timesPerDay = timesPerDay
        medicationData.reminderTimes = reminderTimes
        
        // Save to SwiftData
        if isEditing {
            // Update existing medication - the medicationData is already being modified
            // SwiftData will automatically track changes
        } else {
            // Create new medication
            let newMedication = MedicationData(
                name: medicationData.name.trimmingCharacters(in: .whitespacesAndNewlines),
                medicationDescription: medicationData.medicationDescription,
                instructions: medicationData.instructions,
                frequency: selectedFrequency,
                timesPerDay: timesPerDay,
                reminderTimes: reminderTimes
            )
            modelContext.insert(newMedication)
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Error saving medication: \(error)")
            // TODO: Show error alert
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteAction() {
        guard isEditing else { return }
        
        // Delete from SwiftData
        modelContext.delete(medicationData)
        
        // Save context
        do {
            try modelContext.save()
            print("Medication deleted successfully")
        } catch {
            print("Error deleting medication: \(error)")
            // TODO: Show error alert
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    // MARK: - Helper Methods
    private func updateReminderTimes(for count: Int) {
        if count > reminderTimes.count {
            // Add new times
            let toAdd = count - reminderTimes.count
            for i in 0..<toAdd {
                let baseTime = reminderTimes.last ?? Date()
                if let newTime = Calendar.current.date(byAdding: .hour, value: 4 * (i + 1), to: baseTime) {
                    reminderTimes.append(newTime)
                } else {
                    reminderTimes.append(Date())
                }
            }
        } else if count < reminderTimes.count {
            // Remove extra times
            reminderTimes = Array(reminderTimes.prefix(count))
        }
    }
    
    private func binding(for index: Int) -> Binding<Date> {
        Binding(
            get: {
                guard index < reminderTimes.count else { return Date() }
                return reminderTimes[index]
            },
            set: { newValue in
                guard index < reminderTimes.count else { return }
                reminderTimes[index] = newValue
            }
        )
    }
}

// MARK: - Preview
#Preview("Creating Medication") {
    @Previewable @State var quickAddState: QuickAddState = .medicationForm()
    
    return MedicationFormView(quickAddState: $quickAddState)
}

#Preview("Editing Medication") {
    @Previewable @State var quickAddState: QuickAddState = .medicationForm(editingMedication: MedicationData(
        name: "Aspirin",
        medicationDescription: "For headache relief",
        instructions: "Take with food",
        frequency: .twiceDaily,
        timesPerDay: 2,
        reminderTimes: [Date(), Date().addingTimeInterval(43200)]
    ))
    
    return MedicationFormView(quickAddState: $quickAddState)
}