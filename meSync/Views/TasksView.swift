//
//  TasksView.swift
//  meSync
//
//  Vista para mostrar y gestionar tareas
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Query(sort: \TaskData.dueDate) private var tasks: [TaskData]
    @Binding var quickAddState: QuickAddState
    let taskFormCounter: Int
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Task Form Content (when active)
                taskFormContent
                
                // Tasks list
                LazyVStack(spacing: AppSpacing.md) {
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(tasks) { task in
                            TaskRow(
                                task: task,
                                quickAddState: $quickAddState
                            )
                        }
                    }
                }
                .standardPadding()
                .padding(.top, quickAddState == .hidden ? AppSpacing.md : AppSpacing.lg)
            }
        }
        .background(AppColors.background)
        .animation(.easeInOut(duration: 0.3), value: quickAddState)
    }
    
    // MARK: - Task Form Content
    @ViewBuilder
    private var taskFormContent: some View {
        if case .taskForm(let editingTask) = quickAddState {
            TaskFormView(quickAddState: $quickAddState)
                .id("taskForm-\(editingTask?.id.uuidString ?? "new-\(taskFormCounter)")")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .padding(.top, AppSpacing.sm)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No tasks yet")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text("Tap Add Task to create your first task")
                .captionStyle()
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
}

// MARK: - Task Row Component
struct TaskRow: View {
    let task: TaskData
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Edit button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .taskForm(editingTask: task)
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(AppColors.secondaryText.opacity(0.1), in: Circle())
            }
            .pressableStyle()
            
            // Task icon with priority color
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24))
                .foregroundStyle(priorityColor)
                .frame(width: 40, height: 40)
                .background(priorityColor.opacity(0.1), in: Circle())
            
            // Task info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(task.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Due date and priority info
                HStack(spacing: AppSpacing.md) {
                    // Due date
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(dueDateColor)
                        
                        Text(dueDateText)
                            .font(AppTypography.caption)
                            .foregroundStyle(dueDateColor)
                    }
                    
                    // Priority badge
                    Text(task.priority.rawValue)
                        .font(AppTypography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(priorityColor)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.1), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(priorityColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(priorityColor.opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .taskForm(editingTask: task)
                }
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete \(task.name)?")
        }
    }
    
    // MARK: - Computed Properties
    private var priorityColor: Color {
        switch task.priority {
        case .urgent:
            return .purple
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var dueDateColor: Color {
        let calendar = Calendar.current
        let now = Date()
        
        if task.dueDate < now {
            return .red // Overdue
        } else if calendar.isDateInToday(task.dueDate) {
            return .orange // Due today
        } else if calendar.isDateInTomorrow(task.dueDate) {
            return AppColors.primaryText // Due tomorrow
        } else {
            return AppColors.tertiaryText // Future date
        }
    }
    
    private var dueDateText: String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        
        if task.dueDate < now {
            let components = calendar.dateComponents([.day, .hour], from: task.dueDate, to: now)
            if let days = components.day, days > 0 {
                return "\(days) day\(days == 1 ? "" : "s") overdue"
            } else if let hours = components.hour, hours > 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s") overdue"
            } else {
                return "Overdue"
            }
        } else if calendar.isDateInToday(task.dueDate) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Today at \(formatter.string(from: task.dueDate))"
        } else if calendar.isDateInTomorrow(task.dueDate) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Tomorrow at \(formatter.string(from: task.dueDate))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: task.dueDate)
        }
    }
    
    // MARK: - Actions
    private func deleteTask() {
        modelContext.delete(task)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TaskData.self, configurations: config)
    
    // Add sample data
    let sampleTask1 = TaskData(
        name: "Complete Project Report",
        taskDescription: "Finish the quarterly project report and send to team",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date())! // Overdue
    )
    
    let sampleTask2 = TaskData(
        name: "Team Meeting",
        taskDescription: "Weekly sync with the development team",
        priority: .medium,
        dueDate: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())! // Today
    )
    
    let sampleTask3 = TaskData(
        name: "Code Review",
        taskDescription: "Review pull requests from the team",
        priority: .low,
        dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())! // Tomorrow
    )
    
    container.mainContext.insert(sampleTask1)
    container.mainContext.insert(sampleTask2)
    container.mainContext.insert(sampleTask3)
    
    return TasksView(
        quickAddState: $quickAddState,
        taskFormCounter: 0
    )
    .modelContainer(container)
}