//
//  QuickAddState.swift
//  meSync
//
//  Estado centralizado para el flujo Quick Add
//

import Foundation
import SwiftData

// MARK: - Quick Add State
enum QuickAddState: Equatable {
    case hidden
    case accordion
    case taskForm(editingTask: TaskData? = nil)
    case habitForm(editingHabit: HabitData? = nil)
    case medicationForm(editingMedication: MedicationData? = nil)
    
    // MARK: - Computed Properties
    
    /// Indica si algún formulario está visible
    var isFormVisible: Bool {
        switch self {
        case .taskForm, .habitForm, .medicationForm:
            return true
        case .hidden, .accordion:
            return false
        }
    }
    
    /// Indica si el acordeón está visible
    var isAccordionVisible: Bool {
        if case .accordion = self {
            return true
        }
        return false
    }
    
    /// Indica si está en modo edición
    var isEditing: Bool {
        switch self {
        case .taskForm(let task):
            return task != nil
        case .habitForm(let habit):
            return habit != nil
        case .medicationForm(let medication):
            return medication != nil
        case .hidden, .accordion:
            return false
        }
    }
    
    /// Título del formulario actual
    var formTitle: String {
        switch self {
        case .taskForm(let task):
            return task != nil ? "Editing Task" : "Creating Task"
        case .habitForm(let habit):
            return habit != nil ? "Editing Habit" : "Creating Habit"
        case .medicationForm(let medication):
            return medication != nil ? "Editing Medication" : "Creating Medication"
        case .hidden, .accordion:
            return ""
        }
    }
    
    // MARK: - Transition Methods
    
    /// Transiciones válidas desde el estado actual
    func canTransitionTo(_ newState: QuickAddState) -> Bool {
        switch (self, newState) {
        case (.hidden, .accordion),
             (.accordion, .hidden),
             (.accordion, .taskForm),
             (.accordion, .habitForm),
             (.accordion, .medicationForm),
             (.taskForm, .accordion),
             (.habitForm, .accordion),
             (.medicationForm, .accordion),
             (.taskForm, .hidden),
             (.habitForm, .hidden),
             (.medicationForm, .hidden):
            return true
        default:
            return false
        }
    }
    
    /// Cancela el estado actual y vuelve al anterior apropiado
    mutating func cancel() {
        switch self {
        case .taskForm, .habitForm, .medicationForm:
            self = .accordion
        case .accordion:
            self = .hidden
        case .hidden:
            break // Ya está oculto
        }
    }
    
    /// Oculta todo el Quick Add
    mutating func hide() {
        self = .hidden
    }
}

// MARK: - Data Models
@Model
class TaskData {
    @Attribute(.unique) var id: UUID
    var name: String
    var taskDescription: String
    var priority: TaskPriority
    var dueDate: Date
    var isCompleted: Bool
    var isSkipped: Bool
    
    init(id: UUID = UUID(), name: String = "", taskDescription: String = "", priority: TaskPriority = .medium, dueDate: Date = Date(), isCompleted: Bool = false, isSkipped: Bool = false) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
    }
}

@Model
class HabitData {
    @Attribute(.unique) var id: UUID
    var name: String
    var habitDescription: String
    var frequency: HabitFrequency
    var remindAt: Date
    
    // Daily repetition
    var dailyInterval: Int // Para "Daily": cada X días
    
    // Weekly repetition
    var weeklyInterval: Int // Para "Weekly": cada X semanas
    @Attribute(.externalStorage) private var selectedWeekdaysData: Data?
    
    // Monthly repetition
    var monthlyInterval: Int // Para "Monthly": cada X meses
    var selectedDayOfMonth: Int // 1-31
    
    // Custom repetition
    @Attribute(.externalStorage) private var customDaysData: Data?
    
    // Computed properties for arrays
    var selectedWeekdays: [Int] {
        get {
            guard let data = selectedWeekdaysData else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set {
            selectedWeekdaysData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var customDays: [Int] {
        get {
            guard let data = customDaysData else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set {
            customDaysData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var isCompleted: Bool
    var isSkipped: Bool
    
    init(id: UUID = UUID(), name: String = "", habitDescription: String = "", frequency: HabitFrequency = .noRepetition, remindAt: Date = Date(), dailyInterval: Int = 1, weeklyInterval: Int = 1, selectedWeekdays: [Int] = [], monthlyInterval: Int = 1, selectedDayOfMonth: Int = 1, customDays: [Int] = [], isCompleted: Bool = false, isSkipped: Bool = false) {
        self.id = id
        self.name = name
        self.habitDescription = habitDescription
        self.frequency = frequency
        self.remindAt = remindAt
        self.dailyInterval = dailyInterval
        self.weeklyInterval = weeklyInterval
        self.selectedWeekdaysData = try? JSONEncoder().encode(selectedWeekdays)
        self.monthlyInterval = monthlyInterval
        self.selectedDayOfMonth = selectedDayOfMonth
        self.customDaysData = try? JSONEncoder().encode(customDays)
        self.isCompleted = isCompleted
        self.isSkipped = isSkipped
    }
}

struct MedicationData: Equatable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var reminderTimes: [Date]
    
    init(id: UUID = UUID(), name: String = "", dosage: String = "", frequency: MedicationFrequency = .daily, reminderTimes: [Date] = []) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderTimes = reminderTimes
    }
}

// MARK: - Supporting Enums
enum TaskPriority: String, CaseIterable, Equatable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        case .urgent: return "purple"
        }
    }
}

enum HabitFrequency: String, CaseIterable, Equatable, Codable {
    case noRepetition = "No repetition"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

enum MedicationFrequency: String, CaseIterable, Equatable, Codable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
    case threeTimesDaily = "Three Times Daily"
    case weekly = "Weekly"
    case asNeeded = "As Needed"
}

// MARK: - SwiftData Conformances
extension TaskPriority: Sendable {}
extension HabitFrequency: Sendable {}
extension MedicationFrequency: Sendable {} 