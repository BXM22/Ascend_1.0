import Foundation
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var currentExerciseIndex: Int = 0
    @Published var elapsedTime: Int = 0
    @Published var restTimerActive: Bool = false
    @Published var restTimeRemaining: Int = AppConstants.Timer.defaultRestDuration
    @Published var restTimerTotalDuration: Int = AppConstants.Timer.defaultRestDuration
    @Published var showPRBadge: Bool = false
    @Published var prMessage: String = ""
    @Published var showAddExerciseSheet: Bool = false
    @Published var showSettingsSheet: Bool = false
    @Published var showCompletionModal: Bool = false
    @Published var completionStats: WorkoutCompletionStats?
    @Published var showExerciseHistory: Bool = false
    @Published var isFromTemplate: Bool = false // Track if workout came from template
    @Published var readyForNextSet: UUID = UUID() // Triggers UI update to prepare for next set
    @Published var expandedSections: Set<ExerciseSectionType> = [] // Track which sections are expanded
    @Published var autoAdvanceEnabled: Bool = false // Auto-advance to next set/exercise
    @Published var autoAdvanceRestDuration: Int = 0 // Minimum rest before auto-advance (0 = immediate)
    
    // Undo state
    @Published var showUndoButton: Bool = false
    @Published var lastCompletedSet: (exerciseIndex: Int, setCount: Int, wasPR: Bool)?
    
    // Dropset configuration state
    @Published var dropsetsEnabled: Bool = false
    @Published var numberOfDropsets: Int = AppConstants.Dropset.defaultDropsets
    @Published var weightReductionPerDropset: Double = AppConstants.Dropset.defaultWeightReduction
    
    // Dependencies (injected via initializer)
    let settingsManager: SettingsManager
    weak var progressViewModel: ProgressViewModel?
    weak var programViewModel: WorkoutProgramViewModel?
    weak var templatesViewModel: TemplatesViewModel?
    weak var themeManager: ThemeManager?
    
    private var timer: Timer?
    private var restTimer: Timer?
    private var workoutStartTime: Date?
    private var restTimerStartTime: Date?
    private var restTimerOriginalDuration: Int = 0
    private var backgroundTime: Date?
    private var notificationObservers: [NSObjectProtocol] = []
    
    // Timer pause during rest tracking
    private var pausedTimeAccumulator: Int = 0 // Total paused time in seconds
    private var pauseStartTime: Date? // When the timer was paused
    private var isTimerPaused: Bool = false
    
    // Weight persistence per exercise
    private var lastWeightPerExercise: [String: Double] = [:]
    
    /// Public property to check if timer is paused during rest
    var isTimerPausedDuringRest: Bool {
        return isTimerPaused && settingsManager.pauseTimerDuringRest
    }
    
    var currentExercise: Exercise? {
        guard let workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else {
            return nil
        }
        return workout.exercises[currentExerciseIndex]
    }
    
    /// Get sorted exercises: warmup/stretch → working sets → cardio
    var sortedExercises: [Exercise] {
        guard let workout = currentWorkout else { return [] }
        
        return workout.exercises.sorted { ex1, ex2 in
            // Get category from ExRxExercise data if available
            let exRx1 = ExRxDirectoryManager.shared.findExercise(name: ex1.name)
            let exRx2 = ExRxDirectoryManager.shared.findExercise(name: ex2.name)
            
            let priority1 = ex1.name.getExerciseTypePriority(category: exRx1?.category)
            let priority2 = ex2.name.getExerciseTypePriority(category: exRx2?.category)
            
            // First sort by type priority
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // Within same type, maintain original order (or compound-first for working sets)
            if priority1 == 1 { // Working sets
                return ex1.name.isCompoundExercise() && !ex2.name.isCompoundExercise()
            }
            
            // For warmup/stretch/cardio, maintain original order
            return false
        }
    }
    
    /// Group exercises by section type
    var exercisesBySection: [ExerciseSectionType: [Exercise]] {
        guard currentWorkout != nil else { return [:] }
        let sorted = sortedExercises
        return Dictionary(grouping: sorted) { exercise in
            getSectionType(for: exercise)
        }
    }
    
    /// Get section type for an exercise (for displaying section indicators)
    func getSectionType(for exercise: Exercise) -> ExerciseSectionType {
        // First check category from ExRxExercise data
        if let exRxExercise = ExRxDirectoryManager.shared.findExercise(name: exercise.name) {
            let category = exRxExercise.category.lowercased()
            if category == "warmup" || exercise.name.isWarmupExercise(category: exRxExercise.category) {
                return .warmup
            } else if category == "stretching" || exercise.name.isStretchExercise(category: exRxExercise.category) {
                return .stretch
            } else if category == "cardio" || exercise.name.isCardioExercise(category: exRxExercise.category) {
                return .cardio
            }
        }
        
        // Fallback to name-based detection
        if exercise.name.isWarmupExercise() {
            return .warmup
        } else if exercise.name.isStretchExercise() {
            return .stretch
        } else if exercise.name.isCardioExercise() || (exercise.exerciseType == .hold && exercise.targetHoldDuration != nil && !isCalisthenicsExercise(exercise)) {
            return .cardio
        } else {
            return .workingSets
        }
    }
    
    /// Check if this exercise is the first in its section
    func isFirstInSection(exercise: Exercise, at index: Int) -> Bool {
        let sorted = sortedExercises
        guard index < sorted.count else { return false }
        
        let currentSection = getSectionType(for: exercise)
        
        // Check if previous exercise is in a different section
        if index > 0 {
            let previousExercise = sorted[index - 1]
            let previousSection = getSectionType(for: previousExercise)
            return currentSection != previousSection
        }
        
        // First exercise is always first in its section
        return true
    }
    
    /// Toggle section expansion state
    func toggleSection(_ section: ExerciseSectionType) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
    
    /// Ensure the section containing the given exercise is expanded
    func ensureSectionExpanded(for exercise: Exercise) {
        let section = getSectionType(for: exercise)
        if !expandedSections.contains(section) {
            expandedSections.insert(section)
        }
    }
    
    /// Check if an exercise is a cardio exercise (for Exercise objects with type info)
    func isCardioExercise(_ exercise: Exercise) -> Bool {
        // Check if name indicates cardio
        if exercise.name.isCardioExercise() {
            return true
        }
        // If it's a hold exercise but not calisthenics, it's likely cardio
        if exercise.exerciseType == .hold && exercise.targetHoldDuration != nil && !isCalisthenicsExercise(exercise) {
            return true
        }
        return false
    }
    
    /// Check if an exercise is a calisthenics exercise
    func isCalisthenicsExercise(_ exercise: Exercise) -> Bool {
        // Check if exercise name contains any calisthenics skill name
        let calisthenicsSkillNames = CalisthenicsSkillManager.shared.skills.map { $0.name }
        for skillName in calisthenicsSkillNames {
            if exercise.name.contains(skillName) {
                return true
            }
        }
        
        // Check common calisthenics exercise patterns
        let calisthenicsKeywords = ["Push-up", "Pull-up", "Chin-up", "Dip", "Muscle Up", "Planche", "Handstand", "Lever", "Flag", "L-Sit", "V-Sit"]
        for keyword in calisthenicsKeywords {
            if exercise.name.contains(keyword) {
                return true
            }
        }
        
        // If exercise type is hold, it's likely calisthenics
        if exercise.exerciseType == .hold {
            return true
        }
        
        return false
    }
    
    /// Check if an exercise is a rep-based calisthenics exercise (not hold-based)
    func isRepBasedCalisthenics(_ exerciseName: String) -> Bool {
        // Rep-based calisthenics exercises (these should NOT have hold duration)
        let repBasedKeywords = ["Push-up", "Pull-up", "Chin-up", "Dip", "Muscle Up"]
        for keyword in repBasedKeywords {
            if exerciseName.contains(keyword) {
                return true
            }
        }
        return false
    }
    
    /// Calculate total volume for current exercise (sum of weight × reps)
    var currentExerciseVolume: Int {
        guard let exercise = currentExercise else { return 0 }
        return exercise.sets.reduce(0) { total, set in
            let volume = set.weight * Double(set.reps)
            guard volume.isFinite else { return total }
            return total + Int(volume)
        }
    }
    
    /// Calculate total workout volume (sum across all exercises)
    var totalWorkoutVolume: Int {
        guard let workout = currentWorkout else { return 0 }
        return workout.exercises.reduce(0) { exerciseTotal, exercise in
            let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                let volume = set.weight * Double(set.reps)
                guard volume.isFinite else { return setTotal }
                return setTotal + Int(volume)
            }
            return exerciseTotal + exerciseVolume
        }
    }
    
    /// Count only working sets (exclude warm-up sets) for a given exercise
    func workingSetsCount(for exercise: Exercise) -> Int {
        return exercise.sets.filter { !$0.isWarmup }.count
    }
    
    /// Check if an exercise has completed all of its working sets
    func isExerciseCompleted(_ exercise: Exercise) -> Bool {
        let workingSets = workingSetsCount(for: exercise)
        return workingSets >= exercise.targetSets
    }
    
    /// Format volume with comma separator
    func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
    }
    
    /// Complete a stretch set (tracked by sets only, no weight/reps inputs).
    /// Uses lightweight sets under the hood but skips PR/history for stretches.
    func completeStretchSet() {
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        // Only handle stretch-type exercises here
        guard getSectionType(for: exercise) == .stretch else {
            return
        }
        
        // Create a minimal working set entry (weight 0, reps 1) to track progress
        let workingSetsCount = workingSetsCount(for: exercise)
        let setNumber = workingSetsCount + 1
        let set = ExerciseSet(
            setNumber: setNumber,
            weight: 0,
            reps: 1,
            holdDuration: nil,
            isDropset: false,
            dropsetNumber: nil,
            isWarmup: false
        )
        
        exercise.sets.append(set)
        exercise.currentSet += 1
        workout.exercises[currentExerciseIndex] = exercise
        
        objectWillChange.send()
        currentWorkout = workout
        
        // No PR or history tracking for stretches
        
        // Advance or start rest like a normal set
        if exercise.currentSet > exercise.targetSets {
            advanceToNextExercise()
        } else {
            startRestTimer()
        }
    }
    
    /// Initialize with required dependencies
    /// - Parameters:
    ///   - settingsManager: Required settings manager
    ///   - progressViewModel: Optional progress view model (weak reference)
    ///   - programViewModel: Optional program view model (weak reference)
    ///   - templatesViewModel: Optional templates view model (weak reference)
    ///   - themeManager: Optional theme manager (weak reference)
    init(
        settingsManager: SettingsManager,
        progressViewModel: ProgressViewModel? = nil,
        programViewModel: WorkoutProgramViewModel? = nil,
        templatesViewModel: TemplatesViewModel? = nil,
        themeManager: ThemeManager? = nil
    ) {
        self.settingsManager = settingsManager
        self.progressViewModel = progressViewModel
        self.programViewModel = programViewModel
        self.templatesViewModel = templatesViewModel
        self.themeManager = themeManager
        
        // Load auto-advance settings
        self.autoAdvanceEnabled = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.autoAdvanceEnabled)
        self.autoAdvanceRestDuration = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.autoAdvanceRestDuration)
        
        setupAppLifecycleObservers()
        restoreRestTimerState()
        loadLastWeights()
        
        // Restore workout state if no current workout exists
        if currentWorkout == nil {
            restoreWorkoutState()
            // If workout was restored, also restore timer state
            if currentWorkout != nil {
                // Initialize expanded sections with current exercise's section
                if let currentExercise = currentExercise {
                    expandedSections = [getSectionType(for: currentExercise)]
                }
                restoreWorkoutTimerState()
                // Start timer if workout was restored (preserves restored start time)
                if workoutStartTime != nil {
                    // Create timer without resetting state
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.workoutTimerInterval, repeats: true) { [weak self] _ in
                        guard let self = self, let startTime = self.workoutStartTime else { return }
                        if !self.isTimerPaused {
                            let totalElapsed = Int(Date().timeIntervalSince(startTime))
                            self.elapsedTime = max(0, totalElapsed - self.pausedTimeAccumulator)
                        }
                    }
                    if let timer = timer {
                        RunLoop.main.add(timer, forMode: .common)
                    }
                }
            }
        }
        
        // Log connection status
        if progressViewModel != nil {
            Logger.info("WorkoutViewModel initialized with ProgressViewModel connected", category: .general)
        } else {
            Logger.debug("WorkoutViewModel initialized without ProgressViewModel", category: .general)
        }
    }
    
    /// Reconnect or update the progress view model reference
    /// This can be called if the progress view model needs to be reconnected
    func reconnectProgressViewModel(_ progressVM: ProgressViewModel) {
        progressViewModel = progressVM
        Logger.info("ProgressViewModel reconnected to WorkoutViewModel", category: .general)
    }
    
    private func setupAppLifecycleObservers() {
        #if canImport(UIKit)
        // Listen for app going to background
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackgrounded()
        }
        notificationObservers.append(backgroundObserver)
        
        // Listen for app coming to foreground
        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppForegrounded()
        }
        notificationObservers.append(foregroundObserver)
        
        // Listen for rest timer completion from notification
        let restTimerCompletedObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("RestTimerCompletedFromNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.info("Received rest timer completion notification", category: .notification)
            // If rest timer is still active, complete it
            if self?.restTimerActive == true {
                self?.completeRest()
            } else {
                // Timer may have already completed, but ensure state is clean
                self?.restTimeRemaining = 0
            }
        }
        notificationObservers.append(restTimerCompletedObserver)
        #endif
    }
    
    private func handleAppBackgrounded() {
        backgroundTime = Date()
        
        // If timer is paused during rest, track the pause time
        if isTimerPaused, let pauseStart = pauseStartTime {
            let pauseDuration = Int(Date().timeIntervalSince(pauseStart))
            pausedTimeAccumulator += pauseDuration
            pauseStartTime = nil
        }
        
        // Save workout timer state before invalidating
        saveWorkoutTimerState()
        
        // Pause timers when going to background to save battery
        // We'll recalculate time when foregrounding
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
        
        // Save rest timer state for app termination scenarios
        // This ensures we can restore accurately even if app is killed
        saveRestTimerState()
        
        // Save workout state for auto-restore
        saveWorkoutState()
        
        Logger.debug("App backgrounded - saved timer and workout state", category: .persistence)
    }
    
    private func handleAppForegrounded() {
        guard backgroundTime != nil else { return }
        let backgroundDuration = Int(round(Date().timeIntervalSince(backgroundTime!)))
        self.backgroundTime = nil
        
        // Restore workout state first if no current workout exists
        if currentWorkout == nil {
            restoreWorkoutState()
        }
        
        // Restore workout timer state
        restoreWorkoutTimerState()
        
        // Update workout timer - recalculate from start time, accounting for paused time
        if let startTime = workoutStartTime {
            let totalElapsed = Int(Date().timeIntervalSince(startTime))
            elapsedTime = totalElapsed - pausedTimeAccumulator
            
            // If timer was paused during rest, account for the background time as paused time
            if isTimerPaused && settingsManager.pauseTimerDuringRest {
                pausedTimeAccumulator += Int(backgroundDuration)
                elapsedTime = totalElapsed - pausedTimeAccumulator
            }
            
            // Restart timer if workout is active (was running before backgrounding)
            if currentWorkout != nil && timer == nil {
                startTimer()
            }
        }
        
        // Update rest timer - restore from saved state first if needed
        // Always check UserDefaults first to see if there's a saved state
        if UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.restTimerActive) {
            // There's a saved rest timer state - restore it
            if !restTimerActive || restTimerStartTime == nil {
                Logger.debug("Restoring rest timer from saved state", category: .persistence)
                restoreRestTimerState()
            } else {
                // We have an active timer, but we need to update it based on time that passed in background
                // Always recalculate from the saved start time for accuracy
                let savedTotalDuration = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerTotalDuration)
                let savedStartTimeInterval = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
                let savedRemaining = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
                
                if savedStartTimeInterval > 0 && savedTotalDuration > 0 {
                    // Calculate elapsed time from the original start time
                    let savedStartTime = Date(timeIntervalSince1970: savedStartTimeInterval)
                    let elapsedSinceStart = Date().timeIntervalSince(savedStartTime)
                    let elapsedSinceStartRounded = Int(round(elapsedSinceStart))
                    
                    // Calculate remaining time based on elapsed time
                    let calculatedRemaining = max(0, savedTotalDuration - elapsedSinceStartRounded)
                    
                    Logger.debug("Updating rest timer: savedRemaining=\(savedRemaining)s, calculatedRemaining=\(calculatedRemaining)s, elapsedSinceStart=\(elapsedSinceStartRounded)s, totalDuration=\(savedTotalDuration)s, currentRemaining=\(restTimeRemaining)s, backgroundDuration=\(backgroundDuration)s, savedStartTime=\(savedStartTime)", category: .persistence)
                    
                    // Validate: calculated remaining should be <= saved remaining (time can only decrease)
                    // If calculated is greater, it means the saved start time is wrong or was reset
                    let finalRemaining: Int
                    if calculatedRemaining > savedRemaining + 1 {
                        // Calculated is significantly more than saved - this means start time was reset
                        // Use saved remaining minus background duration as fallback
                        let fallbackRemaining = max(0, savedRemaining - backgroundDuration)
                        Logger.error("Calculated remaining (\(calculatedRemaining)s) > saved remaining (\(savedRemaining)s) - using fallback: \(fallbackRemaining)s", category: .persistence)
                        finalRemaining = fallbackRemaining
                    } else {
                        // Use calculated (more accurate)
                        finalRemaining = calculatedRemaining
                    }
                    
                    if finalRemaining <= 0 {
                        Logger.info("Rest timer completed while app was in background", category: .persistence)
                        completeRest()
                    } else if finalRemaining != restTimeRemaining {
                        // Always update to calculated value (most accurate)
                        Logger.debug("Updating rest timer from saved state: \(finalRemaining)s remaining (was \(restTimeRemaining)s)", category: .persistence)
                        
                        restTimeRemaining = finalRemaining
                        restTimerTotalDuration = savedTotalDuration
                        restTimerOriginalDuration = savedTotalDuration
                        
                        // Adjust start time so timer continues correctly
                        // Set start time to now minus the time that has already elapsed
                        let timeElapsed = savedTotalDuration - finalRemaining
                        restTimerStartTime = Date().addingTimeInterval(-TimeInterval(timeElapsed))
                        
                        restartRestTimer()
                        NotificationManager.shared.scheduleRestTimerNotification(duration: finalRemaining)
                        saveRestTimerState()
                    }
                }
            }
        }
    }
    
    func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let exercises = template.exercises.map { templateExercise in
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: templateExercise.name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: templateExercise.name)
            
            // Use exercise type from template, or determine if not set
            var exerciseType: ExerciseType
            var holdDuration: Int?
            
            if templateExercise.exerciseType != .weightReps {
                exerciseType = templateExercise.exerciseType
                holdDuration = templateExercise.targetHoldDuration
            } else {
                let determined = determineExerciseType(for: templateExercise.name)
                exerciseType = determined.0
                holdDuration = determined.1
            }
            
            // Auto-correct rep-based calisthenics exercises
            // These should always be rep-based (reps + additional weight), not hold-based
            if isRepBasedCalisthenics(templateExercise.name) {
                exerciseType = .weightReps
                holdDuration = nil // Rep-based calisthenics don't have hold duration
            }
            
            return Exercise(
                name: templateExercise.name,
                targetSets: templateExercise.sets,
                exerciseType: exerciseType,
                holdDuration: holdDuration,
                alternatives: alternatives,
                videoURL: videoURL,
                hasDropsets: templateExercise.dropsets,
                numberOfDropsets: templateExercise.dropsets ? 1 : 0,
                weightReductionPerDropset: 5.0
            )
        }
        currentWorkout = Workout(name: template.name, exercises: exercises)
        currentExerciseIndex = 0
        isFromTemplate = true // Mark as from template
        
        // Initialize expanded sections with current exercise's section
        if let currentExercise = currentExercise {
            expandedSections = [getSectionType(for: currentExercise)]
        }
        
        syncDropsetStateFromCurrentExercise()
        startTimer()
        
        // Track exercise usage for all exercises in template
        for exercise in exercises {
            ExerciseUsageTracker.shared.trackExerciseUsage(exercise.name)
        }
    }
    
    private func determineExerciseType(for exerciseName: String) -> (ExerciseType, Int?) {
        // Check if this is a calisthenics skill progression
        for skill in CalisthenicsSkillManager.shared.skills {
            if exerciseName.contains(skill.name) {
                // Find the matching level
                if let level = skill.progressionLevels.first(where: { exerciseName.contains($0.name) }) {
                    if let holdDuration = level.targetHoldDuration {
                        return (.hold, holdDuration)
                    } else {
                        return (.weightReps, nil)
                    }
                }
            }
        }
        
        // Default to weight/reps for regular exercises
        return (.weightReps, nil)
    }
    
    func startWorkout(name: String) {
        currentWorkout = Workout(name: name)
        currentExerciseIndex = 0
        isFromTemplate = false // Mark as manually created
        
        // Initialize expanded sections with current exercise's section
        if let currentExercise = currentExercise {
            expandedSections = [getSectionType(for: currentExercise)]
        }
        
        startTimer()
    }
    
    func startTimer() {
        // Only reset timer state if starting a new workout (start time is nil)
        // If restoring, preserve the restored state
        if workoutStartTime == nil {
        workoutStartTime = Date()
        pausedTimeAccumulator = 0
        isTimerPaused = false
        pauseStartTime = nil
        elapsedTime = 0
        }
        
        // Invalidate any existing timer first
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.workoutTimerInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            if !self.isTimerPaused {
                let totalElapsed = Int(Date().timeIntervalSince(startTime))
                self.elapsedTime = max(0, totalElapsed - self.pausedTimeAccumulator)
            }
        }
        
        // Add timer to RunLoop to ensure it fires correctly
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// Reset the workout timer to zero and restart it
    func resetTimer() {
        workoutStartTime = Date()
        pausedTimeAccumulator = 0
        isTimerPaused = false
        pauseStartTime = nil
        elapsedTime = 0
        // Restart timer if it was running
        if timer != nil {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.workoutTimerInterval, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.workoutStartTime else { return }
                if !self.isTimerPaused {
                    let totalElapsed = Int(Date().timeIntervalSince(startTime))
                    self.elapsedTime = max(0, totalElapsed - self.pausedTimeAccumulator)
                }
            }
        }
    }
    
    func pauseWorkout() {
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        
        // Reset pause state if workout is paused
        if isTimerPaused {
            isTimerPaused = false
            pauseStartTime = nil
        }
    }
    
    func finishWorkout() {
        pauseWorkout()
        
        // Reset pause state
        isTimerPaused = false
        pauseStartTime = nil
        pausedTimeAccumulator = 0
        
        // Clear PR badge when finishing workout
        clearPRBadge()
        
        guard let workout = currentWorkout else { return }
        
        // Calculate completion statistics before saving
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let totalVolume = workout.exercises.reduce(0) { exerciseTotal, exercise in
            let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                let volume = set.weight * Double(set.reps)
                guard volume.isFinite else { return setTotal }
                return setTotal + Int(volume)
            }
            return exerciseTotal + exerciseVolume
        }
        
        // Check for PRs achieved during this workout
        var prsAchieved: [String] = []
        if let progressVM = progressViewModel {
            // Get PRs that were added today
            let today = Calendar.current.startOfDay(for: Date())
            let todayPRs = progressVM.prs.filter { Calendar.current.startOfDay(for: $0.date) == today }
            prsAchieved = Array(Set(todayPRs.map { $0.exercise }))
        }
        
        // Create completion stats
        let stats = WorkoutCompletionStats(
            duration: elapsedTime,
            exerciseCount: workout.exercises.count,
            totalSets: totalSets,
            totalVolume: totalVolume,
            prsAchieved: prsAchieved
        )
        
        // Save completed workout FIRST - this triggers WorkoutHistoryManager updates
        WorkoutHistoryManager.shared.addCompletedWorkout(workout)
        
        // Save workout to Apple Health
        Task {
            do {
                let endDate = workout.startDate.addingTimeInterval(TimeInterval(elapsedTime))
                try await HealthKitManager.shared.saveWorkout(
                    name: workout.name,
                    exercises: workout.exercises,
                    startDate: workout.startDate,
                    endDate: endDate,
                    totalVolume: totalVolume
                )
            } catch {
                Logger.error("Failed to save workout to HealthKit", error: error, category: .general)
            }
        }
        
        // Add workout date to progress tracking and calculate streak IMMEDIATELY
        if let progressVM = progressViewModel {
            Logger.info("📊 Updating progress stats after workout completion", category: .general)
            progressVM.addWorkoutDate()
            // Force immediate streak calculation (addWorkoutDate already calls calculateStreaks, but ensure it's synchronous)
            progressVM.calculateStreaks()
            // Invalidate volume cache since new workout was added
            progressVM.invalidateVolumeCache()
            // Force immediate volume and count update
            progressVM.updateVolumeAndCount()
            Logger.info("✅ Progress stats updated - PRs: \(progressVM.prs.count), Workout dates: \(progressVM.workoutDates.count)", category: .general)
        } else {
            Logger.error("❌ ProgressViewModel is nil - stats not updated!", category: .general)
        }
        
        // Advance program day if workout was from a program
        if let programVM = programViewModel,
           let activeProgram = programVM.activeProgram,
           let program = programVM.programs.first(where: { $0.id == activeProgram.programId }),
           workout.name.contains(program.name) {
            programVM.advanceToNextDay(for: program)
        }
        
        // Only show completion modal if workout came from template
        if isFromTemplate {
        // Store stats and show modal BEFORE clearing workout state
        // This ensures modal appears with accurate data and view is still visible
        completionStats = stats
        showCompletionModal = true
        
        Logger.debug("Showing completion modal - stats: \(stats.exerciseCount) exercises, \(stats.totalSets) sets, \(stats.totalVolume) lbs", category: .general)
        
        // Celebration haptic feedback
        HapticManager.success()
        } else {
            // For manually created workouts, just clear state without showing modal
            currentWorkout = nil
            currentExerciseIndex = 0
            elapsedTime = 0
            isFromTemplate = false
            HapticManager.success()
        }
        
        // Clear saved workout state when workout is finished
        clearWorkoutState()
        clearWorkoutTimerState()
        
        // Don't clear workout state yet if showing modal - wait until modal is dismissed
        // This ensures the modal overlay remains visible
    }
    
    func completeSet(weight: Double, reps: Int, isWarmup: Bool = false) {
        // Validate input
        switch validateSetCompletion(weight: weight, reps: reps) {
        case .failure(let error):
            // Log error - in a production app, you might want to show an alert
            Logger.error("Set completion validation failed", error: error, category: .validation)
            return
        case .success:
            break
        }
        
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        // Store state for undo before making changes
        let setCountBefore = exercise.sets.count
        // Don't check for PR here - we'll check after the set is added
        // This prevents the PR from being added twice
        
        // Update dropset configuration from state before completing set
        exercise.hasDropsets = dropsetsEnabled
        exercise.numberOfDropsets = dropsetsEnabled ? numberOfDropsets : 0
        exercise.weightReductionPerDropset = max(AppConstants.Dropset.minWeightReduction, weightReductionPerDropset)
        
        // Create main set
        // Count only working sets (non-warmup) to determine set number
        let workingSetsCount = exercise.sets.filter { !$0.isWarmup }.count
        let mainSetNumber = workingSetsCount + 1
        let mainSet = ExerciseSet(
            setNumber: mainSetNumber,
            weight: weight,
            reps: reps,
            isDropset: false,
            isWarmup: isWarmup
        )
        
        exercise.sets.append(mainSet)
        
        // Store last weight used for this exercise
        lastWeightPerExercise[exercise.name] = weight
        saveLastWeights()
        
        // If dropsets are enabled, automatically create dropset sets
        // Use state variables directly as source of truth
        if dropsetsEnabled && numberOfDropsets > 0 {
            let reductionAmount = max(AppConstants.Dropset.minWeightReduction, weightReductionPerDropset)
            
            for dropsetNumber in 1...numberOfDropsets {
                let dropsetWeight = max(0, weight - (Double(dropsetNumber) * reductionAmount))
                
                let dropset = ExerciseSet(
                    setNumber: mainSetNumber, // Same set number as main set
                    weight: dropsetWeight,
                    reps: reps,
                    isDropset: true,
                    dropsetNumber: dropsetNumber,
                    isWarmup: false
                )
                
                exercise.sets.append(dropset)
            }
        }
        
        // Increment currentSet only after completing the main set (and its dropsets)
        exercise.currentSet += 1
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI to detect the change by explicitly triggering objectWillChange
        // and assigning a new workout instance
        objectWillChange.send()
        currentWorkout = workout
        
        // Track exercise history
        ExerciseHistoryManager.shared.updateLastWeightReps(
            exerciseName: exercise.name,
            weight: weight,
            reps: reps
        )
        
        // Check for PR and set badge message if it's a new PR
        var isNewPR = false
        if let progressVM = progressViewModel {
            let isFirstTime = !progressVM.availableExercises.contains(exercise.name)
            
            if isFirstTime {
                // First time this exercise is being tracked - don't show PR badge
                progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: weight, reps: reps)
            } else {
                // Check for PR
                isNewPR = checkForPR(exercise: exercise.name, weight: weight, reps: reps)
                
                if isNewPR {
                    // Set PR message immediately - badge will show when rest timer appears
                    prMessage = "New PR: \(Int(weight)) lbs × \(reps) reps"
                    Logger.info("New PR achieved: \(exercise.name) - \(Int(weight)) lbs × \(reps) reps", category: .general)
                } else {
                    // Make sure message is cleared if not a PR
                    if !prMessage.isEmpty {
                        prMessage = ""
                    }
                }
            }
        }
        
        // Store undo state (use isNewPR which was just calculated)
        lastCompletedSet = (exerciseIndex: currentExerciseIndex, setCount: setCountBefore, wasPR: isNewPR)
        showUndoButton = true
        
        // Auto-hide undo button after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.showUndoButton {
                withAnimation(AppAnimations.quick) {
                    self.showUndoButton = false
                }
            }
        }
        
        // Check if all sets are completed before starting rest timer
        // If all sets are done, advance to next exercise instead of starting rest
        Logger.debug("Before rest timer check - prMessage: '\(prMessage)', exercise.currentSet: \(exercise.currentSet), targetSets: \(exercise.targetSets)", category: .general)
        if exercise.currentSet > exercise.targetSets {
            // All sets completed, advance to next exercise immediately
            // Clear PR badge since we're not showing rest timer
            Logger.debug("All sets completed - clearing PR badge and advancing", category: .general)
            clearPRBadge()
            advanceToNextExercise()
        } else {
            // Start rest timer (will show PR badge if there's a PR message)
            Logger.debug("Starting rest timer - prMessage before start: '\(prMessage)'", category: .general)
            startRestTimer()
        }
    }
    
    func undoLastSet() {
        guard let undoState = lastCompletedSet,
              var workout = currentWorkout,
              undoState.exerciseIndex < workout.exercises.count else {
            return
        }
        
        var exercise = workout.exercises[undoState.exerciseIndex]
        
        // Remove sets that were added (main set + dropsets)
        // Only remove working sets, not warm-up sets
        let workingSetsBefore = exercise.sets.filter { !$0.isWarmup }.count
        let workingSetsToRemove = workingSetsBefore - undoState.setCount
        if workingSetsToRemove > 0 {
            // Remove the last N working sets (skip warm-up sets)
            var removed = 0
            for i in (0..<exercise.sets.count).reversed() {
                if !exercise.sets[i].isWarmup {
                    exercise.sets.remove(at: i)
                    removed += 1
                    if removed >= workingSetsToRemove {
                        break
                    }
                }
            }
        }
        
        // Decrement currentSet if needed (only count working sets)
        let currentWorkingSets = exercise.sets.filter { !$0.isWarmup }.count
        exercise.currentSet = max(1, currentWorkingSets + 1)
        
        // Update exercise in workout
        workout.exercises[undoState.exerciseIndex] = exercise
        
        // If a PR was recorded, remove it
        if undoState.wasPR, let progressVM = progressViewModel {
            // Find and remove the most recent PR for this exercise
            // Sort by date descending and remove the first one (most recent)
            let recentPRs = progressVM.prs
                .filter { $0.exercise == exercise.name }
                .sorted { $0.date > $1.date }
            
            if let mostRecentPR = recentPRs.first {
                // Check if it was added very recently (within last 5 seconds to be safe)
                if Date().timeIntervalSince(mostRecentPR.date) < 5.0 {
                    progressVM.prs.removeAll { $0.id == mostRecentPR.id }
                }
            }
        }
        
        // Update workout
        objectWillChange.send()
        currentWorkout = workout
        
        // Hide undo button
        withAnimation(AppAnimations.quick) {
            showUndoButton = false
        }
        lastCompletedSet = nil
        
        HapticManager.success()
    }
    
    func deleteSet(setId: UUID) {
        guard var workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else {
            return
        }
        
        var exercise = workout.exercises[currentExerciseIndex]
        
        // Find and remove the set
        guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setId }) else {
            return
        }
        
        let setToDelete = exercise.sets[setIndex]
        exercise.sets.remove(at: setIndex)
        
        // Update currentSet counter if needed (only for working sets)
        if !setToDelete.isWarmup {
            let currentWorkingSets = exercise.sets.filter { !$0.isWarmup }.count
            exercise.currentSet = max(1, currentWorkingSets + 1)
        }
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI update
        objectWillChange.send()
        currentWorkout = workout
        
        HapticManager.impact(style: .medium)
    }
    
    func completeCalisthenicsSet(reps: Int, additionalWeight: Double) {
        // Store last additional weight used for this exercise
        if let exercise = currentExercise {
            lastWeightPerExercise[exercise.name] = additionalWeight
            saveLastWeights()
        }
        // Validate input
        guard reps >= AppConstants.Validation.minReps,
              reps <= AppConstants.Validation.maxReps else {
            Logger.error("Reps validation failed: \(reps)", category: .validation)
            return
        }
        
        guard additionalWeight >= 0,
              additionalWeight <= AppConstants.Validation.maxWeight else {
            Logger.error("Additional weight validation failed: \(additionalWeight)", category: .validation)
            return
        }
        
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        // Create set with reps and additional weight (weight represents additional weight for calisthenics)
        let set = ExerciseSet(
            setNumber: exercise.currentSet,
            weight: additionalWeight,
            reps: reps,
            holdDuration: nil
        )
        
        exercise.sets.append(set)
        exercise.currentSet += 1
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI to detect the change
        objectWillChange.send()
        currentWorkout = workout
        
        // Track exercise history
        ExerciseHistoryManager.shared.updateLastWeightReps(
            exerciseName: exercise.name,
            weight: additionalWeight,
            reps: reps
        )
        
        // Check for PR and set badge message if it's a new PR
        var isNewPR = false
        if let progressVM = progressViewModel {
            if !progressVM.availableExercises.contains(exercise.name) {
                // First time this exercise is being tracked - don't show PR badge
                progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: additionalWeight, reps: reps)
                Logger.debug("First time calisthenics exercise - no PR badge", category: .general)
            } else {
                // Check for PR
                isNewPR = checkForPR(exercise: exercise.name, weight: additionalWeight, reps: reps)
                if isNewPR {
                    // Set PR message immediately - badge will show when rest timer appears
                    prMessage = "New PR: \(Int(additionalWeight)) lbs × \(reps) reps"
                    Logger.info("PR detected! Message set: \(prMessage)", category: .general)
                }
            }
        }
        
        // Check if all sets are completed before starting rest timer
        if exercise.currentSet > exercise.targetSets {
            // All sets completed, advance to next exercise immediately
            // Clear PR badge since we're not showing rest timer
            clearPRBadge()
            advanceToNextExercise()
        } else {
            // Start rest timer (will show PR badge if there's a PR message)
            startRestTimer()
        }
    }
    
    func completeCalisthenicsHoldSet(duration: Int, additionalWeight: Double) {
        // Validate input
        guard duration >= AppConstants.Validation.minHoldDuration,
              duration <= AppConstants.Validation.maxHoldDuration else {
            Logger.error("Hold duration validation failed: \(duration)", category: .validation)
            return
        }
        
        guard additionalWeight >= 0,
              additionalWeight <= AppConstants.Validation.maxWeight else {
            Logger.error("Additional weight validation failed: \(additionalWeight)", category: .validation)
            return
        }
        
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        // Store last additional weight used for this exercise
        lastWeightPerExercise[exercise.name] = additionalWeight
        saveLastWeights()
        
        // Create set with hold duration and additional weight
        let set = ExerciseSet(
            setNumber: exercise.currentSet,
            weight: additionalWeight, // Store additional weight
            reps: 0, // No reps for hold exercises
            holdDuration: duration
        )
        
        exercise.sets.append(set)
        exercise.currentSet += 1
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI to detect the change
        objectWillChange.send()
        currentWorkout = workout
        
        // Track exercise history (for hold exercises, use duration as "reps" equivalent)
        ExerciseHistoryManager.shared.updateLastWeightReps(
            exerciseName: exercise.name,
            weight: additionalWeight,
            reps: duration
        )
        
        // Check for PR and set badge message if it's a new PR
        var isNewPR = false
        if let progressVM = progressViewModel {
            if !progressVM.availableExercises.contains(exercise.name) {
                // First time this exercise is being tracked - don't show PR badge
                progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: additionalWeight, reps: duration)
                Logger.debug("First time hold exercise - no PR badge", category: .general)
            } else {
                // Check for PR (using duration as reps equivalent for hold exercises)
                isNewPR = checkForPR(exercise: exercise.name, weight: additionalWeight, reps: duration)
                if isNewPR {
                    // Set PR message immediately - badge will show when rest timer appears
                    prMessage = "New PR: \(Int(additionalWeight)) lbs × \(duration)s"
                    Logger.info("PR detected! Message set: \(prMessage)", category: .general)
                }
            }
        }
        
        // Check if all sets are completed before starting rest timer
        if exercise.currentSet > exercise.targetSets {
            // All sets completed, advance to next exercise immediately
            // Clear PR badge since we're not showing rest timer
            clearPRBadge()
            advanceToNextExercise()
        } else {
            // Start rest timer (will show PR badge if there's a PR message)
        startRestTimer()
        }
    }
    
    // Keep old function for backward compatibility (if needed elsewhere)
    func completeHoldSet(duration: Int) {
        // For calisthenics hold exercises, use additional weight = 0
        completeCalisthenicsHoldSet(duration: duration, additionalWeight: 0)
    }
    
    func addExercise(name: String, targetSets: Int, type: ExerciseType, holdDuration: Int?) {
        // Validate input
        switch validateAddExercise(name: name, targetSets: targetSets, type: type, holdDuration: holdDuration) {
        case .failure(let error):
            // Log error - in a production app, you might want to show an alert
            Logger.error("Add exercise validation failed", error: error, category: .validation)
            return
        case .success:
            break
        }
        
        // Auto-correct rep-based calisthenics exercises
        // These should always be rep-based (reps + additional weight), not hold-based
        var correctedType = type
        var correctedHoldDuration = holdDuration
        if isRepBasedCalisthenics(name) {
            correctedType = .weightReps
            correctedHoldDuration = nil // Rep-based calisthenics don't have hold duration
        }
        
        guard var workout = currentWorkout else {
            // Create new workout if none exists
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: name)
            let exercise = Exercise(
                name: name,
                targetSets: targetSets,
                exerciseType: correctedType,
                holdDuration: correctedHoldDuration,
                alternatives: alternatives,
                videoURL: videoURL
            )
            currentWorkout = Workout(name: "Workout", exercises: [exercise])
            currentExerciseIndex = 0
            isFromTemplate = false // Mark as manually created
            startTimer()
            return
        }
        
        // Check for duplicate exercises (case-insensitive)
        let exerciseNameLower = name.lowercased()
        let isDuplicate = workout.exercises.contains { existingExercise in
            existingExercise.name.lowercased() == exerciseNameLower
        }
        
        if isDuplicate {
            Logger.info("Duplicate exercise '\(name)' not added", category: .validation)
            return
        }
        
        let alternatives = ExerciseDataManager.shared.getAlternatives(for: name)
        let videoURL = ExerciseDataManager.shared.getVideoURL(for: name)
        let exercise = Exercise(
            name: name,
            targetSets: targetSets,
            exerciseType: correctedType,
            holdDuration: correctedHoldDuration,
            alternatives: alternatives,
            videoURL: videoURL
        )
        workout.exercises.append(exercise)
        currentWorkout = workout
        
        // Track exercise usage
        ExerciseUsageTracker.shared.trackExerciseUsage(name)
    }
    
    func switchToAlternative(alternativeName: String) {
        // Validate input
        switch validateAlternativeSwitch(alternativeName: alternativeName) {
        case .failure(let error):
            // Log error - in a production app, you might want to show an alert
            Logger.error("Alternative switch validation failed", error: error, category: .validation)
            return
        case .success:
            break
        }
        
        guard var workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        // Get alternatives for the alternative exercise (recursive)
        let alternatives = ExerciseDataManager.shared.getAlternatives(for: alternativeName)
        let videoURL = ExerciseDataManager.shared.getVideoURL(for: alternativeName)
        
        // Replace current exercise with alternative
        let currentExercise = workout.exercises[currentExerciseIndex]
        var alternativeExercise = Exercise(
            name: alternativeName,
            targetSets: currentExercise.targetSets,
            exerciseType: currentExercise.exerciseType,
            holdDuration: currentExercise.targetHoldDuration,
            alternatives: alternatives,
            videoURL: videoURL,
            hasDropsets: currentExercise.hasDropsets,
            numberOfDropsets: currentExercise.numberOfDropsets,
            weightReductionPerDropset: currentExercise.weightReductionPerDropset
        )
        
        // Preserve sets if any
        alternativeExercise.sets = currentExercise.sets
        alternativeExercise.currentSet = currentExercise.currentSet
        
        workout.exercises[currentExerciseIndex] = alternativeExercise
        currentWorkout = workout
        
        // Sync dropset state after switching
        syncDropsetStateFromCurrentExercise()
    }
    
    private func startRestTimer() {
        Logger.debug("startRestTimer called - prMessage: '\(prMessage)', isEmpty: \(prMessage.isEmpty), showPRBadge: \(showPRBadge)", category: .general)
        
        // Show PR badge when rest timer appears if there's a PR message
        // IMPORTANT: PR badge must be shown regardless of auto-advance state
        if !prMessage.isEmpty {
            // Set badge state immediately
            showPRBadge = true
            Logger.info("✅ SHOWING PR BADGE: '\(prMessage)'", category: .general)
            Logger.info("✅ showPRBadge = \(showPRBadge), prMessage = '\(prMessage)'", category: .general)
            
            // Force UI update
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.objectWillChange.send()
                Logger.info("✅ UI update triggered - showPRBadge: \(self.showPRBadge)", category: .general)
            }
            
            // Hide PR badge after configured duration
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.PRBadge.displayDuration) { [weak self] in
                guard let self = self else { return }
                self.showPRBadge = false
                Logger.info("Hiding PR badge after \(AppConstants.PRBadge.displayDuration) seconds", category: .general)
                // Clear message after badge is hidden
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    if !self.showPRBadge {
                        self.prMessage = ""
                        Logger.debug("PR message cleared", category: .general)
                    }
                }
            }
        } else {
            Logger.debug("❌ No PR message to show - prMessage is empty", category: .general)
        }
        
        // Check if auto-advance is enabled with immediate (0 duration) rest
        if autoAdvanceEnabled && autoAdvanceRestDuration == 0 {
            // Don't start a visible rest timer - just show the PR badge (if any)
            // and auto-advance AFTER the PR badge has had time to display
            let autoAdvanceDelay = AppConstants.PRBadge.displayDuration + 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + autoAdvanceDelay) { [weak self] in
                guard let self = self else { return }
                self.completeRest()
            }
            return
        }
        
        // Normal rest timer flow
        restTimerActive = true
        restTimerOriginalDuration = settingsManager.restTimerDuration
        restTimerTotalDuration = restTimerOriginalDuration
        restTimeRemaining = restTimerOriginalDuration
        restTimerStartTime = Date()
        
        // Pause workout timer during rest if setting is enabled
        if settingsManager.pauseTimerDuringRest {
            pauseWorkoutTimer()
        }
        
        // Validate timer duration
        guard restTimerOriginalDuration > 0 else {
            Logger.error("Invalid rest timer duration: \(restTimerOriginalDuration)", category: .validation)
            restTimerActive = false
            return
        }
        
        // Schedule notification for when rest timer completes
        NotificationManager.shared.scheduleRestTimerNotification(duration: restTimeRemaining)
        
        // Save state for persistence
        saveRestTimerState()
        
        startRestTimerTick()
    }
    
    private func restartRestTimer() {
        // Don't reset start time - keep the original start time for accurate restoration
        // Only set it if it's nil (shouldn't happen, but safety check)
        if restTimerStartTime == nil {
        restTimerStartTime = Date()
        }
        startRestTimerTick()
    }
    
    private func startRestTimerTick() {
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.restTimerInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Ensure time remaining is never negative
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
                
                // Haptic feedback for timer milestones
                if self.restTimeRemaining == 30 {
                    HapticManager.warning()
                } else if self.restTimeRemaining == 15 {
                    HapticManager.impact(style: .light)
                } else if self.restTimeRemaining == 5 {
                    HapticManager.impact(style: .medium)
                }
                
                // Check for auto-advance
                if self.autoAdvanceEnabled {
                    let elapsed = self.restTimerTotalDuration - self.restTimeRemaining
                    if elapsed >= self.autoAdvanceRestDuration {
                        // Auto-advance after minimum rest duration
                        self.restTimeRemaining = 0
                        self.completeRest()
                        return
                    }
                }
            } else {
                // Timer reached zero or went negative - complete rest
                self.restTimeRemaining = 0
                self.completeRest()
            }
        }
        
        // Add timer to RunLoop to ensure it fires correctly, especially when app is backgrounded
        if let restTimer = restTimer {
            RunLoop.main.add(restTimer, forMode: .common)
        }
    }
    
    func skipRest() {
        // Clear PR badge when skipping rest
        clearPRBadge()
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
        restTimerStartTime = nil
        restTimerOriginalDuration = 0
        restTimerTotalDuration = AppConstants.Timer.defaultRestDuration
        
        // Resume workout timer if it was paused
        if settingsManager.pauseTimerDuringRest {
            resumeWorkoutTimer()
        }
        
        // Cancel notification since timer was skipped
        NotificationManager.shared.cancelRestTimerNotification()
        
        // Clear saved state
        clearRestTimerState()
        
        // Trigger UI update to prepare for next set
        readyForNextSet = UUID()
        
        // Check if exercise is complete and advance if needed
        checkAndAdvanceExercise()
    }
    
    func completeRest() {
        // Clear PR badge when completing rest
        clearPRBadge()
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
        restTimerStartTime = nil
        restTimerOriginalDuration = 0
        restTimerTotalDuration = AppConstants.Timer.defaultRestDuration
        
        // Resume workout timer if it was paused
        if settingsManager.pauseTimerDuringRest {
            resumeWorkoutTimer()
        }
        
        // Cancel notification since timer completed
        NotificationManager.shared.cancelRestTimerNotification()
        
        // Clear saved state
        clearRestTimerState()
        
        // Trigger UI update to prepare for next set
        readyForNextSet = UUID()
        
        // Check if exercise is complete and advance if needed
        checkAndAdvanceExercise()
    }
    
    // MARK: - Auto-Advance
    
    func toggleAutoAdvance() {
        autoAdvanceEnabled.toggle()
        UserDefaults.standard.set(autoAdvanceEnabled, forKey: AppConstants.UserDefaultsKeys.autoAdvanceEnabled)
        HapticManager.impact(style: .light)
    }
    
    func setAutoAdvanceRestDuration(_ duration: Int) {
        autoAdvanceRestDuration = max(0, duration)
        UserDefaults.standard.set(autoAdvanceRestDuration, forKey: AppConstants.UserDefaultsKeys.autoAdvanceRestDuration)
    }
    
    // MARK: - Timer Controls
    
    func quickSkipRest() {
        skipRest()
    }
    
    func addTimeToRest(_ seconds: Int) {
        guard restTimerActive else { return }
        restTimeRemaining += seconds
        restTimerTotalDuration += seconds
        restTimerOriginalDuration += seconds
        HapticManager.impact(style: .light)
    }
    
    func subtractTimeFromRest(_ seconds: Int) {
        guard restTimerActive else { return }
        let newRemaining = max(0, restTimeRemaining - seconds)
        let reduction = restTimeRemaining - newRemaining
        restTimeRemaining = newRemaining
        restTimerTotalDuration = max(restTimeRemaining, restTimerTotalDuration - reduction)
        restTimerOriginalDuration = max(restTimeRemaining, restTimerOriginalDuration - reduction)
        HapticManager.impact(style: .light)
        
        // If timer reaches zero, complete rest
        if restTimeRemaining == 0 {
            completeRest()
        }
    }
    
    // MARK: - Timer Pause During Rest
    
    private func pauseWorkoutTimer() {
        guard !isTimerPaused else { return }
        isTimerPaused = true
        pauseStartTime = Date()
        // Update elapsed time immediately to reflect pause
        if let startTime = workoutStartTime {
            let totalElapsed = Int(Date().timeIntervalSince(startTime))
            elapsedTime = max(0, totalElapsed - pausedTimeAccumulator)
        }
    }
    
    private func resumeWorkoutTimer() {
        guard isTimerPaused, let pauseStart = pauseStartTime else { return }
        let pauseDuration = Int(Date().timeIntervalSince(pauseStart))
        pausedTimeAccumulator += pauseDuration
        isTimerPaused = false
        pauseStartTime = nil
        // Update elapsed time to reflect resume
        if let startTime = workoutStartTime {
            let totalElapsed = Int(Date().timeIntervalSince(startTime))
            elapsedTime = max(0, totalElapsed - pausedTimeAccumulator)
        }
    }
    
    // MARK: - Warm-up Sets
    
    func addWarmupSets(for workingWeight: Double, reps: Int) {
        guard var exercise = currentExercise,
              var workout = currentWorkout,
              workingWeight > 0, reps > 0 else { return }
        
        // Don't add warm-up sets if they already exist
        guard !hasWarmupSets() else { return }
        
        // Don't add warm-up sets if there are already working sets
        guard exercise.sets.isEmpty else { return }
        
        let percentages = settingsManager.warmupPercentages.sorted()
        guard !percentages.isEmpty else { return }
        
        // Calculate warm-up sets and insert before first working set
        // Use negative setNumbers for warm-up sets to avoid conflicts with working sets
        var warmupSets: [ExerciseSet] = []
        for (index, percentage) in percentages.enumerated() {
            let warmupWeight = max(0, (workingWeight * percentage / 100.0).rounded(toNearest: 2.5))
            // Use same reps as working set, or reduce for very light warm-up sets
            let warmupReps = percentage < 50 ? min(reps, 5) : reps
            let warmupSet = ExerciseSet(
                setNumber: -(index + 1), // Negative numbers for warm-up sets
                weight: warmupWeight,
                reps: warmupReps,
                isDropset: false,
                isWarmup: true // Mark as warm-up
            )
            warmupSets.append(warmupSet)
        }
        
        // Insert warm-up sets at the beginning
        exercise.sets.insert(contentsOf: warmupSets, at: 0)
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI update
        objectWillChange.send()
        currentWorkout = workout
        
        HapticManager.success()
    }
    
    func hasWarmupSets() -> Bool {
        guard let exercise = currentExercise else { return false }
        // Check if any sets are marked as warm-up
        return exercise.sets.contains { $0.isWarmup }
    }
    
    private func checkAndAdvanceExercise() {
        guard let exercise = currentExercise,
              currentWorkout != nil else { return }
        
        // Count only working sets (exclude warm-up sets)
        let workingSetsCount = exercise.sets.filter { !$0.isWarmup }.count
        
        // Check if all sets are completed
        if workingSetsCount >= exercise.targetSets {
            // All sets completed, move to next exercise
            advanceToNextExercise()
        }
    }
    
    private func clearPRBadge() {
        Logger.debug("clearPRBadge called - clearing showPRBadge and prMessage", category: .general)
        showPRBadge = false
        prMessage = ""
    }
    
    private func advanceToNextExercise() {
        // Clear PR badge when advancing to next exercise
        clearPRBadge()
        guard let workout = currentWorkout else { return }
        
        // Check if all exercises are completed (not just if we're on the last one)
        let allExercisesComplete = workout.exercises.allSatisfy { exercise in
            let workingSetsCount = exercise.sets.filter { !$0.isWarmup }.count
            return workingSetsCount >= exercise.targetSets
        }
        
        if allExercisesComplete {
            // All exercises completed - automatically finish the workout
            // This shows the completion modal and saves stats to dashboard
            HapticManager.success()
            finishWorkout()
        } else if currentExerciseIndex < workout.exercises.count - 1 {
            // Move to next exercise with animation
            withAnimation(AppAnimations.smooth) {
                currentExerciseIndex += 1
            }
            syncDropsetStateFromCurrentExercise()
            
            // Ensure the section containing the next exercise is expanded
            if let nextExercise = currentExercise {
                ensureSectionExpanded(for: nextExercise)
            }
            
            HapticManager.selection()
            
            // Trigger UI update to prepare for next set in new exercise
            readyForNextSet = UUID()
        }
    }
    
    // Sync dropset state from current exercise
    func syncDropsetStateFromCurrentExercise() {
        guard let exercise = currentExercise else {
            dropsetsEnabled = false
            numberOfDropsets = AppConstants.Dropset.defaultDropsets
            weightReductionPerDropset = AppConstants.Dropset.defaultWeightReduction
            return
        }
        
        dropsetsEnabled = exercise.hasDropsets
        numberOfDropsets = exercise.numberOfDropsets > 0 ? exercise.numberOfDropsets : AppConstants.Dropset.defaultDropsets
        weightReductionPerDropset = max(AppConstants.Dropset.minWeightReduction, exercise.weightReductionPerDropset)
    }
    
    // Update current exercise with dropset configuration
    func updateCurrentExerciseDropsetConfiguration() {
        guard var workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        workout.exercises[currentExerciseIndex].hasDropsets = dropsetsEnabled
        workout.exercises[currentExerciseIndex].numberOfDropsets = dropsetsEnabled ? numberOfDropsets : 0
        workout.exercises[currentExerciseIndex].weightReductionPerDropset = max(AppConstants.Dropset.minWeightReduction, weightReductionPerDropset)
        
        currentWorkout = workout
    }
    
    func abortWorkoutTimer() {
        // Reset the workout timer to 0
        timer?.invalidate()
        timer = nil
        workoutStartTime = Date()
        elapsedTime = 0
        startTimer()
    }
    
    func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Rest Timer Persistence
    
    private func saveRestTimerState() {
        guard restTimerActive else {
            clearRestTimerState()
            return
        }
        
        // Ensure we have valid values before saving
        guard restTimeRemaining >= 0, restTimerTotalDuration > 0 else {
            Logger.error("Invalid rest timer state - not saving", category: .persistence)
            return
        }
        
        UserDefaults.standard.set(restTimerActive, forKey: AppConstants.UserDefaultsKeys.restTimerActive)
        UserDefaults.standard.set(max(0, restTimeRemaining), forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
        UserDefaults.standard.set(restTimerTotalDuration, forKey: AppConstants.UserDefaultsKeys.restTimerTotalDuration)
        
        // Always save the start time - this is the original start time when timer first started
        // Don't save if it's nil (shouldn't happen, but safety check)
        if let startTime = restTimerStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
            Logger.debug("Saved rest timer state: \(restTimeRemaining)s remaining of \(restTimerTotalDuration)s total, startTime=\(startTime)", category: .persistence)
        } else {
            Logger.error("Cannot save rest timer state - startTime is nil", category: .persistence)
        }
    }
    
    private func restoreRestTimerState() {
        // Only restore if there's an active workout
        guard currentWorkout != nil else {
            clearRestTimerState()
            return
        }
        
        guard UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.restTimerActive) else {
            return
        }
        
        let totalDuration = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerTotalDuration)
        let startTimeInterval = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
        let savedRemaining = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
        
        guard startTimeInterval > 0, totalDuration > 0 else {
            clearRestTimerState()
            return
        }
        
        let originalStartTime = Date(timeIntervalSince1970: startTimeInterval)
        let elapsedSinceStart = Date().timeIntervalSince(originalStartTime)
        // Round elapsed time to nearest second to avoid fractional second issues
        let elapsed = Int(round(elapsedSinceStart))
        
        // Calculate remaining time based on elapsed time since original start
        let calculatedRemaining = max(0, totalDuration - elapsed)
        
        // Use the calculated remaining time (more accurate than saved value)
        // The saved value might be slightly off due to timing differences
        let newRemaining = calculatedRemaining
        
        Logger.debug("Restoring rest timer: saved=\(savedRemaining)s, calculated=\(calculatedRemaining)s, elapsed=\(elapsed)s (raw=\(elapsedSinceStart)), total=\(totalDuration)s, originalStart=\(originalStartTime)", category: .persistence)
        
        if newRemaining <= 0 {
            // Timer completed while app was terminated
            clearRestTimerState()
            // Complete rest if timer finished
            completeRest()
            return
        }
        
        // Restore state - preserve original total duration for accurate progress calculation
        restTimerActive = true
        
        // Note: Don't show PR badge when restoring from background
        // PR badge should only show when rest timer first appears after completing a set
        
        restTimeRemaining = newRemaining
        restTimerTotalDuration = totalDuration // Preserve original total duration
        restTimerOriginalDuration = totalDuration // Set to original total, not remaining
        
        // Set start time to now minus the time that has already elapsed
        // This ensures the timer continues counting down correctly
        // The elapsed time is the difference between total duration and remaining time
        let timeElapsed = totalDuration - newRemaining
        restTimerStartTime = Date().addingTimeInterval(-TimeInterval(timeElapsed))
        
        // Restart the timer
        restartRestTimer()
        
        // Reschedule notification with remaining time
        NotificationManager.shared.scheduleRestTimerNotification(duration: newRemaining)
        
        Logger.debug("Restored rest timer state: \(newRemaining)s remaining of \(totalDuration)s total (elapsed: \(elapsed)s, original start: \(originalStartTime))", category: .persistence)
    }
    
    
    // MARK: - Workout Timer Persistence
    
    private func saveWorkoutTimerState() {
        guard currentWorkout != nil else {
            clearWorkoutTimerState()
            return
        }
        
        if let startTime = workoutStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.workoutStartTime)
        }
        UserDefaults.standard.set(elapsedTime, forKey: AppConstants.UserDefaultsKeys.workoutElapsedTime)
        UserDefaults.standard.set(pausedTimeAccumulator, forKey: AppConstants.UserDefaultsKeys.workoutPausedTimeAccumulator)
        UserDefaults.standard.set(isTimerPaused, forKey: AppConstants.UserDefaultsKeys.workoutIsPaused)
        if let pauseStart = pauseStartTime {
            UserDefaults.standard.set(pauseStart.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.workoutPauseStartTime)
        } else {
            UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutPauseStartTime)
        }
        
        Logger.debug("Saved workout timer state: elapsed=\(elapsedTime)s, paused=\(isTimerPaused)", category: .persistence)
    }
    
    private func restoreWorkoutTimerState() {
        guard currentWorkout != nil else { return }
        
        let startTimeInterval = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.workoutStartTime)
        guard startTimeInterval > 0 else { return }
        
        let savedStartTime = Date(timeIntervalSince1970: startTimeInterval)
        let savedPausedAccumulator = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.workoutPausedTimeAccumulator)
        let savedIsPaused = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.workoutIsPaused)
        let pauseStartInterval = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.workoutPauseStartTime)
        
        // Restore state
        workoutStartTime = savedStartTime
        pausedTimeAccumulator = savedPausedAccumulator
        isTimerPaused = savedIsPaused
        
        // Recalculate elapsed time based on actual time passed
        let totalElapsed = Int(Date().timeIntervalSince(savedStartTime))
        elapsedTime = max(0, totalElapsed - savedPausedAccumulator)
        
        if savedIsPaused && pauseStartInterval > 0 {
            pauseStartTime = Date(timeIntervalSince1970: pauseStartInterval)
        }
        
        Logger.debug("Restored workout timer state: elapsed=\(elapsedTime)s, paused=\(savedIsPaused)", category: .persistence)
    }
    
    
    // MARK: - Workout State Persistence
    
    private func saveWorkoutState() {
        guard let workout = currentWorkout else {
            clearWorkoutState()
            return
        }
        
        do {
            let workoutData = try JSONEncoder().encode(workout)
            UserDefaults.standard.set(workoutData, forKey: AppConstants.UserDefaultsKeys.currentWorkout)
            UserDefaults.standard.set(currentExerciseIndex, forKey: AppConstants.UserDefaultsKeys.currentExerciseIndex)
            UserDefaults.standard.set(isFromTemplate, forKey: AppConstants.UserDefaultsKeys.isFromTemplate)
            
            Logger.debug("Saved workout state: \(workout.exercises.count) exercises, index=\(currentExerciseIndex)", category: .persistence)
        } catch {
            Logger.error("Failed to save workout state", error: error, category: .persistence)
        }
    }
    
    private func restoreWorkoutState() {
        guard currentWorkout == nil else { return }
        
        guard let workoutData = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.currentWorkout) else {
            return
        }
        
        do {
            let workout = try JSONDecoder().decode(Workout.self, from: workoutData)
            let savedIndex = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.currentExerciseIndex)
            let savedIsFromTemplate = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isFromTemplate)
            
            // Validate index
            let validIndex = min(max(0, savedIndex), workout.exercises.count - 1)
            
            currentWorkout = workout
            currentExerciseIndex = validIndex
            isFromTemplate = savedIsFromTemplate
            
            Logger.debug("Restored workout state: \(workout.exercises.count) exercises, index=\(validIndex)", category: .persistence)
        } catch {
            Logger.error("Failed to restore workout state", error: error, category: .persistence)
            clearWorkoutState()
        }
    }
    
    
    // MARK: - Weight Persistence
    
    private func saveLastWeights() {
        do {
            let data = try JSONEncoder().encode(lastWeightPerExercise)
            UserDefaults.standard.set(data, forKey: AppConstants.UserDefaultsKeys.lastWeightPerExercise)
        } catch {
            Logger.error("Failed to save last weights", error: error, category: .persistence)
        }
    }
    
    private func loadLastWeights() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.lastWeightPerExercise) else {
            return
        }
        
        do {
            lastWeightPerExercise = try JSONDecoder().decode([String: Double].self, from: data)
        } catch {
            Logger.error("Failed to load last weights", error: error, category: .persistence)
            lastWeightPerExercise = [:]
        }
    }
    
    /// Get the last weight used for an exercise
    func getLastWeight(for exerciseName: String) -> Double? {
        return lastWeightPerExercise[exerciseName]
    }
    
    /// Get weight and rep suggestion for an exercise based on history or PRs
    func getWeightSuggestion(for exercise: Exercise) -> (weight: Double, reps: Int)? {
        // First, try to get from exercise history
        if let history = ExerciseHistoryManager.shared.getLastWeightReps(for: exercise.name) {
            return (history.weight, history.reps)
        }
        
        // If no history, try to get from PRs via progressViewModel
        if let progressVM = progressViewModel {
            // Get the best PR for this exercise (highest weight × reps)
            let exercisePRs = progressVM.prs.filter { $0.exercise == exercise.name }
            if let bestPR = exercisePRs.max(by: { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }) {
                // Suggest the PR weight and reps
                return (bestPR.weight, bestPR.reps)
            }
        }
        
        // If no history or PR, return nil
        return nil
    }
    
    // MARK: - Workout Completion and Cancellation
    
    /// Cancel the current workout without saving
    func cancelWorkout() {
        pauseWorkout()
        currentWorkout = nil
        currentExerciseIndex = 0
        clearWorkoutState()
        clearWorkoutTimerState()
        clearRestTimerState()
        
        HapticManager.impact(style: .medium)
        Logger.info("Workout cancelled", category: .general)
    }
    
    /// Clear workout state (public wrapper)
    func clearWorkoutState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.currentWorkout)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.currentExerciseIndex)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.isFromTemplate)
    }
    
    /// Clear workout timer state (public wrapper)
    func clearWorkoutTimerState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutStartTime)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutElapsedTime)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutPausedTimeAccumulator)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutIsPaused)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.workoutPauseStartTime)
    }
    
    /// Clear rest timer state (public wrapper)
    func clearRestTimerState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerActive)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerTotalDuration)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
    }
    
    // MARK: - Exercise Deletion
    
    func removeExercise(at index: Int) {
        guard var workout = currentWorkout,
              index >= 0 && index < workout.exercises.count else {
            return
        }
        
        // If exercise has completed sets, we'll show confirmation in the view
        // For now, just remove it
        workout.exercises.remove(at: index)
        
        // Adjust current exercise index if needed
        if index == currentExerciseIndex {
            // If we deleted the current exercise, move to the previous one (or first if at start)
            if workout.exercises.isEmpty {
                // No exercises left, clear workout
                currentWorkout = nil
                currentExerciseIndex = 0
                pauseWorkout()
                clearWorkoutState()
                clearWorkoutTimerState()
            } else {
                // Move to previous exercise, or stay at 0 if we were at 0
                currentExerciseIndex = max(0, index - 1)
            }
        } else if index < currentExerciseIndex {
            // If we deleted an exercise before the current one, decrement the index
            currentExerciseIndex -= 1
        }
        
        // Update workout
        currentWorkout = workout
        
        // If no exercises left, finish workout
        if workout.exercises.isEmpty {
            pauseWorkout()
            clearWorkoutState()
            clearWorkoutTimerState()
        }
        
        HapticManager.selection()
        Logger.debug("Removed exercise at index \(index)", category: .general)
    }
    
    // MARK: - Exercise Reordering
    
    /// Move an exercise within the current workout's exercise list.
    /// Indices refer to the underlying `currentWorkout.exercises` order.
    func moveExercise(from sourceIndex: Int, to destinationIndex: Int) {
        guard var workout = currentWorkout else { return }
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < workout.exercises.count else {
            return
        }
        
        // Clamp destination to valid range
        let clampedDestination = max(0, min(destinationIndex, workout.exercises.count - 1))
        guard clampedDestination != sourceIndex else { return }
        
        let movedExercise = workout.exercises.remove(at: sourceIndex)
        workout.exercises.insert(movedExercise, at: clampedDestination)
        
        // Adjust currentExerciseIndex to track the same logical exercise
        if sourceIndex == currentExerciseIndex {
            currentExerciseIndex = clampedDestination
        } else if sourceIndex < currentExerciseIndex && clampedDestination >= currentExerciseIndex {
            // Item moved from before the current index to after/at it
            currentExerciseIndex -= 1
        } else if sourceIndex > currentExerciseIndex && clampedDestination <= currentExerciseIndex {
            // Item moved from after the current index to before/at it
            currentExerciseIndex += 1
        }
        
        currentWorkout = workout
        HapticManager.selection()
        Logger.debug("Reordered exercise from index \(sourceIndex) to \(clampedDestination)", category: .general)
    }
    
    private func checkForPR(exercise: String, weight: Double, reps: Int, silent: Bool = false) -> Bool {
        guard let progressVM = progressViewModel else {
            // No progress view model connected - can't determine if it's a PR
            Logger.debug("checkForPR: No progressViewModel connected for \(exercise)", category: .general)
            return false
        }
        
        // Check existing PRs BEFORE calling addOrUpdatePR to determine if it's a new PR
        // This way we know if it's a PR before adding it to the list
        let existingPRs = progressVM.prs.filter { $0.exercise == exercise }
        var isNewPR = false
        
        if existingPRs.isEmpty {
            // First PR for this exercise
            isNewPR = true
        } else {
            // Find the best existing PR
            if let best = existingPRs.max(by: { pr1, pr2 in
                if pr1.weight != pr2.weight {
                    return pr1.weight < pr2.weight
                }
                return pr1.reps < pr2.reps
            }) {
                // New PR if weight is higher, or same weight with more reps
                isNewPR = weight > best.weight || (weight == best.weight && reps > best.reps)
            }
        }
        
        // Only add to ProgressViewModel if it's actually a new PR
        if isNewPR {
            let wasAdded = progressVM.addOrUpdatePR(exercise: exercise, weight: weight, reps: reps)
            if !wasAdded {
                Logger.error("Failed to add PR to ProgressViewModel even though it's a new PR", category: .general)
                return false
            }
        }
        
        return isNewPR
    }
    
    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
        // Remove all notification observers
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
}

// MARK: - Exercise Section Type
enum ExerciseSectionType {
    case warmup
    case stretch
    case workingSets
    case cardio
    
    var displayName: String {
        switch self {
        case .warmup:
            return "Warmup"
        case .stretch:
            return "Stretch"
        case .workingSets:
            return "Exercises"
        case .cardio:
            return "Cardio"
        }
    }
    
    var icon: String {
        switch self {
        case .warmup:
            return "flame.fill"
        case .stretch:
            return "figure.flexibility"
        case .workingSets:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        }
    }
}
