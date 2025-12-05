import Foundation

// MARK: - Workout Generation Settings
struct WorkoutGenerationSettings: Codable {
    var exercisesPerMuscleGroup: [String: Int] // Muscle group name -> number of exercises
    var includeCardio: Bool
    var includeCalisthenics: Bool
    var preferredEquipment: [String] // e.g., ["Bodyweight", "Dumbbells", "Barbell"]
    var minExercises: Int
    var maxExercises: Int
    
    init() {
        // Default settings
        self.exercisesPerMuscleGroup = [
            "Chest": 2,
            "Lats": 2,
            "Shoulders": 2,
            "Biceps": 1,
            "Triceps": 1,
            "Quads": 2,
            "Hamstrings": 2,
            "Glutes": 1,
            "Calves": 1,
            "Abs": 2,
            "Obliques": 1
        ]
        self.includeCardio = false
        self.includeCalisthenics = false
        self.preferredEquipment = ["Bodyweight", "Dumbbells", "Barbell"]
        self.minExercises = 4
        self.maxExercises = 8
    }
    
    func getExerciseCount(for muscleGroup: String) -> Int {
        return exercisesPerMuscleGroup[muscleGroup] ?? 1
    }
}

