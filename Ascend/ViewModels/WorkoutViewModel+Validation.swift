import Foundation

// MARK: - Validation Extensions for Testing
extension WorkoutViewModel {
    /// Validates that a workout can be started
    func validateWorkoutStart() -> Bool {
        return currentWorkout == nil || currentWorkout?.exercises.isEmpty == true
    }
    
    /// Validates that a set can be completed
    func validateSetCompletion(weight: Double, reps: Int) -> AppResult<Void> {
        guard let exercise = currentExercise else {
            return .failure(.invalidState("No current exercise"))
        }
        
        // Check if exercise type matches
        guard exercise.exerciseType != .hold else {
            return .failure(.validationFailed("Use completeHoldSet for hold exercises"))
        }
        
        // Basic validation with bounds checking
        guard weight >= AppConstants.Validation.minWeight,
              weight <= AppConstants.Validation.maxWeight else {
            return .failure(.validationFailed("Weight must be between \(Int(AppConstants.Validation.minWeight)) and \(Int(AppConstants.Validation.maxWeight)) lbs"))
        }
        
        guard reps >= AppConstants.Validation.minReps,
              reps <= AppConstants.Validation.maxReps else {
            return .failure(.validationFailed("Reps must be between \(AppConstants.Validation.minReps) and \(AppConstants.Validation.maxReps)"))
        }
        
        return .success(())
    }
    
    /// Validates that a hold set can be completed
    func validateHoldSetCompletion(duration: Int) -> AppResult<Void> {
        guard let exercise = currentExercise else {
            return .failure(.invalidState("No current exercise"))
        }
        
        // Check if exercise type matches
        guard exercise.exerciseType == .hold else {
            return .failure(.validationFailed("Use completeSet for weight/reps exercises"))
        }
        
        // Basic validation with bounds checking
        guard duration >= AppConstants.Validation.minHoldDuration,
              duration <= AppConstants.Validation.maxHoldDuration else {
            return .failure(.validationFailed("Duration must be between \(AppConstants.Validation.minHoldDuration) and \(AppConstants.Validation.maxHoldDuration) seconds"))
        }
        
        return .success(())
    }
    
    /// Validates that an alternative can be switched
    func validateAlternativeSwitch(alternativeName: String) -> AppResult<Void> {
        guard let workout = currentWorkout else {
            return .failure(.invalidState("No active workout"))
        }
        
        guard currentExerciseIndex < workout.exercises.count else {
            return .failure(.invalidState("Invalid exercise index"))
        }
        
        guard !alternativeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed("Alternative exercise name cannot be empty"))
        }
        
        return .success(())
    }
    
    /// Validates that an exercise can be added
    func validateAddExercise(name: String, targetSets: Int, type: ExerciseType, holdDuration: Int?) -> AppResult<Void> {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed("Exercise name cannot be empty"))
        }
        
        guard targetSets >= AppConstants.Validation.minSets,
              targetSets <= AppConstants.Validation.maxSets else {
            return .failure(.validationFailed("Target sets must be between \(AppConstants.Validation.minSets) and \(AppConstants.Validation.maxSets)"))
        }
        
        if type == .hold, let duration = holdDuration {
            guard duration >= AppConstants.Validation.minHoldDuration,
                  duration <= AppConstants.Validation.maxHoldDuration else {
                return .failure(.validationFailed("Hold duration must be between \(AppConstants.Validation.minHoldDuration) and \(AppConstants.Validation.maxHoldDuration) seconds"))
            }
        }
        
        return .success(())
    }
}

extension ProgressViewModel {
    /// Validates that a PR can be added
    func validatePRAddition(exercise: String, weight: Double, reps: Int) -> AppResult<Void> {
        guard !exercise.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.validationFailed("Exercise name cannot be empty"))
        }
        
        guard weight >= AppConstants.Validation.minWeight,
              weight <= AppConstants.Validation.maxWeight else {
            return .failure(.validationFailed("Weight must be between \(Int(AppConstants.Validation.minWeight)) and \(Int(AppConstants.Validation.maxWeight)) lbs"))
        }
        
        guard reps >= AppConstants.Validation.minReps,
              reps <= AppConstants.Validation.maxReps else {
            return .failure(.validationFailed("Reps must be between \(AppConstants.Validation.minReps) and \(AppConstants.Validation.maxReps)"))
        }
        
        return .success(())
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

