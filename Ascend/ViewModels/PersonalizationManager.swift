//
//  PersonalizationManager.swift
//  Ascend
//
//  Created on 2024
//

import Foundation
import Combine

struct WorkoutDayPattern {
    let mostCommonDays: [String] // Day names like "Monday", "Wednesday"
    let averageDaysBetween: Double
    let frequencyPerWeek: Double
    let formattedInsight: String
}

struct RecoverySuggestion {
    let daysSinceLastWorkout: Int
    let suggestedRestDaysRemaining: Int
    let status: RecoveryStatus
    let muscleGroupsNeedingRecovery: [String]
    let message: String
}

enum RecoveryStatus {
    case ready
    case needsRest
    case optimal
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .needsRest: return "red"
        case .optimal: return "yellow"
        }
    }
}

struct PersonalizedRecommendation {
    let workoutType: String // "Push", "Pull", "Legs", "Full Body"
    let reasoning: String
    let mostFrequentExercises: [(name: String, count: Int)]
    let underworkedMuscleGroups: [(name: String, daysSince: Int)]
}

class PersonalizationManager: ObservableObject {
    static let shared = PersonalizationManager()
    
    private let workoutHistoryManager = WorkoutHistoryManager.shared
    private let exerciseDataManager = ExerciseDataManager.shared
    
    // Cache for performance
    private var cachedDayPattern: WorkoutDayPattern?
    private var cachedDayPatternDate: Date?
    private var cachedRecovery: RecoverySuggestion?
    private var cachedRecoveryDate: Date?
    private var cachedRecommendations: PersonalizedRecommendation?
    private var cachedRecommendationsDate: Date?
    
    private let cacheValidity: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Workout Day Pattern Analysis
    
    func analyzeWorkoutDays() -> WorkoutDayPattern? {
        // Check cache
        if let cached = cachedDayPattern,
           let cacheDate = cachedDayPatternDate,
           Date().timeIntervalSince(cacheDate) < cacheValidity {
            return cached
        }
        
        let workouts = workoutHistoryManager.completedWorkouts
        guard workouts.count >= 5 else {
            return nil // Need at least 5 workouts for meaningful pattern
        }
        
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:] // 1 = Sunday, 2 = Monday, etc.
        
        // Count workouts by day of week
        for workout in workouts {
            let weekday = calendar.component(.weekday, from: workout.startDate)
            dayCounts[weekday, default: 0] += 1
        }
        
        // Get top 3 most common days
        let sortedDays = dayCounts.sorted { $0.value > $1.value }
        let topDays = Array(sortedDays.prefix(3))
        
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let mostCommonDayNames = topDays.map { dayNames[$0.key - 1] }
        
