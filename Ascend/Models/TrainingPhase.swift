import Foundation

// MARK: - Training Phase
enum TrainingPhase: String, Codable, CaseIterable {
    case bulking = "Bulking"
    case cutting = "Cutting"
    case endurance = "Endurance"
    
    var description: String {
        switch self {
        case .bulking:
            return "Maximize muscle growth with high volume"
        case .cutting:
            return "Preserve muscle while cutting fat"
        case .endurance:
            return "Build fatigue resistance with high reps"
        }
    }
    
    // Rep ranges for each phase
    var repRange: ClosedRange<Int> {
        switch self {
        case .bulking:
            return 6...12
        case .cutting:
            return 5...10
        case .endurance:
            return 12...25 // 12-20+ reps
        }
    }
    
    // Sets per muscle group per week
    var weeklySetsPerMuscle: ClosedRange<Int> {
        switch self {
        case .bulking:
            return 12...20
        case .cutting:
            return 8...12
        case .endurance:
            return 8...15
        }
    }
    
    // Rest times in seconds
    var restTimeRange: ClosedRange<Int> {
        switch self {
        case .bulking:
            return 90...180 // 1.5-3 min
        case .cutting:
            return 120...180 // 2-3 min
        case .endurance:
            return 30...90 // 30-90s
        }
    }
    
    // RIR (Reps in Reserve) ranges
    var rirRange: ClosedRange<Int> {
        switch self {
        case .bulking:
            return 0...2
        case .cutting:
            return 0...1
        case .endurance:
            return 0...3
        }
    }
    
    // Get exercise counts for a specific split type and day
    // This will be used by WorkoutGenerationSettings.applyPhasePreset()
    static func getExerciseCounts(for phase: TrainingPhase, splitType: String, dayType: String) -> [String: Int] {
        let dayLower = dayType.lowercased()
        let splitLower = splitType.lowercased()
        
        switch (phase, splitLower, dayLower) {
        // PPL - Bulk
        case (.bulking, "push/pull/legs", "push"), (.bulking, "ppl", "push"):
            return ["Chest": Int.random(in: 2...3), "Shoulders": Int.random(in: 1...2), "Triceps": Int.random(in: 1...2)]
        case (.bulking, "push/pull/legs", "pull"), (.bulking, "ppl", "pull"):
            return ["Lats": Int.random(in: 3...4), "Shoulders": 1, "Biceps": Int.random(in: 1...2)]
        case (.bulking, "push/pull/legs", "legs"), (.bulking, "ppl", "legs"):
            return ["Quads": 2, "Hamstrings": 1, "Glutes": 1, "Calves": Int.random(in: 1...2)]
            
        // PPL - Cut
        case (.cutting, "push/pull/legs", "push"), (.cutting, "ppl", "push"):
            return ["Chest": Int.random(in: 1...2), "Shoulders": 1, "Triceps": 1]
        case (.cutting, "push/pull/legs", "pull"), (.cutting, "ppl", "pull"):
            return ["Lats": Int.random(in: 2...3), "Shoulders": 1, "Biceps": Int.random(in: 0...1)]
        case (.cutting, "push/pull/legs", "legs"), (.cutting, "ppl", "legs"):
            return ["Quads": Int.random(in: 1...2), "Hamstrings": Int.random(in: 1...2), "Glutes": Int.random(in: 1...2), "Calves": Int.random(in: 0...1)]
            
        // Upper/Lower - Bulk
        case (.bulking, "upper/lower", "upper"), (.bulking, "upperlower", "upper"):
            return ["Chest": Int.random(in: 1...2), "Lats": 2, "Shoulders": 1, "Biceps": Int.random(in: 1...2), "Triceps": Int.random(in: 0...1)]
        case (.bulking, "upper/lower", "lower"), (.bulking, "upperlower", "lower"):
            return ["Quads": 2, "Hamstrings": 1, "Glutes": 1, "Calves": Int.random(in: 1...2), "Abs": Int.random(in: 0...1)]
            
        // Upper/Lower - Cut
        case (.cutting, "upper/lower", "upper"), (.cutting, "upperlower", "upper"):
            return ["Chest": 1, "Lats": 2, "Shoulders": 1, "Biceps": Int.random(in: 0...1), "Triceps": Int.random(in: 0...1)]
        case (.cutting, "upper/lower", "lower"), (.cutting, "upperlower", "lower"):
            return ["Quads": Int.random(in: 1...2), "Hamstrings": Int.random(in: 1...2), "Glutes": Int.random(in: 1...2), "Calves": Int.random(in: 0...1), "Abs": Int.random(in: 0...1)]
            
        // Full-Body - Bulk
        case (.bulking, "full body", _), (.bulking, "fullbody", _):
            return ["Quads": 1, "Hamstrings": 0, "Glutes": 1, "Chest": 1, "Lats": Int.random(in: 1...2), "Shoulders": Int.random(in: 0...1), "Biceps": Int.random(in: 0...1), "Triceps": Int.random(in: 0...1)]
            
        // Full-Body - Cut
        case (.cutting, "full body", _), (.cutting, "fullbody", _):
            return ["Quads": 1, "Hamstrings": 0, "Glutes": 1, "Chest": 1, "Lats": 1, "Shoulders": Int.random(in: 0...1), "Biceps": Int.random(in: 0...1), "Triceps": Int.random(in: 0...1)]
            
        // Full-Body - Endurance
        case (.endurance, "full body", _), (.endurance, "fullbody", _):
            return ["Quads": 1, "Hamstrings": 1, "Glutes": 0, "Chest": 1, "Lats": Int.random(in: 1...2), "Abs": Int.random(in: 0...1), "Biceps": Int.random(in: 0...1), "Triceps": Int.random(in: 0...1)]
            
        default:
            return [:]
        }
    }
    
