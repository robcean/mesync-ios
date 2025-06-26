//
//  TaskFormView.swift
//  meSync
//
//  Formulario reutilizable para crear y editar tareas
//

import SwiftUI
import SwiftData

struct TaskFormView: View {
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    
    // Form data
    @State private var taskData: TaskData
    @State private var selectedPriority: TaskPriority
    
    // UI State
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
        isEditing || !taskData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initializer
    init(quickAddState: Binding<QuickAddState>) {
        self._quickAddState = quickAddState
        
        // Extract editing task data if available
        if case .taskForm(let editingTask) = quickAddState.wrappedValue,
           let task = editingTask {
            self._taskData = State(initialValue: task)
            self._selectedPriority = State(initialValue: task.priority)
        } else {
            self._taskData = State(initialValue: TaskData())
            self._selectedPriority = State(initialValue: .medium)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            formHeader
            
            // Form Content
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    formFields
                    prioritySection
                    dateTimeSection
                    
                    Spacer(minLength: AppSpacing.xxxl)
                }
                .standardPadding()
            }
            
            // Action Buttons
            actionButtons
        }
        .onAppear {
            // Always sync priority on appear
            selectedPriority = taskData.priority
            
            // Focus on name field when form appears
            isNameFocused = true
        }
        .onChange(of: selectedPriority) { oldValue, newValue in
            taskData.priority = newValue
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
                
                TextField("Enter task name", text: $taskData.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Description")
                    .subtitleStyle()
                
                DynamicHeightTextEditor(
                    text: $taskData.taskDescription,
                    placeholder: "Enter task description"
                )
                .focused($isDescriptionFocused)
            }
        }
    }
    
    // MARK: - Priority Section
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Priority")
                .subtitleStyle()
            
            HStack(spacing: AppSpacing.md) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    priorityButton(for: priority)
                }
            }
        }
    }
    
    private func priorityButton(for priority: TaskPriority) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPriority = priority
            }
        } label: {
            Text(priority.rawValue)
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundStyle(selectedPriority == priority ? .white : AppColors.primaryText)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    selectedPriority == priority ? AppColors.primary : AppColors.cardBackground,
                    in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                )
        }
        .pressableStyle()
    }
    
    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Date and Time")
                .subtitleStyle()
            
            DatePicker(
                "Due Date",
                selection: $taskData.dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
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
    
    // MARK: - Actions
    private func cancelAction() {
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.cancel()
        }
    }
    
    private func saveAction() {
        // Validate required fields
        guard !taskData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // TODO: Show validation error
            return
        }
        
        // Dismiss keyboard
        isNameFocused = false
        isDescriptionFocused = false
        
        // Save to SwiftData
        if isEditing {
            // Update existing task - the taskData is already being modified
            // SwiftData will automatically track changes
        } else {
            // Create new task
            let newTask = TaskData(
                name: taskData.name.trimmingCharacters(in: .whitespacesAndNewlines),
                taskDescription: taskData.taskDescription,
                priority: taskData.priority,
                dueDate: taskData.dueDate
            )
            modelContext.insert(newTask)
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Error saving task: \(error)")
            // TODO: Show error alert
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
    
    private func deleteAction() {
        guard isEditing else { return }
        
        // Delete from SwiftData
        modelContext.delete(taskData)
        
        // Save context
        do {
            try modelContext.save()
            print("Task deleted successfully")
        } catch {
            print("Error deleting task: \(error)")
            // TODO: Show error alert
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            quickAddState.hide()
        }
    }
}

// MARK: - Preview
#Preview("Creating Task") {
    @Previewable @State var quickAddState: QuickAddState = .taskForm()
    
    return TaskFormView(quickAddState: $quickAddState)
}

#Preview("Editing Task") {
    @Previewable @State var quickAddState: QuickAddState = .taskForm(editingTask: TaskData(
        name: "Sample Task",
        taskDescription: "This is a sample task for testing the edit functionality.",
        priority: .high,
        dueDate: Date().addingTimeInterval(3600)
    ))
    
    return TaskFormView(quickAddState: $quickAddState)
} 