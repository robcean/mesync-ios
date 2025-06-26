//
//  MedicationsView.swift
//  meSync
//
//  Vista para mostrar y gestionar medicamentos
//

import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Query(sort: \MedicationData.name) private var medications: [MedicationData]
    @Binding var quickAddState: QuickAddState
    let medicationFormCounter: Int
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Medication Form Content (when active)
                medicationFormContent
                
                // Medications list
                LazyVStack(spacing: AppSpacing.md) {
                    if medications.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(medications) { medication in
                            MedicationRow(
                                medication: medication,
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
    
    // MARK: - Medication Form Content
    @ViewBuilder
    private var medicationFormContent: some View {
        if case .medicationForm(let editingMedication) = quickAddState {
            MedicationFormView(quickAddState: $quickAddState)
                .id("medicationForm-\(editingMedication?.id.uuidString ?? "new-\(medicationFormCounter)")")
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
            Image(systemName: "pills")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text("No medications yet")
                .subtitleStyle()
                .multilineTextAlignment(.center)
            
            Text("Tap Add Meds to create your first medication")
                .captionStyle()
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.vertical, AppSpacing.xxxl)
    }
}

// MARK: - Medication Row Component
struct MedicationRow: View {
    let medication: MedicationData
    @Binding var quickAddState: QuickAddState
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var showTakeNowAlert = false
    
    var body: some View {
        ZStack {
            HStack(spacing: AppSpacing.md) {
            // Edit button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .medicationForm(editingMedication: medication)
                }
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(AppColors.secondaryText.opacity(0.1), in: Circle())
            }
            .pressableStyle()
            
            // Medication icon
            Image(systemName: "pills.fill")
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1), in: Circle())
            
            // Medication info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(medication.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                
                if !medication.medicationDescription.isEmpty {
                    Text(medication.medicationDescription)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                // Dose times
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                    
                    Text(doseTimes)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Take Now button
            Button {
                takeNowAction()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    
                    Text("Take Now")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
            .pressableStyle()
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
            
            // Take Now Alert Banner
            if showTakeNowAlert {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        
                        Text("Dose recorded successfully")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(.white)
                    }
                    .padding()
                    .background(Color.green, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                    .shadow(radius: 4)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .contextMenu {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quickAddState = .medicationForm(editingMedication: medication)
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
        .alert("Delete Medication", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMedication()
            }
        } message: {
            Text("Are you sure you want to delete \(medication.name)?")
        }
    }
    
    // MARK: - Computed Properties
    private var doseTimes: String {
        if medication.timesPerDay == 1 {
            return "Once daily"
        } else {
            let times = medication.reminderTimes.prefix(3).map { time in
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return formatter.string(from: time)
            }
            let timesString = times.joined(separator: ", ")
            
            if medication.reminderTimes.count > 3 {
                return "\(timesString)..."
            }
            return timesString
        }
    }
    
    // MARK: - Actions
    private func takeNowAction() {
        // Record the unscheduled dose
        medication.unscheduledDoses.append(Date())
        
        // Save to SwiftData
        do {
            try modelContext.save()
            print("Unscheduled dose recorded successfully from MedicationRow")
        } catch {
            print("Error recording unscheduled dose: \(error)")
        }
        
        // Show visual feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            showTakeNowAlert = true
        }
        
        // Hide alert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showTakeNowAlert = false
            }
        }
    }
    
    private func deleteMedication() {
        modelContext.delete(medication)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting medication: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var quickAddState: QuickAddState = .hidden
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MedicationData.self, configurations: config)
    
    // Add sample data
    let sampleMedication1 = MedicationData(
        name: "Aspirin",
        medicationDescription: "For headache relief",
        instructions: "Take with food",
        frequency: .daily,
        timesPerDay: 1,
        reminderTimes: [Date()]
    )
    
    let sampleMedication2 = MedicationData(
        name: "Blood Pressure Med",
        medicationDescription: "For hypertension control",
        instructions: "Take on empty stomach",
        frequency: .twiceDaily,
        timesPerDay: 2,
        reminderTimes: [
            Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        ]
    )
    
    container.mainContext.insert(sampleMedication1)
    container.mainContext.insert(sampleMedication2)
    
    return MedicationsView(
        quickAddState: $quickAddState,
        medicationFormCounter: 0
    )
    .modelContainer(container)
}