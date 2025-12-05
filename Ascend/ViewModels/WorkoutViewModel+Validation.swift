import Foundation

// MARK: - Validation Extensions for Testing
extension WorkoutViewModel {
    /// Validates that a workout can be started
    func validateWorkoutStart() -> Bool {
        return currentWorkout == nil || currentWorkout?.exercises.isEmpty == true
    }
    
    /// Validates that a set can be completed
    func validateSetCompletion(weight: Double, reps: Int) -> Bool {
        guard let exercise = currentExercise else { return false }
        
        // Basic validation
        guard weight > 0, reps > 0 else { return false }
        
        // Check if exercise type matches
        if exercise.exerciseType == .hold {
            return false // Use completeHoldSet for hold exercises
        }
        
        return true
    }
    
    /// Validates that an alternative can be switched
    func validateAlternativeSwitch(alternativeName: String) -> Bool {
        guard currentWorkout != nil,
              currentExerciseIndex < (currentWorkout?.exercises.count ?? 0) else {
            return false
        }
        
        return !alternativeName.isEmpty
    }
}

extension ProgressViewModel {
    /// Validates that a PR can be added
    func validatePRAddition(exercise: String, weight: Double, reps: Int) -> Bool {
        guard !exercise.isEmpty, weight > 0, reps > 0 else {
            return false
        }
        
        return true
    }
    
    /// Validates PR comparison logic
    func isNewPR(exercise: String, weight: Double, reps: Int) -> Bool {
        let existingPRs = prs.filter { $0.exercise == exercise }
        
        guard !existingPRs.isEmpty else {
            return true // First PR for this exercise
        }
        
        let currentPR = existingPRs.max { pr1, pr2 in
            if pr1.weight != pr2.weight {
                return pr1.weight < pr2.weight
            }
            return pr1.reps < pr2.reps
        }
        
        guard let current = currentPR else { return true }
        
        // New PR if weight is higher, or same weight with more reps
        return weight > current.weight || (weight == current.weight && reps > current.reps)
    }
}

extension ExerciseDataManager {
    /// Validates YouTube URL format
    func isValidYouTubeURL(_ urlString: String) -> Bool {
        guard URL(string: urlString) != nil else { return false }
        return urlString.contains("youtube.com") || urlString.contains("youtu.be")
    }
    
    /// Gets all exercises with alternatives (for testing/validation)
    func getAllExercisesWithAlternatives() -> [String] {
        // Use known exercise names and filter by public methods
        let knownExercises = [
            "Bench Press", "Squat", "Deadlift", "Shoulder Press", "Barbell Row",
            "Pull-ups", "Plank", "Bicep Curl", "Tricep Extension", "Leg Press"
        ]
        return knownExercises.filter { hasAlternatives(for: $0) }
    }
    
    /// Gets all exercises with videos (for testing/validation)
    func getAllExercisesWithVideos() -> [String] {
        // Use known exercise names and filter by public methods
        let knownExercises = [
            "Bench Press", "Squat", "Deadlift", "Shoulder Press", "Barbell Row",
            "Pull-ups", "Plank", "Bicep Curl", "Tricep Extension", "Leg Press"
        ]
        return knownExercises.filter { hasVideo(for: $0) }
    }
}

