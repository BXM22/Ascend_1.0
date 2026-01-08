//
//  RecoveryManager.swift
//  Ascend
//
//  Comprehensive recovery tracking based on muscle groups, training types, and intensity
//

import Foundation
import Combine
import SwiftUI

// MARK: - Recovery Training Style
enum RecoveryTrainingStyle: String, Codable, CaseIterable {
    case weights = "Weights"
    case calisthenics = "Calisthenics"
    case sports = "Sports"
    case fatLoss = "Fat Loss"
    
    var icon: String {
        switch self {
        case .weights: return "dumbbell.fill"
        case .calisthenics: return "figure.gymnastics"
        case .sports: return "sportscourt.fill"
        case .fatLoss: return "flame.fill"
        }
    }
    
    var description: String {
        switch self {
        case .weights: return "Strength & Muscle Building"
        case .calisthenics: return "Bodyweight & Skills"
        case .sports: return "Athletic Performance"
        case .fatLoss: return "Fat Loss & Conditioning"
        }
    }
}

// MARK: - Training Frequency
enum TrainingFrequency: String, Codable, CaseIterable {
    case beginner3 = "3 Days (Beginner)"
    case intermediate4 = "4 Days (Intermediate)"
    case advanced5 = "5 Days (Advanced)"
    case elite6 = "6 Days (Elite)"
    
    var daysPerWeek: Int {
        switch self {
        case .beginner3: return 3
        case .intermediate4: return 4
        case .advanced5: return 5
        case .elite6: return 6
        }
    }
    
    var description: String {
        switch self {
        case .beginner3: return "Full Body, 48hrs between sessions"
        case .intermediate4: return "Upper/Lower Split, 72hrs per muscle"
        case .advanced5: return "Heavy + Volume days"
        case .elite6: return "Skill work daily + strength"
        }
    }
}

// MARK: - Muscle Recovery State
enum MuscleRecoveryState: String, Codable {
    case ready = "Ready"           // Green - can train
    case recovering = "Recovering" // Yellow - almost ready
    case fatigued = "Fatigued"     // Orange - needs more rest
    case exhausted = "Exhausted"   // Red - definitely rest
    
    var color: Color {
        switch self {
        case .ready: return Color(hex: "22c55e")      // Green
        case .recovering: return Color(hex: "eab308") // Yellow
        case .fatigued: return Color(hex: "f97316")   // Orange
        case .exhausted: return Color(hex: "ef4444")  // Red
        }
    }
    
    var icon: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .recovering: return "arrow.triangle.2.circlepath.circle.fill"
        case .fatigued: return "clock.fill"
        case .exhausted: return "xmark.circle.fill"
        }
    }
    
    var message: String {
        switch self {
        case .ready: return "Ready to train"
        case .recovering: return "Almost recovered"
        case .fatigued: return "Needs more rest"
        case .exhausted: return "Take a rest day"
        }
    }
}

// MARK: - Muscle Recovery Info
struct MuscleRecoveryInfo: Identifiable {
    let id = UUID()
    let muscleGroup: String
    let state: MuscleRecoveryState
    let hoursSinceWorked: Int
    let requiredRecoveryHours: Int
    let recoveryPercentage: Double // 0.0 to 1.0
    let lastWorkoutIntensity: WorkoutIntensity?
    let wasCompound: Bool
    
    var estimatedHoursRemaining: Int {
        max(0, requiredRecoveryHours - hoursSinceWorked)
    }
    
    var formattedTimeRemaining: String {
        let hours = estimatedHoursRemaining
        if hours == 0 {
            return "Ready"
        } else if hours < 24 {
            return "\(hours)h remaining"
        } else {
            let days = hours / 24
            let remainingHours = hours % 24
            if remainingHours == 0 {
                return "\(days)d remaining"
            } else {
                return "\(days)d \(remainingHours)h remaining"
            }
        }
    }
}

// MARK: - CNS Fatigue Level
enum CNSFatigueLevel: String, Codable {
    case fresh = "Fresh"
    case mild = "Mild"
    case moderate = "Moderate"
    case high = "High"
    
    var color: Color {
        switch self {
        case .fresh: return Color(hex: "22c55e")
        case .mild: return Color(hex: "eab308")
        case .moderate: return Color(hex: "f97316")
        case .high: return Color(hex: "ef4444")
        }
    }
    