    // Get rep range for exercise based on type and muscle group
    func getRepRangeForExercise(isCompound: Bool, muscleGroup: String) -> ClosedRange<Int> {
        let muscleLower = muscleGroup.lowercased()
        
        // Special cases for certain muscle groups
        let isCalves = muscleLower.contains("calves") || muscleLower.contains("calf")
        let isAbs = muscleLower.contains("abs") || muscleLower.contains("core")
        
        switch self {
        case .bulking:
            // Bulk/Hypertrophy: Optimal 6-12 rep range
            if isCalves || isAbs {
                // Calves and abs respond well to higher reps even in bulk
                return isCompound ? 10...15 : 12...20
            }
            return isCompound ? 6...10 : 8...12
            
        case .cutting:
            // Cut: Higher intensity, lower volume
            if isCalves || isAbs {
                return isCompound ? 8...12 : 10...15
            }
            return isCompound ? 5...8 : 6...10
            
        case .endurance:
            // Endurance: Higher rep ranges
            if isCalves || isAbs {
                return isCompound ? 15...25 : 20...30
            }
            return isCompound ? 12...20 : 15...25
        }
    }
    
    // Get sets range for exercise based on type and muscle group
    func getSetsRangeForExercise(isCompound: Bool, muscleGroup: String) -> ClosedRange<Int> {
        switch self {
        case .bulking:
            // Bulk/Hypertrophy: Higher volume for growth
            return isCompound ? 3...5 : 2...4
            
        case .cutting:
            // Cut: Lower volume, maintain intensity
            return isCompound ? 2...4 : 1...3
            
        case .endurance:
            // Endurance: Moderate volume
            return isCompound ? 2...3 : 2...3
        }
    }
    
    // Get random rep count within the appropriate range
    func getRandomReps(isCompound: Bool, muscleGroup: String) -> Int {
        let range = getRepRangeForExercise(isCompound: isCompound, muscleGroup: muscleGroup)
        return Int.random(in: range)
    }
    
    // Get random set count within the appropriate range
    func getRandomSets(isCompound: Bool, muscleGroup: String) -> Int {
        let range = getSetsRangeForExercise(isCompound: isCompound, muscleGroup: muscleGroup)
        return Int.random(in: range)
    }
    
    // Get rep string for display (format: "8-10" or "12")
    func getRepString(isCompound: Bool, muscleGroup: String) -> String {
        let range = getRepRangeForExercise(isCompound: isCompound, muscleGroup: muscleGroup)
        if range.lowerBound == range.upperBound {
            return "\(range.lowerBound)"
        } else {
            return "\(range.lowerBound)-\(range.upperBound)"
        }
    }
    
    // Legacy methods for backward compatibility
    func getSetsPerExercise(isCompound: Bool = true) -> Int {
        return getRandomSets(isCompound: isCompound, muscleGroup: "General")
    }
    
    func getRepString() -> String {
        return getRepString(isCompound: true, muscleGroup: "General")
    }
}

