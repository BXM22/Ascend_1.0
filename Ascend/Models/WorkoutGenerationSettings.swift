import Foundation

// MARK: - Training Type
enum TrainingType: String, Codable, CaseIterable {
    case strength = "Strength"
    case endurance = "Endurance"
    
    var description: String {
        switch self {
        case .strength:
            return "Lower reps, higher weight for maximum strength"
        case .endurance:
            return "Higher reps, lower weight for muscular endurance"
        }
    }
}

// MARK: - Training Goal
enum TrainingGoal: String, Codable, CaseIterable {
    case bulk = "Bulk"
    case cut = "Cut"
    
    var description: String {
        switch self {
        case .bulk:
            return "Build muscle mass with higher volume"
        case .cut:
            return "Maintain muscle while cutting fat"
        }
    }
}

// MARK: - Workout Generation Settings
struct WorkoutGenerationSettings: Codable {
    var exercisesPerMuscleGroup: [String: Int] // Muscle group name -> number of exercises
    var includeCardio: Bool
    var includeCalisthenics: Bool
    var preferredEquipment: [String] // e.g., ["Bodyweight", "Dumbbells", "Barbell"]
    var minExercises: Int
    var maxExercises: Int
    var trainingType: TrainingType
    var trainingGoal: TrainingGoal
    
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
        self.trainingType = .strength
        self.trainingGoal = .bulk
    }
    
    func getExerciseCount(for muscleGroup: String) -> Int {
        return exercisesPerMuscleGroup[muscleGroup] ?? 1
    }
}