    var message: String {
        switch self {
        case .fresh: return "CNS fully recovered"
        case .mild: return "Light training recommended"
        case .moderate: return "Avoid heavy compounds"
        case .high: return "Rest day needed"
        }
    }
}

// MARK: - Recovery Settings
struct RecoverySettings: Codable {
    var trainingStyle: RecoveryTrainingStyle
    var trainingFrequency: TrainingFrequency
    var customRecoveryHours: [String: Int] // Muscle group -> custom hours
    var sleepHoursPerNight: Double
    var deloadWeekInterval: Int // Weeks between deloads
    var lastDeloadDate: Date?
    
    static var `default`: RecoverySettings {
        RecoverySettings(
            trainingStyle: .weights,
            trainingFrequency: .intermediate4,
            customRecoveryHours: [:],
            sleepHoursPerNight: 7.5,
            deloadWeekInterval: 6,
            lastDeloadDate: nil
        )
    }
}

// MARK: - Recovery Summary
struct RecoverySummary {
    let overallStatus: MuscleRecoveryState
    let cnsLevel: CNSFatigueLevel
    let muscleRecoveries: [MuscleRecoveryInfo]
    let readyToTrain: [String]
    let needsRest: [String]
    let deloadRecommended: Bool
    let weeksUntilDeload: Int
    let message: String
    let trainingRecommendation: String
}

// MARK: - Recovery Manager
class RecoveryManager: ObservableObject {
    static let shared = RecoveryManager()
    
    @Published var settings: RecoverySettings {
        didSet {
            saveSettings()
            invalidateCache()
        }
    }
    
    @Published private(set) var cachedSummary: RecoverySummary?
    private var cacheDate: Date?
    private let cacheValidity: TimeInterval = 60 // 1 minute
    
    private let workoutHistoryManager = WorkoutHistoryManager.shared
    private let exerciseDataManager = ExerciseDataManager.shared
    
    private let settingsKey = "RecoverySettings"
    
    // MARK: - Default Recovery Hours by Muscle Group
    private let defaultRecoveryHours: [String: Int] = [
        // Large muscle groups - 72 hours
        "Chest": 72,
        "Back": 72,
        "Lats": 72,
        "Upper Back": 72,
        "Quads": 72,
        "Hamstrings": 72,
        "Glutes": 72,
        
        // Medium muscle groups - 48-72 hours
        "Shoulders": 48,
        "Traps": 48,
        "Lower Back": 72,
        
        // Small muscle groups - 48 hours
        "Biceps": 48,
        "Triceps": 48,
        "Forearms": 48,
        "Calves": 48,
        "Abs": 48,
        "Obliques": 48,
        "Core": 48,
        
        // Full body / compound - 72-96 hours
        "Full Body": 96
    ]
    
    // Compound exercises that cause more CNS fatigue
    private let compoundExercises: Set<String> = [
        "squat", "deadlift", "bench press", "overhead press", "barbell row",
        "clean", "snatch", "power clean", "front squat", "back squat",
        "romanian deadlift", "sumo deadlift", "pendlay row", "t-bar row"
    ]
    
    private init() {
        settings = RecoveryManager.loadSettings()
    }
    
    // MARK: - Settings Persistence
    
