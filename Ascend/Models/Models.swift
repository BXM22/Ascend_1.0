import Foundation
import SwiftUI

// MARK: - Exercise Set
struct ExerciseSet: Identifiable, Equatable, Codable {
    let id: UUID
    let setNumber: Int
    let weight: Double
    let reps: Int
    let holdDuration: Int?
    
    init(setNumber: Int, weight: Double, reps: Int, holdDuration: Int? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.holdDuration = holdDuration
    }
    
    static func == (lhs: ExerciseSet, rhs: ExerciseSet) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Exercise Type
enum ExerciseType: Codable {
    case weightReps
    case hold
}

// MARK: - Exercise
struct Exercise: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    var sets: [ExerciseSet]
    var currentSet: Int
    let targetSets: Int
    let exerciseType: ExerciseType
    let targetHoldDuration: Int?
    let alternatives: [String]
    let videoURL: String?
    
    // Convenience property for type
    var type: ExerciseType {
        exerciseType
    }
    
    init(name: String, targetSets: Int, exerciseType: ExerciseType, holdDuration: Int? = nil, alternatives: [String] = [], videoURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.sets = []
        self.currentSet = 1
        self.targetSets = targetSets
        self.exerciseType = exerciseType
        self.targetHoldDuration = holdDuration
        self.alternatives = alternatives
        self.videoURL = videoURL
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Template Exercise
struct TemplateExercise: Identifiable, Codable {
    let id: UUID
    let name: String
    var sets: Int
    var reps: String // Can be "6-8", "10-12", "AMRAP", etc.
    var dropsets: Bool
    var exerciseType: ExerciseType
    var targetHoldDuration: Int?
    
    init(id: UUID = UUID(), name: String, sets: Int = 3, reps: String = "8-10", dropsets: Bool = false, exerciseType: ExerciseType = .weightReps, targetHoldDuration: Int? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.dropsets = dropsets
        self.exerciseType = exerciseType
        self.targetHoldDuration = targetHoldDuration
    }
}

// MARK: - Workout Template
struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    var exercises: [TemplateExercise] // Changed from [String] to [TemplateExercise]
    let estimatedDuration: Int
    var intensity: WorkoutIntensity? // Optional intensity level
    
    // Legacy initializer for backward compatibility
    init(id: UUID = UUID(), name: String, exercises: [String], estimatedDuration: Int) {
        self.id = id
        self.name = name
        self.estimatedDuration = estimatedDuration
        self.intensity = nil
        // Convert old format to new format
        self.exercises = exercises.map { TemplateExercise(name: $0) }
    }
    
    // New initializer with TemplateExercise array
    init(id: UUID = UUID(), name: String, exercises: [TemplateExercise], estimatedDuration: Int, intensity: WorkoutIntensity? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.intensity = intensity
    }
}

// MARK: - Workout Intensity
enum WorkoutIntensity: String, Codable, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"
    case extreme = "Extreme"
    
    var description: String {
        switch self {
        case .light: return "Easy recovery day"
        case .moderate: return "Standard training"
        case .intense: return "High effort workout"
        case .extreme: return "Maximum intensity"
        }
    }
}

// MARK: - Workout
struct Workout: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    var exercises: [Exercise]
    let startDate: Date
    
    init(name: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.startDate = Date()
    }
    
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Personal Record
struct PersonalRecord: Identifiable {
    let id: UUID
    let exercise: String
    let weight: Double
    let reps: Int
    let date: Date
    
    init(exercise: String, weight: Double, reps: Int, date: Date = Date()) {
        self.id = UUID()
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.date = date
    }
}
