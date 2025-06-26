//
//  InstanceStateManager.swift
//  meSync
//
//  Manages the state of habit and medication instances across views
//

import SwiftUI

@MainActor
class InstanceStateManager: ObservableObject {
    static let shared = InstanceStateManager()
    
    @Published var habitInstanceStates: [String: (isCompleted: Bool, isSkipped: Bool, completedAt: Date?, skippedAt: Date?)] = [:]
    @Published var medicationInstanceStates: [String: (isCompleted: Bool, isSkipped: Bool, completedAt: Date?, skippedAt: Date?)] = [:]
    
    private init() {
        loadStates()
    }
    
    // MARK: - State Management
    func updateHabitState(for key: String, isCompleted: Bool, isSkipped: Bool, completedAt: Date?, skippedAt: Date?) {
        habitInstanceStates[key] = (isCompleted: isCompleted, isSkipped: isSkipped, completedAt: completedAt, skippedAt: skippedAt)
        saveStates()
    }
    
    func updateMedicationState(for key: String, isCompleted: Bool, isSkipped: Bool, completedAt: Date?, skippedAt: Date?) {
        medicationInstanceStates[key] = (isCompleted: isCompleted, isSkipped: isSkipped, completedAt: completedAt, skippedAt: skippedAt)
        saveStates()
    }
    
    // MARK: - Persistence (Future implementation)
    private func loadStates() {
        // TODO: Load from UserDefaults or Core Data
        // For now, states are only stored in memory
    }
    
    private func saveStates() {
        // TODO: Save to UserDefaults or Core Data
        // For now, states are only stored in memory
    }
    
    // MARK: - Cleanup
    func cleanupOldStates() {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        // Remove states older than 7 days
        habitInstanceStates = habitInstanceStates.filter { key, _ in
            // Extract date from key format: "UUID_yyyy-MM-dd"
            let components = key.split(separator: "_")
            if components.count >= 2 {
                let dateString = String(components[1])
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    return date >= sevenDaysAgo
                }
            }
            return false
        }
        
        medicationInstanceStates = medicationInstanceStates.filter { key, _ in
            // Extract date from key format: "UUID_yyyy-MM-dd_doseN"
            let components = key.split(separator: "_")
            if components.count >= 2 {
                let dateString = String(components[1])
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    return date >= sevenDaysAgo
                }
            }
            return false
        }
    }
}