    private static func loadSettings() -> RecoverySettings {
        guard let data = UserDefaults.standard.data(forKey: "RecoverySettings"),
              let decoded = try? JSONDecoder().decode(RecoverySettings.self, from: data) else {
            return .default
        }
        return decoded
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    // MARK: - Recovery Calculation
    
    func getRecoverySummary() -> RecoverySummary {
        // Check cache
        if let cached = cachedSummary,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidity {
            return cached
        }
        
        let muscleRecoveries = calculateMuscleRecoveries()
        let cnsLevel = calculateCNSFatigue()
        
        // Categorize muscles
        let readyToTrain = muscleRecoveries.filter { $0.state == .ready }.map { $0.muscleGroup }
        let needsRest = muscleRecoveries.filter { $0.state == .exhausted || $0.state == .fatigued }.map { $0.muscleGroup }
        
        // Determine overall status
        let overallStatus = determineOverallStatus(from: muscleRecoveries, cnsLevel: cnsLevel)
        
        // Deload check
        let deloadInfo = checkDeloadRecommendation()
        
        // Generate message
        let message = generateStatusMessage(overallStatus: overallStatus, readyCount: readyToTrain.count, needsRestCount: needsRest.count)
        
        // Training recommendation
        let recommendation = generateTrainingRecommendation(readyMuscles: readyToTrain, cnsLevel: cnsLevel)
        
        let summary = RecoverySummary(
            overallStatus: overallStatus,
            cnsLevel: cnsLevel,
            muscleRecoveries: muscleRecoveries,
            readyToTrain: readyToTrain,
            needsRest: needsRest,
            deloadRecommended: deloadInfo.recommended,
            weeksUntilDeload: deloadInfo.weeksUntil,
            message: message,
            trainingRecommendation: recommendation
        )
        
        cachedSummary = summary
        cacheDate = Date()
        
        return summary
    }
    
    private func calculateMuscleRecoveries() -> [MuscleRecoveryInfo] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get recent workouts (last 7 days)
        let recentWorkouts = workoutHistoryManager.completedWorkouts.filter {
            calendar.dateComponents([.day], from: $0.startDate, to: now).day ?? 0 < 7
        }
        
        // Track last workout info per muscle group
        var muscleLastWorked: [String: (date: Date, intensity: WorkoutIntensity?, wasCompound: Bool)] = [:]
        
        for workout in recentWorkouts {
            for exercise in workout.exercises {
                let (primary, secondary) = exerciseDataManager.getMuscleGroups(for: exercise.name)
                let isCompound = compoundExercises.contains { exercise.name.lowercased().contains($0) }
                
                // Determine intensity from workout volume
                let intensity = determineExerciseIntensity(exercise: exercise)
                
                // Track primary muscles (full recovery needed)
                for muscle in primary {
                    let normalizedMuscle = normalizeMuscleGroup(muscle)
                    if let existing = muscleLastWorked[normalizedMuscle] {
                        if workout.startDate > existing.date {
                            muscleLastWorked[normalizedMuscle] = (workout.startDate, intensity, isCompound)
                        }
                    } else {
                        muscleLastWorked[normalizedMuscle] = (workout.startDate, intensity, isCompound)
                    }
                }
                
                // Track secondary muscles (partial recovery, reduce required time by 25%)
                for muscle in secondary {
                    let normalizedMuscle = normalizeMuscleGroup(muscle)
                    if muscleLastWorked[normalizedMuscle] == nil {
                        muscleLastWorked[normalizedMuscle] = (workout.startDate, intensity, false)
                    }
                }
            }
        }
        
        // Calculate recovery for all tracked muscles
        var recoveries: [MuscleRecoveryInfo] = []
        
        for (muscle, info) in muscleLastWorked {
            let hoursSince = Int(now.timeIntervalSince(info.date) / 3600)
            let requiredHours = getRequiredRecoveryHours(for: muscle, intensity: info.intensity, wasCompound: info.wasCompound)
            let percentage = min(1.0, Double(hoursSince) / Double(requiredHours))
            let state = determineRecoveryState(percentage: percentage)
            
            recoveries.append(MuscleRecoveryInfo(
                muscleGroup: muscle,
                state: state,
                hoursSinceWorked: hoursSince,
                requiredRecoveryHours: requiredHours,
                recoveryPercentage: percentage,
                lastWorkoutIntensity: info.intensity,
                wasCompound: info.wasCompound
            ))
        }
        
        // Sort by recovery state (most fatigued first)
        return recoveries.sorted { $0.recoveryPercentage < $1.recoveryPercentage }
    }
    
    private func getRequiredRecoveryHours(for muscle: String, intensity: WorkoutIntensity?, wasCompound: Bool) -> Int {
        // Check for custom setting first
        if let custom = settings.customRecoveryHours[muscle] {
            return custom
        }
        
        var baseHours = defaultRecoveryHours[muscle] ?? 48
        
        // Adjust for intensity
        if let intensity = intensity {
            switch intensity {
            case .light:
                baseHours = Int(Double(baseHours) * 0.75) // 25% less
            case .moderate:
                break // No adjustment
            case .intense:
                baseHours = Int(Double(baseHours) * 1.25) // 25% more
            case .extreme:
                baseHours = Int(Double(baseHours) * 1.5) // 50% more (72-96hr rule)
            }
        }
        
        // Add extra for compound movements (CNS)
        if wasCompound {
            baseHours += 12
        }
        
        // Adjust for training type
        switch settings.trainingStyle {
        case .calisthenics:
            // Skill work can be more frequent
            baseHours = Int(Double(baseHours) * 0.8)
        case .sports:
            // Athletes need more recovery
            baseHours = Int(Double(baseHours) * 1.1)
        case .fatLoss:
            // Still need rest for fat loss
            break
        case .weights:
            break
        }
        
        // Sleep penalty
        if settings.sleepHoursPerNight < 7 {
            baseHours += 12 // Less sleep = slower recovery
        }
        
        return max(24, baseHours) // Minimum 24 hours
    }
    
