import Foundation

/// Centralized constants for the application
enum AppConstants {
    
    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKeys {
        static let restTimerDuration = "restTimerDuration"
        static let customColorTheme = "customColorTheme"
        static let themeMode = "themeMode"
        static let savedWorkoutPrograms = "savedWorkoutPrograms"
        static let activeWorkoutProgram = "activeWorkoutProgram"
        static let savedWorkoutTemplates = "savedWorkoutTemplates"
        static let customExercises = "customExercises"
        static let completedWorkouts = "completedWorkouts"
        // Rest timer persistence
        static let restTimerActive = "restTimerActive"
        static let restTimerRemaining = "restTimerRemaining"
        static let restTimerTotalDuration = "restTimerTotalDuration"
        static let restTimerStartTime = "restTimerStartTime"
        // Progress tracking persistence
        static let personalRecords = "personalRecords"
        static let workoutDates = "workoutDates"
        static let restDays = "restDays"
        // Warm-up settings
        static let warmupPercentages = "warmupPercentages"
        // Set templates
        static let setTemplates = "setTemplates"
        // Timer pause during rest
        static let pauseTimerDuringRest = "pauseTimerDuringRest"
        // Exercise usage tracking
        static let recentExercises = "recentExercises"
        static let exerciseUsageCounts = "exerciseUsageCounts"
    }
    
    // MARK: - Timer Constants
    
    enum Timer {
        static let defaultRestDuration: Int = 90 // seconds
        static let minRestDuration: Int = 30 // seconds
        static let maxRestDuration: Int = 600 // 10 minutes
        static let restDurationStep: Int = 15 // seconds
        static let workoutTimerInterval: TimeInterval = 1.0 // seconds
        static let restTimerInterval: TimeInterval = 1.0 // seconds
    }
    
    // MARK: - Rest Timer Options
    
    static let restTimerOptions: [Int] = [30, 45, 60, 90, 120, 180, 240, 300]
    
    // MARK: - Dropset Constants
    
    enum Dropset {
        static let minDropsets: Int = 1
        static let maxDropsets: Int = 5
        static let defaultDropsets: Int = 1
        static let minWeightReduction: Double = 5.0 // lbs
        static let maxWeightReduction: Double = 50.0 // lbs
        static let defaultWeightReduction: Double = 5.0 // lbs
        static let weightReductionStep: Double = 5.0 // lbs
    }
    
    // MARK: - Warm-up Constants
    
    enum Warmup {
        static let defaultPercentages: [Double] = [50.0, 70.0, 90.0] // percentages of working weight
        static let minPercentage: Double = 20.0
        static let maxPercentage: Double = 95.0
        static let percentageStep: Double = 5.0
    }
    
    // MARK: - Hold Exercise Constants
    
    enum HoldExercise {
        static let quickSelectDurations: [Int] = [15, 30, 45, 60] // seconds
        static let defaultDuration: Int = 30 // seconds
    }
    
    // MARK: - Cache Constants
    
    enum Cache {
        static let volumeCacheValidity: TimeInterval = 300 // 5 minutes
        static let volumeCacheValidityShort: TimeInterval = 60 // 1 minute
    }
    
    // MARK: - Progress Tracking
    
    enum Progress {
        static let defaultTotalVolume: Int = 15000
        static let defaultWorkoutCount: Int = 12
        static let weeksToDisplay: Int = 8
    }
    
    // MARK: - UI Constants
    
    enum UI {
        static let minimumButtonSize: CGFloat = 44.0 // points (HIG requirement)
        static let cardCornerRadius: CGFloat = 20.0
        static let buttonCornerRadius: CGFloat = 16.0
        static let smallCornerRadius: CGFloat = 12.0
        static let borderWidth: CGFloat = 1.0
        static let thickBorderWidth: CGFloat = 2.0
    }
    
    // MARK: - Animation Durations
    
    enum Animation {
        static let quick: TimeInterval = 0.2
        static let standard: TimeInterval = 0.3
        static let smooth: TimeInterval = 0.4
        static let celebration: TimeInterval = 0.6
    }
    
    // MARK: - PR Badge
    
    enum PRBadge {
        static let displayDuration: TimeInterval = 3.0 // seconds
    }
    
    // MARK: - CloudKit
    
    enum CloudKit {
        static let containerIdentifier = "iCloud.com.app.com.Ascend"
        static let workoutRecordType = "Workout"
        static let templateRecordType = "WorkoutTemplate"
        static let programRecordType = "WorkoutProgram"
        static let customExerciseRecordType = "CustomExercise"
    }
    
    // MARK: - Validation
    
    enum Validation {
        static let minWeight: Double = 0.0
        static let maxWeight: Double = 1000.0 // lbs
        static let minReps: Int = 1
        static let maxReps: Int = 100
        static let minSets: Int = 1
        static let maxSets: Int = 20
        static let minHoldDuration: Int = 1 // seconds
        static let maxHoldDuration: Int = 3600 // 1 hour
    }
    
    // MARK: - Notification Names
    
    enum Notification {
        static let colorThemeDidChange = Foundation.Notification.Name("colorThemeDidChange")
    }
}

