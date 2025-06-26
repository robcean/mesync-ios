//
//  HabitsView.swift
//  meSync
//
//  Vista para mostrar y gestionar hábitos
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Query(sort: \HabitData.name) private var habits: [HabitData]
    @Binding var quickAddState: QuickAddState
    let habitFormCounter: Int
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Habit Form Content (when active)
                habitFormContent
                
                // Habits list
                LazyVStack(spacing: AppSpacing.md) {
                    if habits.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(habits) { habit in
                            HabitRow(
                                habit: habit,
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
    
    // MARK: - Habit Form Content
    @ViewBuilder
    private var habitFormContent: some View {
        if case .habitForm(let editingHabit) = quickAddState {
            HabitFormView(quickAddState: $quickAddState)
                .id("habitForm-\(editingHabit?.id.uuidString ?? "new-\(habitFormCounter)")")
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
            Image(systemName: "repeat")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No habits yet")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text("Tap Add Habit to create your first habit")
                .captionStyle()
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
}

// MARK: - Habit Row Component
struct HabitRow: View {
    let habit: HabitData
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Edit button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .habitForm(editingHabit: habit)
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(AppColors.secondaryText.opacity(0.1), in: Circle())
            }
            .pressableStyle()
            
            // Habit icon
            Image(systemName: "repeat")
                .font(.system(size: 24))
                .foregroundStyle(.green)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1), in: Circle())
            
            // Habit info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(habit.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                
                if !habit.habitDescription.isEmpty {
                    Text(habit.habitDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Frequency info
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                    
                    Text(frequencyDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .habitForm(editingHabit: habit)
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
        .alert("Delete Habit", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete \(habit.name)?")
        }
    }
    
    // MARK: - Computed Properties
    private var frequencyDescription: String {
        switch habit.frequency {
        case .noRepetition:
            return "One time only"
        case .daily:
            return habit.dailyInterval == 1 ? "Daily" : "Every \(habit.dailyInterval) days"
        case .weekly:
            let days = habit.selectedWeekdays.compactMap { weekdayAbbreviation(for: $0) }.joined(separator: ", ")
            let interval = habit.weeklyInterval == 1 ? "" : "Every \(habit.weeklyInterval) weeks: "
            return "\(interval)\(days)"
        case .monthly:
            let interval = habit.monthlyInterval == 1 ? "Monthly" : "Every \(habit.monthlyInterval) months"
            return "\(interval) on day \(habit.selectedDayOfMonth)"
        case .custom:
            let days = habit.customDays.map { "\($0)" }.joined(separator: ", ")
            return "Days: \(days)"
        }
    }
    
    // MARK: - Helper Methods
    private func weekdayAbbreviation(for day: Int) -> String? {
        switch day {
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        case 7: return "Sun"
        default: return nil
        }
    }
    
    // MARK: - Actions
    private func deleteHabit() {
        modelContext.delete(habit)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting habit: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: HabitData.self, configurations: config)
    
    // Add sample data
    let sampleHabit1 = HabitData(
        name: "Morning Exercise",
        habitDescription: "30 minutes of cardio",
        frequency: .daily,
        remindAt: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    )
    
    let sampleHabit2 = HabitData(
        name: "Read Book",
        habitDescription: "Read for personal growth",
        frequency: .weekly,
        remindAt: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
    )
    sampleHabit2.selectedWeekdays = [1, 3, 5] // Mon, Wed, Fri
    
    container.mainContext.insert(sampleHabit1)
    container.mainContext.insert(sampleHabit2)
    
    return HabitsView(
        quickAddState: $quickAddState,
        habitFormCounter: 0
    )
    .modelContainer(container)
}