    private func determineRecoveryState(percentage: Double) -> MuscleRecoveryState {
        switch percentage {
        case 1.0...: return .ready
        case 0.75..<1.0: return .recovering
        case 0.5..<0.75: return .fatigued
        default: return .exhausted
        }
    }
    
    private func determineExerciseIntensity(exercise: Exercise) -> WorkoutIntensity {
        // Determine intensity based on weight and rep scheme
        let totalVolume = exercise.sets.reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
        let avgReps = exercise.sets.isEmpty ? 0 : exercise.sets.map { $0.reps }.reduce(0, +) / exercise.sets.count
        
        if avgReps <= 5 && totalVolume > 0 {
            return .extreme // Heavy strength work
        } else if avgReps <= 8 {
            return .intense
        } else if avgReps <= 12 {
            return .moderate
        } else {
            return .light
        }
    }
    
    private func calculateCNSFatigue() -> CNSFatigueLevel {
        let calendar = Calendar.current
        let now = Date()
        
        // Check recent workouts for heavy compounds
        let recentWorkouts = workoutHistoryManager.completedWorkouts.filter {
            calendar.dateComponents([.hour], from: $0.startDate, to: now).hour ?? 0 < 96 // Last 4 days
        }
        
        var heavyCompoundCount = 0
        var lastHeavyDate: Date?
        
        for workout in recentWorkouts {
            for exercise in workout.exercises {
                let isCompound = compoundExercises.contains { exercise.name.lowercased().contains($0) }
                let intensity = determineExerciseIntensity(exercise: exercise)
                
                if isCompound && (intensity == .intense || intensity == .extreme) {
                    heavyCompoundCount += 1
                    if lastHeavyDate == nil || workout.startDate > lastHeavyDate! {
                        lastHeavyDate = workout.startDate
                    }
                }
            }
        }
        
        // Determine CNS level
        if heavyCompoundCount == 0 {
            return .fresh
        }
        
        let hoursSinceHeavy = lastHeavyDate.map { Int(now.timeIntervalSince($0) / 3600) } ?? 96
        
        if hoursSinceHeavy < 24 && heavyCompoundCount >= 2 {
            return .high
        } else if hoursSinceHeavy < 48 && heavyCompoundCount >= 1 {
            return .moderate
        } else if hoursSinceHeavy < 72 {
            return .mild
        } else {
            return .fresh
        }
    }
    
    private func determineOverallStatus(from recoveries: [MuscleRecoveryInfo], cnsLevel: CNSFatigueLevel) -> MuscleRecoveryState {
        // CNS overrides muscle status
        if cnsLevel == .high {
            return .exhausted
        }
        
        let exhaustedCount = recoveries.filter { $0.state == .exhausted }.count
        let fatiguedCount = recoveries.filter { $0.state == .fatigued }.count
        let readyCount = recoveries.filter { $0.state == .ready }.count
        
        if exhaustedCount > 2 || (exhaustedCount > 0 && cnsLevel == .moderate) {
            return .exhausted
        } else if fatiguedCount > 2 || exhaustedCount > 0 {
            return .fatigued
        } else if readyCount >= recoveries.count / 2 {
            return .ready
        } else {
            return .recovering
        }
    }
    
    private func checkDeloadRecommendation() -> (recommended: Bool, weeksUntil: Int) {
        guard let lastDeload = settings.lastDeloadDate else {
            // No deload recorded, check training history
            let weeks = workoutHistoryManager.completedWorkouts.count / 4 // Rough estimate
            return (weeks >= settings.deloadWeekInterval, max(0, settings.deloadWeekInterval - weeks))
        }
        
        let weeksSince = Calendar.current.dateComponents([.weekOfYear], from: lastDeload, to: Date()).weekOfYear ?? 0
        let weeksUntil = max(0, settings.deloadWeekInterval - weeksSince)
        
        return (weeksUntil == 0, weeksUntil)
    }
    
