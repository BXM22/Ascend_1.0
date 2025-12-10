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
            return total + Int(set.weight * Double(set.reps))
        }
    }
    
    /// Calculate total workout volume (sum across all exercises)
    var totalWorkoutVolume: Int {
        guard let workout = currentWorkout else { return 0 }
        return workout.exercises.reduce(0) { exerciseTotal, exercise in
            let exerciseVolume = exercise.sets.reduce(0) { setTotal, set in
                return setTotal + Int(set.weight * Double(set.reps))
            }
            return exerciseTotal + exerciseVolume
        }
    }
    
    /// Format volume with comma separator
    func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
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
        setupAppLifecycleObservers()
        restoreRestTimerState()
        
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
        
        // Pause timers when going to background to save battery
        // We'll recalculate time when foregrounding
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
        
        // Save rest timer state for app termination scenarios
        // This ensures we can restore accurately even if app is killed
        saveRestTimerState()
        
        Logger.debug("App backgrounded - saved rest timer state", category: .persistence)
    }
    
    private func handleAppForegrounded() {
        guard backgroundTime != nil else { return }
        let backgroundDuration = Date().timeIntervalSince(backgroundTime!)
        self.backgroundTime = nil
        
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
        
        // Update rest timer - calculate based on time elapsed since timer started
        if restTimerActive, let restStart = restTimerStartTime {
            // Calculate total elapsed time since timer started
            let totalElapsed = Int(Date().timeIntervalSince(restStart))
            // Use the original total duration for accurate calculation
            // Prefer restTimerTotalDuration as it's the published value used by UI
            let originalTotal = restTimerTotalDuration > 0 ? restTimerTotalDuration : restTimerOriginalDuration
            
            guard originalTotal > 0 else {
                Logger.error("Invalid original total duration: \(originalTotal)", category: .persistence)
                completeRest()
                return
            }
            
            let newRemaining = max(0, originalTotal - totalElapsed)
            
            if newRemaining <= 0 {
                // Timer completed while in background
                Logger.info("Rest timer completed while app was in background", category: .persistence)
                completeRest()
            } else {
                // Restart timer with remaining time - reset start time to now
                // The timer will continue counting down from the updated restTimeRemaining
                restTimeRemaining = newRemaining
                restTimerStartTime = Date()
                
                // Preserve original total duration for accurate progress calculation
                // Ensure restTimerTotalDuration is set correctly
                if restTimerTotalDuration == 0 || restTimerTotalDuration != originalTotal {
                    restTimerTotalDuration = originalTotal
                }
                restTimerOriginalDuration = originalTotal
                
                // Restart the timer
                restartRestTimer()
                
                // Reschedule notification with remaining time
                NotificationManager.shared.scheduleRestTimerNotification(duration: newRemaining)
                
                // Save updated state
                saveRestTimerState()
                
                Logger.debug("Restored rest timer after foreground: \(newRemaining)s remaining of \(originalTotal)s total", category: .persistence)
            }
        } else if restTimerActive {
            // Timer was active but we lost the start time - try to restore from UserDefaults
            Logger.debug("Rest timer active but start time missing - attempting restore", category: .persistence)
            restoreRestTimerState()
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
        startTimer()
    }
    
    func startTimer() {
        workoutStartTime = Date()
        pausedTimeAccumulator = 0
        isTimerPaused = false
        pauseStartTime = nil
        elapsedTime = 0
        
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
                return setTotal + Int(set.weight * Double(set.reps))
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
        
        // Add workout date to progress tracking and calculate streak IMMEDIATELY
        if let progressVM = progressViewModel {
            progressVM.addWorkoutDate()
            // Force immediate streak calculation (addWorkoutDate already calls calculateStreaks, but ensure it's synchronous)
            progressVM.calculateStreaks()
            // Invalidate volume cache since new workout was added
            progressVM.invalidateVolumeCache()
            // Force immediate volume and count update
            progressVM.updateVolumeAndCount()
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
        
        // Don't clear workout state yet if showing modal - wait until modal is dismissed
        // This ensures the modal overlay remains visible
    }
    
    func completeSet(weight: Double, reps: Int) {
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
        let wasPR = false // Will be set correctly after we check
        
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
            isWarmup: false
        )
        
        exercise.sets.append(mainSet)
        
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
            Logger.debug("Exercise '\(exercise.name)' - First time: \(isFirstTime), availableExercises count: \(progressVM.availableExercises.count)", category: .general)
            
            if isFirstTime {
                // First time this exercise is being tracked - don't show PR badge
                progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: weight, reps: reps)
                Logger.debug("First time exercise - no PR badge", category: .general)
            } else {
                // Check for PR
                Logger.debug("Checking for PR: \(exercise.name) - \(Int(weight)) lbs × \(reps) reps", category: .general)
                Logger.debug("BEFORE checkForPR - prMessage: '\(prMessage)'", category: .general)
                isNewPR = checkForPR(exercise: exercise.name, weight: weight, reps: reps)
                Logger.debug("AFTER checkForPR - isNewPR: \(isNewPR), prMessage: '\(prMessage)'", category: .general)
                
                if isNewPR {
                    // Set PR message immediately - badge will show when rest timer appears
                    prMessage = "New PR: \(Int(weight)) lbs × \(reps) reps"
                    Logger.info("✅ PR MESSAGE SET: '\(prMessage)'", category: .general)
                    Logger.info("✅ prMessage is now: '\(prMessage)'", category: .general)
                    Logger.info("✅ About to start rest timer - prMessage will be: '\(prMessage)'", category: .general)
                } else {
                    Logger.debug("❌ Not a PR for \(exercise.name): \(Int(weight)) lbs × \(reps) reps", category: .general)
                    // Make sure message is cleared if not a PR
                    if !prMessage.isEmpty {
                        Logger.debug("Clearing old PR message", category: .general)
                        prMessage = ""
                    }
                }
            }
        } else {
            Logger.debug("❌ No progressViewModel - cannot check for PR", category: .general)
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
        restTimerActive = true
        
        Logger.debug("startRestTimer called - prMessage: '\(prMessage)', isEmpty: \(prMessage.isEmpty), showPRBadge: \(showPRBadge)", category: .general)
        
        // Show PR badge when rest timer appears if there's a PR message
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
        restTimerStartTime = Date()
        startRestTimerTick()
    }
    
    private func startRestTimerTick() {
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.restTimerInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Ensure time remaining is never negative
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
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
        
        // Check if exercise is complete and advance if needed
        checkAndAdvanceExercise()
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
            HapticManager.selection()
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
        
        if let startTime = restTimerStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
        }
        
        Logger.debug("Saved rest timer state: \(restTimeRemaining)s remaining of \(restTimerTotalDuration)s total", category: .persistence)
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
        
        guard startTimeInterval > 0, totalDuration > 0 else {
            clearRestTimerState()
            return
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let elapsed = Int(Date().timeIntervalSince(startTime))
        // Use the original total duration for accurate calculation
        let newRemaining = max(0, totalDuration - elapsed)
        
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
        restTimerStartTime = Date() // Reset to now for accurate counting
        
        // Restart the timer
        restartRestTimer()
        
        // Reschedule notification with remaining time
        NotificationManager.shared.scheduleRestTimerNotification(duration: newRemaining)
        
        Logger.debug("Restored rest timer state: \(newRemaining)s remaining of \(totalDuration)s total", category: .persistence)
    }
    
    private func clearRestTimerState() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerActive)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerTotalDuration)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerStartTime)
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
            Logger.debug("checkForPR: \(exercise) - First PR for this exercise", category: .general)
        } else {
            // Find the best existing PR
            if let best = existingPRs.max(by: { pr1, pr2 in
                if pr1.weight != pr2.weight {
                    return pr1.weight < pr2.weight
                }
                return pr1.reps < pr2.reps
            }) {
                Logger.debug("checkForPR: \(exercise) - Best existing PR: \(Int(best.weight)) lbs × \(best.reps) reps", category: .general)
                Logger.debug("checkForPR: \(exercise) - New attempt: \(Int(weight)) lbs × \(reps) reps", category: .general)
                
                // New PR if weight is higher, or same weight with more reps
                isNewPR = weight > best.weight || (weight == best.weight && reps > best.reps)
                
                if isNewPR {
                    Logger.info("✅ NEW PR DETECTED: \(Int(weight)) lbs × \(reps) reps beats \(Int(best.weight)) lbs × \(best.reps) reps", category: .general)
                } else {
                    Logger.debug("❌ Not a new PR: \(Int(weight)) lbs × \(reps) reps does not beat \(Int(best.weight)) lbs × \(best.reps) reps", category: .general)
                }
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
