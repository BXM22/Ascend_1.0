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
    var includeWarmup: Bool
    var includeStretch: Bool
    /// Maximum number of warmup/stretch exercises to include per workout (0 = none)
    var maxWarmupStretchExercises: Int
    /// Maximum number of cardio exercises to include per workout (0 = none)
    var maxCardioExercises: Int
    var preferredEquipment: [String] // e.g., ["Bodyweight", "Dumbbells", "Barbell"]
    var minExercises: Int
    var maxExercises: Int
    var trainingType: TrainingType
    var trainingGoal: TrainingGoal
    var restTimeMin: Int // Rest time minimum in seconds
    var restTimeMax: Int // Rest time maximum in seconds
    var rirMin: Int // Reps in Reserve minimum
    var rirMax: Int // Reps in Reserve maximum
    
    // Computed properties for ranges (not Codable, but useful for logic)
    var restTimeRange: ClosedRange<Int> {
        return restTimeMin...restTimeMax
    }
    
    var rirRange: ClosedRange<Int> {
        return rirMin...rirMax
    }
    
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
        self.includeWarmup = true
        self.includeStretch = true
        self.maxWarmupStretchExercises = 2
        self.maxCardioExercises = 1
        self.preferredEquipment = ["Bodyweight", "Dumbbells", "Barbell"]
        self.minExercises = 4
        self.maxExercises = 8
        self.trainingType = .strength
        self.trainingGoal = .bulk
        self.restTimeMin = 90 // Default to bulking rest times
        self.restTimeMax = 180
        self.rirMin = 0 // Default to bulking RIR
        self.rirMax = 2
    }
    
    func getExerciseCount(for muscleGroup: String) -> Int {
        return exercisesPerMuscleGroup[muscleGroup] ?? 1
    }
    
    // Convert TrainingGoal to TrainingPhase
    private func getTrainingPhase() -> TrainingPhase {
        switch (trainingType, trainingGoal) {
        case (.endurance, _):
            return .endurance
        case (_, .bulk):
            return .bulking
        case (_, .cut):
            return .cutting
        }
    }
    
    // Apply phase preset based on training goal and split type
    mutating func applyPhasePreset(splitType: WorkoutSplitType? = nil) {
        let phase = getTrainingPhase()
        
        // Set rest time and RIR ranges
        self.restTimeMin = phase.restTimeRange.lowerBound
        self.restTimeMax = phase.restTimeRange.upperBound
        self.rirMin = phase.rirRange.lowerBound
        self.rirMax = phase.rirRange.upperBound
        
        // If split type is provided, apply specific exercise counts
        if let splitType = splitType {
            applyExerciseCountsForSplit(phase: phase, splitType: splitType)
        } else {
            // Apply general presets based on phase
            applyGeneralPhasePreset(phase: phase)
        }
    }
    
    // Apply workout type preset (ensures consistency for same goal)
    mutating func applyWorkoutTypePreset(workoutType: String, splitType: WorkoutSplitType) {
        // Apply phase preset first to ensure rest times and RIR are set correctly
        applyPhasePreset(splitType: splitType)
        
        // The exercise counts and min/max will be handled by WorkoutGenerator.applyWorkoutTypeSettings()
        // This method ensures the base settings (rest times, RIR) are consistent for the same phase
    }
    
    // Apply exercise counts for specific split type
    private mutating func applyExerciseCountsForSplit(phase: TrainingPhase, splitType: WorkoutSplitType) {
        // Reset all muscle groups to 0 first
        for key in exercisesPerMuscleGroup.keys {
            exercisesPerMuscleGroup[key] = 0
        }
        
        switch splitType {
        case .pushPullLegs:
            // This will be handled by individual workout generation methods
            // (generatePushWorkout, generatePullWorkout, generateLegWorkout)
            break
            
        case .upperLower:
            // This will be handled by generateUpperWorkout and generateLowerWorkout
            break
            
        case .fullBody:
            let counts = TrainingPhase.getExerciseCounts(for: phase, splitType: "full body", dayType: "")
            for (muscle, count) in counts {
                exercisesPerMuscleGroup[muscle] = count
            }
            // Set min/max for full body
            switch phase {
            case .bulking:
                minExercises = 5
                maxExercises = 7
            case .cutting:
                minExercises = 4
                maxExercises = 6
            case .endurance:
                minExercises = 4
                maxExercises = 6
            }
            
        default:
            applyGeneralPhasePreset(phase: phase)
        }
    }
    
    // Apply general phase preset (for custom or unknown splits)
    private mutating func applyGeneralPhasePreset(phase: TrainingPhase) {
        switch phase {
        case .bulking:
            // Higher volume for bulking
            minExercises = 5
            maxExercises = 8
            // Increase exercise counts slightly
            for key in exercisesPerMuscleGroup.keys {
                let current = exercisesPerMuscleGroup[key] ?? 0
                exercisesPerMuscleGroup[key] = max(1, current + 1)
            }
            
        case .cutting:
            // Lower volume for cutting
            minExercises = 3
            maxExercises = 6
            // Reduce exercise counts, prioritize compounds
            for key in exercisesPerMuscleGroup.keys {
                let current = exercisesPerMuscleGroup[key] ?? 0
                exercisesPerMuscleGroup[key] = max(0, current - 1)
            }
            
        case .endurance:
            // Moderate volume for endurance
            minExercises = 4
            maxExercises = 6
        }
    }
}