        // Calculate average days between workouts
        let sortedDates = workouts.map { $0.startDate }.sorted()
        var totalDaysBetween = 0.0
        var intervals = 0
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween > 0 {
                totalDaysBetween += Double(daysBetween)
                intervals += 1
            }
        }
        
        let averageDaysBetween = intervals > 0 ? totalDaysBetween / Double(intervals) : 0.0
        let frequencyPerWeek = averageDaysBetween > 0 ? 7.0 / averageDaysBetween : 0.0
        
        // Format insight
        let formattedInsight: String
        if mostCommonDayNames.count == 1 {
            formattedInsight = "You usually work out on \(mostCommonDayNames[0])"
        } else if mostCommonDayNames.count == 2 {
            formattedInsight = "You usually work out on \(mostCommonDayNames[0]) and \(mostCommonDayNames[1])"
        } else {
            let lastDay = mostCommonDayNames.last ?? ""
            let otherDays = mostCommonDayNames.dropLast().joined(separator: ", ")
            formattedInsight = "You usually work out on \(otherDays), and \(lastDay)"
        }
        
        let pattern = WorkoutDayPattern(
            mostCommonDays: mostCommonDayNames,
            averageDaysBetween: averageDaysBetween,
            frequencyPerWeek: frequencyPerWeek,
            formattedInsight: formattedInsight
        )
        
        cachedDayPattern = pattern
        cachedDayPatternDate = Date()
        
        return pattern
    }
    
    // MARK: - Recovery Time Analysis
    
    func calculateRecoveryTime() -> RecoverySuggestion? {
        // Check cache
        if let cached = cachedRecovery,
           let cacheDate = cachedRecoveryDate,
           Date().timeIntervalSince(cacheDate) < cacheValidity {
            return cached
        }
        
        let workouts = workoutHistoryManager.completedWorkouts
        guard let lastWorkout = workouts.sorted(by: { $0.startDate > $1.startDate }).first else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = Date()
        let daysSince = calendar.dateComponents([.day], from: lastWorkout.startDate, to: today).day ?? 0
        
        // Analyze muscle groups worked in last workout
        var muscleGroupsWorked: Set<String> = []
        var totalVolume = 0
        
        for exercise in lastWorkout.exercises {
            let (primary, secondary) = exerciseDataManager.getMuscleGroups(for: exercise.name)
            muscleGroupsWorked.formUnion(primary)
            muscleGroupsWorked.formUnion(secondary)
            
            // Calculate volume
            for set in exercise.sets where !set.isWarmup {
                totalVolume += Int(set.weight * Double(set.reps))
            }
        }
        
        // Determine recovery needs based on muscle groups and volume
        let suggestedRestDays: Int
        let status: RecoveryStatus
        var muscleGroupsNeedingRecovery: [String] = []
        
        // Recovery rules:
        // - Same muscle group: 48-72 hours (2-3 days)
        // - Different muscle groups: 24-48 hours (1-2 days)
        // - Full body or high volume: 48-72 hours (2-3 days)
        
        if muscleGroupsWorked.count >= 4 || totalVolume > 10000 {
            // Full body or high volume workout
            if daysSince < 2 {
                suggestedRestDays = 2 - daysSince
                status = .needsRest
                muscleGroupsNeedingRecovery = Array(muscleGroupsWorked)
            } else if daysSince < 3 {
                suggestedRestDays = 0
                status = .optimal
            } else {
                suggestedRestDays = 0
                status = .ready
            }
        } else {
            // Targeted muscle group workout
            if daysSince < 1 {
                suggestedRestDays = 1 - daysSince
                status = .needsRest
                muscleGroupsNeedingRecovery = Array(muscleGroupsWorked)
            } else if daysSince < 2 {
                suggestedRestDays = 0
                status = .optimal
            } else {
                suggestedRestDays = 0
                status = .ready
            }
        }
        
        // Check if same muscle groups were worked recently
        let recentWorkouts = workouts.filter {
            calendar.dateComponents([.day], from: $0.startDate, to: today).day ?? 0 < 7
        }
        
        for workout in recentWorkouts where workout.id != lastWorkout.id {
            for exercise in workout.exercises {
                let (primary, secondary) = exerciseDataManager.getMuscleGroups(for: exercise.name)
                let workoutMuscleGroups = Set(primary + secondary)
                let overlap = muscleGroupsWorked.intersection(workoutMuscleGroups)
                
                if !overlap.isEmpty {
                    let workoutDaysAgo = calendar.dateComponents([.day], from: workout.startDate, to: today).day ?? 0
                    if workoutDaysAgo < 3 {
                        muscleGroupsNeedingRecovery.append(contentsOf: overlap)
                    }
                }
            }
        }
        
        // Remove duplicates
        muscleGroupsNeedingRecovery = Array(Set(muscleGroupsNeedingRecovery))
        
        let message: String
        if status == .ready {
            message = "Ready to train"
        } else if status == .needsRest {
            if suggestedRestDays > 0 {
                message = "Suggested recovery: \(suggestedRestDays) more day\(suggestedRestDays > 1 ? "s" : "")"
            } else {
                message = "Take a rest day"
            }
        } else {
            message = "Optimal time to train"
        }
        
        let suggestion = RecoverySuggestion(
            daysSinceLastWorkout: daysSince,
            suggestedRestDaysRemaining: suggestedRestDays,
            status: status,
            muscleGroupsNeedingRecovery: muscleGroupsNeedingRecovery,
            message: message
        )
        
        cachedRecovery = suggestion
        cachedRecoveryDate = Date()
        
        return suggestion
    }
    
    // MARK: - Personalized Recommendations
    
    func getPersonalizedRecommendations() -> PersonalizedRecommendation? {
        // Check cache
        if let cached = cachedRecommendations,
           let cacheDate = cachedRecommendationsDate,
           Date().timeIntervalSince(cacheDate) < cacheValidity {
            return cached
        }
        
        let workouts = workoutHistoryManager.completedWorkouts
        guard workouts.count >= 10 else {
            return nil // Need at least 10 workouts for meaningful recommendations
        }
        
        // Analyze last 20 workouts
        let recentWorkouts = Array(workouts.sorted(by: { $0.startDate > $1.startDate }).prefix(20))
        
        // Count exercise frequency
        var exerciseCounts: [String: Int] = [:]
        var muscleGroupCounts: [String: Int] = [:]
        var muscleGroupLastWorked: [String: Date] = [:]
        
        let calendar = Calendar.current
        let today = Date()
        
        for workout in recentWorkouts {
            for exercise in workout.exercises {
                // Count exercise frequency
                exerciseCounts[exercise.name, default: 0] += 1
                
                // Count muscle group frequency
                let (primary, secondary) = exerciseDataManager.getMuscleGroups(for: exercise.name)
                for muscleGroup in primary + secondary {
                    muscleGroupCounts[muscleGroup, default: 0] += 1
                    // Track last time worked
                    if let lastDate = muscleGroupLastWorked[muscleGroup] {
                        if workout.startDate > lastDate {
                            muscleGroupLastWorked[muscleGroup] = workout.startDate
                        }
                    } else {
                        muscleGroupLastWorked[muscleGroup] = workout.startDate
                    }
                }
            }
        }
        
        // Get top 3 most frequent exercises
        let topExercises = exerciseCounts.sorted { $0.value > $1.value }.prefix(3).map { (name: $0.key, count: $0.value) }
        
        // Find underworked muscle groups (not worked in last 7 days)
        let underworkedMuscleGroups = muscleGroupLastWorked.compactMap { (muscleGroup, lastDate) -> (String, Int)? in
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysSince > 7 {
                return (muscleGroup, daysSince)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
        
        // Determine recommended workout type
        let recommendedType: String
        let reasoning: String
        
        // Analyze muscle group patterns to suggest workout type
        let chestCount = muscleGroupCounts.filter { $0.key.lowercased().contains("chest") || $0.key.lowercased().contains("pectoral") }.values.reduce(0, +)
        let backCount = muscleGroupCounts.filter { $0.key.lowercased().contains("back") || $0.key.lowercased().contains("lat") }.values.reduce(0, +)
        let legCount = muscleGroupCounts.filter { $0.key.lowercased().contains("leg") || $0.key.lowercased().contains("quad") || $0.key.lowercased().contains("hamstring") }.values.reduce(0, +)
        
        if let mostUnderworked = underworkedMuscleGroups.first {
            let muscleGroup = mostUnderworked.0
            if muscleGroup.lowercased().contains("chest") || muscleGroup.lowercased().contains("pectoral") {
                recommendedType = "Push"
                reasoning = "You haven't worked \(muscleGroup) in \(mostUnderworked.1) days"
            } else if muscleGroup.lowercased().contains("back") || muscleGroup.lowercased().contains("lat") {
                recommendedType = "Pull"
                reasoning = "You haven't worked \(muscleGroup) in \(mostUnderworked.1) days"
            } else if muscleGroup.lowercased().contains("leg") || muscleGroup.lowercased().contains("quad") || muscleGroup.lowercased().contains("hamstring") {
                recommendedType = "Legs"
                reasoning = "You haven't worked \(muscleGroup) in \(mostUnderworked.1) days"
            } else {
                recommendedType = "Full Body"
                reasoning = "Based on your workout history"
            }
        } else if chestCount < backCount && chestCount < legCount {
            recommendedType = "Push"
            reasoning = "Based on your history, try a Push workout"
        } else if backCount < chestCount && backCount < legCount {
            recommendedType = "Pull"
            reasoning = "Based on your history, try a Pull workout"
        } else if legCount < chestCount && legCount < backCount {
            recommendedType = "Legs"
            reasoning = "Based on your history, try a Legs workout"
        } else {
            recommendedType = "Full Body"
            reasoning = "Based on your workout history"
        }
        
        let recommendation = PersonalizedRecommendation(
            workoutType: recommendedType,
            reasoning: reasoning,
            mostFrequentExercises: topExercises,
            underworkedMuscleGroups: Array(underworkedMuscleGroups.prefix(3))
        )
        
        cachedRecommendations = recommendation
        cachedRecommendationsDate = Date()
        
        return recommendation
    }
    
    // MARK: - Helper Methods
    
    func getMostFrequentExercises(limit: Int = 5) -> [(name: String, count: Int)] {
        let workouts = workoutHistoryManager.completedWorkouts
        var exerciseCounts: [String: Int] = [:]
        
        for workout in workouts {
            for exercise in workout.exercises {
                exerciseCounts[exercise.name, default: 0] += 1
            }
        }
        
        return exerciseCounts.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
    }
    
    func getUnderworkedMuscleGroups() -> [(name: String, daysSince: Int)] {
        let workouts = workoutHistoryManager.completedWorkouts
        guard !workouts.isEmpty else { return [] }
        
        var muscleGroupLastWorked: [String: Date] = [:]
        let calendar = Calendar.current
        let today = Date()
        
        for workout in workouts {
            for exercise in workout.exercises {
                let (primary, secondary) = exerciseDataManager.getMuscleGroups(for: exercise.name)
                for muscleGroup in primary + secondary {
                    if let lastDate = muscleGroupLastWorked[muscleGroup] {
                        if workout.startDate > lastDate {
                            muscleGroupLastWorked[muscleGroup] = workout.startDate
                        }
                    } else {
                        muscleGroupLastWorked[muscleGroup] = workout.startDate
                    }
                }
            }
        }
        
        return muscleGroupLastWorked.compactMap { (muscleGroup, lastDate) -> (String, Int)? in
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysSince > 7 {
                return (muscleGroup, daysSince)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Cache Management
    
    func invalidateCache() {
        cachedDayPattern = nil
        cachedDayPatternDate = nil
        cachedRecovery = nil
        cachedRecoveryDate = nil
        cachedRecommendations = nil
        cachedRecommendationsDate = nil
    }
}