    private func generateStatusMessage(overallStatus: MuscleRecoveryState, readyCount: Int, needsRestCount: Int) -> String {
        switch overallStatus {
        case .ready:
            return "You're fully recovered! Time to train."
        case .recovering:
            return "\(readyCount) muscle groups ready, \(needsRestCount) still recovering."
        case .fatigued:
            return "Several muscles need more rest. Consider light training."
        case .exhausted:
            return "Rest day recommended. Your body needs recovery."
        }
    }
    
    private func generateTrainingRecommendation(readyMuscles: [String], cnsLevel: CNSFatigueLevel) -> String {
        if cnsLevel == .high {
            return "Rest or light mobility work only"
        }
        
        if readyMuscles.isEmpty {
            return "Full rest day or active recovery"
        }
        
        // Group ready muscles into workout types
        let hasChest = readyMuscles.contains { $0.lowercased().contains("chest") }
        let hasBack = readyMuscles.contains { $0.lowercased().contains("back") || $0.lowercased().contains("lat") }
        let hasLegs = readyMuscles.contains { $0.lowercased().contains("quad") || $0.lowercased().contains("hamstring") || $0.lowercased().contains("glute") }
        let hasArms = readyMuscles.contains { $0.lowercased().contains("bicep") || $0.lowercased().contains("tricep") }
        let hasCore = readyMuscles.contains { $0.lowercased().contains("ab") || $0.lowercased().contains("core") }
        
        var recommendations: [String] = []
        
        if hasChest && hasArms {
            recommendations.append("Push day")
        } else if hasChest {
            recommendations.append("Chest workout")
        }
        
        if hasBack && hasArms {
            recommendations.append("Pull day")
        } else if hasBack {
            recommendations.append("Back workout")
        }
        
        if hasLegs {
            recommendations.append("Leg day")
        }
        
        if hasCore {
            recommendations.append("Core work")
        }
        
        if recommendations.isEmpty {
            return "Light accessory work: \(readyMuscles.prefix(3).joined(separator: ", "))"
        }
        
        return "Try: " + recommendations.prefix(2).joined(separator: " or ")
    }
    
    private func normalizeMuscleGroup(_ muscle: String) -> String {
        // Normalize muscle group names for consistency
        let lowercased = muscle.lowercased()
        
        if lowercased.contains("pec") || lowercased.contains("chest") {
            return "Chest"
        } else if lowercased.contains("lat") || lowercased.contains("upper back") {
            return "Back"
        } else if lowercased.contains("delt") || lowercased.contains("shoulder") {
            return "Shoulders"
        } else if lowercased.contains("bicep") {
            return "Biceps"
        } else if lowercased.contains("tricep") {
            return "Triceps"
        } else if lowercased.contains("quad") {
            return "Quads"
        } else if lowercased.contains("hamstring") {
            return "Hamstrings"
        } else if lowercased.contains("glute") {
            return "Glutes"
        } else if lowercased.contains("calf") || lowercased.contains("calves") {
            return "Calves"
        } else if lowercased.contains("ab") || lowercased.contains("core") {
            return "Core"
        } else if lowercased.contains("trap") {
            return "Traps"
        } else if lowercased.contains("forearm") {
            return "Forearms"
        } else if lowercased.contains("lower back") || lowercased.contains("erector") {
            return "Lower Back"
        }
        
        return muscle.capitalized
    }
    
    // MARK: - Cache Management
    
    func invalidateCache() {
        cachedSummary = nil
        cacheDate = nil
    }
    
    // MARK: - Custom Recovery Settings
    
    func setCustomRecoveryHours(for muscle: String, hours: Int) {
        settings.customRecoveryHours[muscle] = hours
    }
    
    func removeCustomRecoveryHours(for muscle: String) {
        settings.customRecoveryHours.removeValue(forKey: muscle)
    }
    
    func markDeloadComplete() {
        settings.lastDeloadDate = Date()
    }
    
    // MARK: - All Muscle Groups
    
    static let allMuscleGroups: [String] = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps",
        "Quads", "Hamstrings", "Glutes", "Calves",
        "Core", "Traps", "Forearms", "Lower Back"
    ]
}
