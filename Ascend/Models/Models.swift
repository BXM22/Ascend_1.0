import Foundation
import SwiftUI

// MARK: - Exercise Set
struct ExerciseSet: Identifiable, Equatable {
    let id = UUID()
    let setNumber: Int
    let weight: Double
    let reps: Int
    let holdDuration: Int?
    
    init(setNumber: Int, weight: Double, reps: Int, holdDuration: Int? = nil) {
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
struct Exercise: Identifiable, Equatable {
    let id = UUID()
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

// MARK: - Workout Template
struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let exercises: [String]
    let estimatedDuration: Int
    
    init(id: UUID = UUID(), name: String, exercises: [String], estimatedDuration: Int) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
    }
}

// MARK: - Workout
struct Workout: Identifiable, Equatable {
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
