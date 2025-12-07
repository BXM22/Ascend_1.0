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
    
    var currentExercise: Exercise? {
        guard let workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else {
            return nil
        }
        return workout.exercises[currentExerciseIndex]
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
        self.backgroundTime = nil
        
        // Update workout timer - recalculate from start time
        if let startTime = workoutStartTime {
            elapsedTime = Int(Date().timeIntervalSince(startTime))
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
            let exerciseType: ExerciseType
            let holdDuration: Int?
            
            if templateExercise.exerciseType != .weightReps {
                exerciseType = templateExercise.exerciseType
                holdDuration = templateExercise.targetHoldDuration
            } else {
                let determined = determineExerciseType(for: templateExercise.name)
                exerciseType = determined.0
                holdDuration = determined.1
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
        syncDropsetStateFromCurrentExercise()
        startTimer()
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
        startTimer()
    }
    
    func startTimer() {
        workoutStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timer.workoutTimerInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            self.elapsedTime = Int(Date().timeIntervalSince(startTime))
        }
    }
    
    func pauseWorkout() {
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
    }
    
    func finishWorkout() {
        pauseWorkout()
        
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
        
        // Store stats and show modal BEFORE clearing workout state
        // This ensures modal appears with accurate data and view is still visible
        completionStats = stats
        showCompletionModal = true
        
        Logger.debug("Showing completion modal - stats: \(stats.exerciseCount) exercises, \(stats.totalSets) sets, \(stats.totalVolume) lbs", category: .general)
        
        // Celebration haptic feedback
        HapticManager.success()
        
        // Don't clear workout state yet - wait until modal is dismissed
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
        
        // Update dropset configuration from state before completing set
        exercise.hasDropsets = dropsetsEnabled
        exercise.numberOfDropsets = dropsetsEnabled ? numberOfDropsets : 0
        exercise.weightReductionPerDropset = max(AppConstants.Dropset.minWeightReduction, weightReductionPerDropset)
        
        // Create main set
        let mainSetNumber = exercise.currentSet
        let mainSet = ExerciseSet(
            setNumber: mainSetNumber,
            weight: weight,
            reps: reps,
            isDropset: false
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
                    dropsetNumber: dropsetNumber
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
        
        // Add initial entry for new exercise or check for PR (only check main set, not dropsets)
        if let progressVM = progressViewModel {
            if !progressVM.availableExercises.contains(exercise.name) {
                // First time this exercise is being tracked
                progressVM.addInitialExerciseEntry(exercise: exercise.name, weight: weight, reps: reps)
            } else {
                // Check for PR
                checkForPR(exercise: exercise.name, weight: weight, reps: reps)
            }
        } else {
            // No progress view model, just check for PR (shows badge only)
            checkForPR(exercise: exercise.name, weight: weight, reps: reps)
        }
        
        // Check if all sets are completed before starting rest timer
        // If all sets are done, advance to next exercise instead of starting rest
        if exercise.currentSet > exercise.targetSets {
            // All sets completed, advance to next exercise immediately
            advanceToNextExercise()
        } else {
            // Start rest timer
            startRestTimer()
        }
    }
    
    func completeHoldSet(duration: Int) {
        // Validate input
        switch validateHoldSetCompletion(duration: duration) {
        case .failure(let error):
            // Log error - in a production app, you might want to show an alert
            Logger.error("Hold set completion validation failed", error: error, category: .validation)
            return
        case .success:
            break
        }
        
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        let set = ExerciseSet(
            setNumber: exercise.currentSet,
            weight: 0,
            reps: 0,
            holdDuration: duration
        )
        
        exercise.sets.append(set)
        exercise.currentSet += 1
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        
        // Force SwiftUI to detect the change
        objectWillChange.send()
        currentWorkout = workout
        
        // Start rest timer
        startRestTimer()
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
        
        guard var workout = currentWorkout else {
            // Create new workout if none exists
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: name)
            let exercise = Exercise(
                name: name,
                targetSets: targetSets,
                exerciseType: type,
                holdDuration: holdDuration,
                alternatives: alternatives,
                videoURL: videoURL
            )
            currentWorkout = Workout(name: "Workout", exercises: [exercise])
            currentExerciseIndex = 0
            startTimer()
            return
        }
        
        let alternatives = ExerciseDataManager.shared.getAlternatives(for: name)
        let videoURL = ExerciseDataManager.shared.getVideoURL(for: name)
        let exercise = Exercise(
            name: name,
            targetSets: targetSets,
            exerciseType: type,
            holdDuration: holdDuration,
            alternatives: alternatives,
            videoURL: videoURL
        )
        workout.exercises.append(exercise)
        currentWorkout = workout
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
        restTimerOriginalDuration = settingsManager.restTimerDuration
        restTimerTotalDuration = restTimerOriginalDuration
        restTimeRemaining = restTimerOriginalDuration
        restTimerStartTime = Date()
        
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
    }
    
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
        restTimerStartTime = nil
        restTimerOriginalDuration = 0
        restTimerTotalDuration = AppConstants.Timer.defaultRestDuration
        
        // Cancel notification since timer was skipped
        NotificationManager.shared.cancelRestTimerNotification()
        
        // Clear saved state
        clearRestTimerState()
        
        // Check if exercise is complete and advance if needed
        checkAndAdvanceExercise()
    }
    
    func completeRest() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
        restTimerStartTime = nil
        restTimerOriginalDuration = 0
        restTimerTotalDuration = AppConstants.Timer.defaultRestDuration
        
        // Cancel notification since timer completed
        NotificationManager.shared.cancelRestTimerNotification()
        
        // Clear saved state
        clearRestTimerState()
        
        // Check if exercise is complete and advance if needed
        checkAndAdvanceExercise()
    }
    
    private func checkAndAdvanceExercise() {
        guard let exercise = currentExercise,
              currentWorkout != nil else { return }
        
        // Check if all sets are completed
        if exercise.currentSet > exercise.targetSets {
            // All sets completed, move to next exercise
            advanceToNextExercise()
        }
    }
    
    private func advanceToNextExercise() {
        guard let workout = currentWorkout else { return }
        
        // Check if there's a next exercise
        if currentExerciseIndex < workout.exercises.count - 1 {
            // Move to next exercise with animation
            withAnimation(AppAnimations.smooth) {
                currentExerciseIndex += 1
            }
            syncDropsetStateFromCurrentExercise()
            HapticManager.selection()
        } else {
            // Last exercise completed - automatically finish the workout
            // This shows the completion modal and saves stats to dashboard
            HapticManager.success()
            finishWorkout()
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
        guard UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.restTimerActive) else {
            return
        }
        
        let remaining = UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerRemaining)
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
            return
        }
        
        // Restore state - preserve original total duration for accurate progress calculation
        restTimerActive = true
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
    
    private func checkForPR(exercise: String, weight: Double, reps: Int) {
        guard let progressVM = progressViewModel else {
            // No progress view model connected, just show badge
            showPRBadge = true
            prMessage = "New PR: \(Int(weight)) lbs × \(reps) reps"
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.PRBadge.displayDuration) {
                self.showPRBadge = false
            }
            return
        }
        
        // Add or update PR in ProgressViewModel
        let isNewPR = progressVM.addOrUpdatePR(exercise: exercise, weight: weight, reps: reps)
        
        if isNewPR {
            // Show PR badge
            showPRBadge = true
            prMessage = "New PR: \(Int(weight)) lbs × \(reps) reps"
            
            // Hide PR badge after configured duration
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.PRBadge.displayDuration) {
                self.showPRBadge = false
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
        // Remove all notification observers
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
}
