import Foundation
import SwiftUI
import Combine

class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var currentExerciseIndex: Int = 0
    @Published var elapsedTime: Int = 0
    @Published var restTimerActive: Bool = false
    @Published var restTimeRemaining: Int = 60
    @Published var showPRBadge: Bool = false
    @Published var prMessage: String = ""
    @Published var showAddExerciseSheet: Bool = false
    @Published var showSettingsSheet: Bool = false
    
    var settingsManager: SettingsManager?
    var progressViewModel: ProgressViewModel?
    var programViewModel: WorkoutProgramViewModel?
    var templatesViewModel: TemplatesViewModel?
    var themeManager: ThemeManager?
    
    private var timer: Timer?
    private var restTimer: Timer?
    private var workoutStartTime: Date?
    
    var currentExercise: Exercise? {
        guard let workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else {
            return nil
        }
        return workout.exercises[currentExerciseIndex]
    }
    
    init(settingsManager: SettingsManager? = nil) {
        self.settingsManager = settingsManager ?? SettingsManager()
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
                videoURL: videoURL
            )
        }
        currentWorkout = Workout(name: template.name, exercises: exercises)
        currentExerciseIndex = 0
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        
        // Save completed workout
        if let workout = currentWorkout {
            WorkoutHistoryManager.shared.addCompletedWorkout(workout)
        }
        
        // Add workout date to progress tracking
        if let progressVM = progressViewModel {
            progressVM.addWorkoutDate()
        }
        
        // Advance program day if workout was from a program
        if let programVM = programViewModel,
           let workout = currentWorkout,
           let activeProgram = programVM.activeProgram,
           let program = programVM.programs.first(where: { $0.id == activeProgram.programId }),
           workout.name.contains(program.name) {
            programVM.advanceToNextDay(for: program)
        }
        
        currentWorkout = nil
        currentExerciseIndex = 0
        elapsedTime = 0
    }
    
    func completeSet(weight: Double, reps: Int) {
        guard var exercise = currentExercise,
              var workout = currentWorkout else { return }
        
        let set = ExerciseSet(
            setNumber: exercise.currentSet,
            weight: weight,
            reps: reps
        )
        
        exercise.sets.append(set)
        exercise.currentSet += 1
        
        // Update exercise in workout
        workout.exercises[currentExerciseIndex] = exercise
        currentWorkout = workout
        
        // Add initial entry for new exercise or check for PR
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
        
        // Start rest timer
        startRestTimer()
    }
    
    func completeHoldSet(duration: Int) {
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
        currentWorkout = workout
        
        // Start rest timer
        startRestTimer()
    }
    
    func addExercise(name: String, targetSets: Int, type: ExerciseType, holdDuration: Int?) {
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
        guard var workout = currentWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        // Get alternatives for the alternative exercise (recursive)
        let alternatives = ExerciseDataManager.shared.getAlternatives(for: alternativeName)
        let videoURL = ExerciseDataManager.shared.getVideoURL(for: alternativeName)
        
        // Replace current exercise with alternative
        var alternativeExercise = Exercise(
            name: alternativeName,
            targetSets: workout.exercises[currentExerciseIndex].targetSets,
            exerciseType: workout.exercises[currentExerciseIndex].exerciseType,
            holdDuration: workout.exercises[currentExerciseIndex].targetHoldDuration,
            alternatives: alternatives,
            videoURL: videoURL
        )
        
        // Preserve sets if any
        alternativeExercise.sets = workout.exercises[currentExerciseIndex].sets
        alternativeExercise.currentSet = workout.exercises[currentExerciseIndex].currentSet
        
        workout.exercises[currentExerciseIndex] = alternativeExercise
        currentWorkout = workout
    }
    
    private func startRestTimer() {
        guard let settingsManager = settingsManager else { return }
        
        restTimerActive = true
        restTimeRemaining = settingsManager.restTimerDuration
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
            } else {
                self.completeRest()
            }
        }
    }
    
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
    }
    
    func completeRest() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimeRemaining = 0
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
    
    private func checkForPR(exercise: String, weight: Double, reps: Int) {
        guard let progressVM = progressViewModel else {
            // No progress view model connected, just show badge
            showPRBadge = true
            prMessage = "New PR: \(Int(weight)) lbs × \(reps) reps"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
            
            // Hide PR badge after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showPRBadge = false
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        restTimer?.invalidate()
    }
}
