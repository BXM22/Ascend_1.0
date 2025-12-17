import Foundation

// MARK: - Exercise Classification Utilities
extension String {
    /// Check if exercise name indicates a warmup exercise
    func isWarmupExercise(category: String? = nil) -> Bool {
        if let category = category, category.lowercased() == "warmup" {
            return true
        }
        return self.lowercased().contains("warmup")
    }
    
    /// Check if exercise name indicates a stretch exercise
    func isStretchExercise(category: String? = nil) -> Bool {
        if let category = category, category.lowercased() == "stretching" {
            return true
        }
        return self.lowercased().contains("stretch")
    }
    
    /// Check if exercise name indicates a cardio exercise
    func isCardioExercise(category: String? = nil) -> Bool {
        if let category = category, category.lowercased() == "cardio" {
            return true
        }
        let nameLower = self.lowercased()
        let cardioKeywords = ["run", "bike", "row", "cardio", "treadmill", "elliptical", "cycling", "running", "jog", "sprint"]
        return cardioKeywords.contains { nameLower.contains($0) }
    }
    
    /// Check if exercise is a working set (not warmup, stretch, or cardio)
    func isWorkingSetExercise(category: String? = nil) -> Bool {
        return !self.isWarmupExercise(category: category) &&
               !self.isStretchExercise(category: category) &&
               !self.isCardioExercise(category: category)
    }
    
    /// Get exercise type priority for sorting (0 = warmup/stretch, 1 = working sets, 2 = cardio)
    func getExerciseTypePriority(category: String? = nil) -> Int {
        if self.isWarmupExercise(category: category) || self.isStretchExercise(category: category) {
            return 0
        } else if self.isCardioExercise(category: category) {
            return 2
        } else {
            return 1 // Working sets
        }
    }
    
    /// Check if exercise is compound
    func isCompoundExercise() -> Bool {
        let nameLower = self.lowercased()
        let keywords = [
            "squat", "deadlift", "bench", "press", "row", "pull", "dip",
            "lunge", "leg press", "hack squat", "romanian", "good morning",
            "overhead", "military", "shoulder press", "pull-up", "chin-up",
            "lat pulldown", "barbell", "t-bar", "cable row", "inverted row"
        ]
        return keywords.contains { nameLower.contains($0) }
    }
}

// MARK: - Day Type Extraction Utility
struct WorkoutDayTypeExtractor {
    /// Extract day type from workout name
    static func extract(from name: String) -> String? {
        let nameLower = name.lowercased()
        if nameLower.contains("push") {
            return "Push"
        } else if nameLower.contains("pull") {
            return "Pull"
        } else if nameLower.contains("leg") {
            return "Legs"
        } else if nameLower.contains("upper") {
            return "Upper"
        } else if nameLower.contains("lower") {
            return "Lower"
        } else if nameLower.contains("full") || nameLower.contains("body") {
            return "Full Body"
        } else if nameLower.contains("chest") && nameLower.contains("back") {
            return "Push" // Chest & Back is similar to Push
        } else if nameLower.contains("back") {
            return "Pull"
        } else if nameLower.contains("shoulders") {
            return "Push"
        }
        return nil
    }
}

