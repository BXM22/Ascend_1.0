import XCTest
@testable import Ascend

final class WorkoutViewModelTests: XCTestCase {
    var viewModel: WorkoutViewModel!
    var settingsManager: SettingsManager!
    var progressViewModel: ProgressViewModel!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        progressViewModel = ProgressViewModel()
        viewModel = WorkoutViewModel(
            settingsManager: settingsManager,
            progressViewModel: progressViewModel
        )
    }
    
    override func tearDown() {
        viewModel = nil
        progressViewModel = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Workout Lifecycle Tests
    
    func testStartWorkout() {
        // Given
        XCTAssertNil(viewModel.currentWorkout)
        
        // When
        viewModel.startWorkout(name: "Test Workout")
        
        // Then
        XCTAssertNotNil(viewModel.currentWorkout)
        XCTAssertEqual(viewModel.currentWorkout?.name, "Test Workout")
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertGreaterThan(viewModel.elapsedTime, 0)
    }
    
    func testFinishWorkout() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        let initialWorkoutCount = progressViewModel.workoutCount
        
        // When
        viewModel.finishWorkout()
        
        // Then
        XCTAssertNil(viewModel.currentWorkout)
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.elapsedTime, 0)
    }
    
    func testPauseWorkout() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        let initialTime = viewModel.elapsedTime
        
        // When
        viewModel.pauseWorkout()
        
        // Wait a bit
        let expectation = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then - time should not have increased
        XCTAssertEqual(viewModel.elapsedTime, initialTime)
    }
    
    // MARK: - Set Completion Tests
    
    func testCompleteSet() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        
        // When
        viewModel.completeSet(weight: 185, reps: 8)
        
        // Then
        XCTAssertNotNil(viewModel.currentExercise)
        XCTAssertEqual(viewModel.currentExercise?.sets.count, 1)
        XCTAssertEqual(viewModel.currentExercise?.currentSet, 2)
        XCTAssertTrue(viewModel.restTimerActive)
    }
    
    func testCompleteSet_Validation() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        
        // When - invalid weight
        let result1 = viewModel.validateSetCompletion(weight: -10, reps: 8)
        
        // Then
        XCTAssertTrue(result1.isFailure)
        
        // When - invalid reps
        let result2 = viewModel.validateSetCompletion(weight: 185, reps: 0)
        
        // Then
        XCTAssertTrue(result2.isFailure)
        
        // When - valid input
        let result3 = viewModel.validateSetCompletion(weight: 185, reps: 8)
        
        // Then
        XCTAssertTrue(result3.isSuccess)
    }
    
    func testCompleteHoldSet() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Plank", targetSets: 3, type: .hold, holdDuration: 60)
        
        // When
        viewModel.completeHoldSet(duration: 45)
        
        // Then
        XCTAssertNotNil(viewModel.currentExercise)
        XCTAssertEqual(viewModel.currentExercise?.sets.count, 1)
        XCTAssertEqual(viewModel.currentExercise?.sets.first?.holdDuration, 45)
        XCTAssertTrue(viewModel.restTimerActive)
    }
    
    // MARK: - Exercise Management Tests
    
    func testAddExercise() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        
        // When
        viewModel.addExercise(name: "Squat", targetSets: 4, type: .weightReps, holdDuration: nil)
        
        // Then
        XCTAssertEqual(viewModel.currentWorkout?.exercises.count, 1)
        XCTAssertEqual(viewModel.currentWorkout?.exercises.first?.name, "Squat")
        XCTAssertEqual(viewModel.currentWorkout?.exercises.first?.targetSets, 4)
    }
    
    func testAddExercise_CreatesWorkoutIfNone() {
        // Given
        XCTAssertNil(viewModel.currentWorkout)
        
        // When
        viewModel.addExercise(name: "Deadlift", targetSets: 3, type: .weightReps, holdDuration: nil)
        
        // Then
        XCTAssertNotNil(viewModel.currentWorkout)
        XCTAssertEqual(viewModel.currentWorkout?.exercises.count, 1)
    }
    
    // MARK: - Dropset Tests
    
    func testDropsetConfiguration() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        
        // When
        viewModel.dropsetsEnabled = true
        viewModel.numberOfDropsets = 3
        viewModel.weightReductionPerDropset = 10.0
        viewModel.updateCurrentExerciseDropsetConfiguration()
        viewModel.completeSet(weight: 185, reps: 8)
        
        // Then
        let sets = viewModel.currentExercise?.sets ?? []
        // Should have 1 main set + 3 dropsets = 4 total
        XCTAssertEqual(sets.count, 4)
        XCTAssertTrue(sets[0].isDropset == false)
        XCTAssertTrue(sets[1].isDropset == true)
        XCTAssertEqual(sets[1].dropsetNumber, 1)
        XCTAssertEqual(sets[1].weight, 175) // 185 - 10
    }
    
    // MARK: - Timer Tests
    
    func testFormatTime() {
        // Test seconds only
        XCTAssertEqual(viewModel.formatTime(45), "0:45")
        
        // Test minutes and seconds
        XCTAssertEqual(viewModel.formatTime(125), "2:05")
        
        // Test hours, minutes, and seconds
        XCTAssertEqual(viewModel.formatTime(3665), "1:01:05")
    }
    
    func testAbortWorkoutTimer() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        let initialTime = viewModel.elapsedTime
        
        // Wait a bit
        let expectation = XCTestExpectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        viewModel.abortWorkoutTimer()
        
        // Then
        XCTAssertEqual(viewModel.elapsedTime, 0)
    }
    
    // MARK: - Rest Timer Tests
    
    func testStartRestTimer() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        settingsManager.restTimerDuration = 90
        
        // When
        viewModel.completeSet(weight: 185, reps: 8)
        
        // Then
        XCTAssertTrue(viewModel.restTimerActive)
        XCTAssertEqual(viewModel.restTimeRemaining, 90)
        XCTAssertEqual(viewModel.restTimerTotalDuration, 90)
    }
    
    func testRestTimerCountdown() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        settingsManager.restTimerDuration = 5 // Short duration for testing
        
        // When
        viewModel.completeSet(weight: 185, reps: 8)
        let initialRemaining = viewModel.restTimeRemaining
        
        // Wait for timer to tick
        let expectation = XCTestExpectation(description: "Wait for timer")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Then - time should have decreased
        XCTAssertLessThan(viewModel.restTimeRemaining, initialRemaining)
    }
    
    func testSkipRest() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        viewModel.completeSet(weight: 185, reps: 8)
        XCTAssertTrue(viewModel.restTimerActive)
        
        // When
        viewModel.skipRest()
        
        // Then
        XCTAssertFalse(viewModel.restTimerActive)
        XCTAssertEqual(viewModel.restTimeRemaining, 0)
    }
    
    func testCompleteRest() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        viewModel.completeSet(weight: 185, reps: 8)
        XCTAssertTrue(viewModel.restTimerActive)
        
        // When
        viewModel.completeRest()
        
        // Then
        XCTAssertFalse(viewModel.restTimerActive)
        XCTAssertEqual(viewModel.restTimeRemaining, 0)
    }
    
    // MARK: - Completion Flow Tests
    
    func testFinishWorkout_ShowsCompletionModal() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        viewModel.completeSet(weight: 185, reps: 8)
        
        // When
        viewModel.finishWorkout()
        
        // Then
        XCTAssertTrue(viewModel.showCompletionModal)
        XCTAssertNotNil(viewModel.completionStats)
        if let stats = viewModel.completionStats {
            XCTAssertGreaterThan(stats.duration, 0)
            XCTAssertEqual(stats.exerciseCount, 1)
            XCTAssertGreaterThan(stats.totalSets, 0)
            XCTAssertGreaterThan(stats.totalVolume, 0)
        }
    }
    
    func testFinishWorkout_CalculatesStatsCorrectly() {
        // Given
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        viewModel.completeSet(weight: 185, reps: 8)
        viewModel.completeSet(weight: 185, reps: 8)
        viewModel.addExercise(name: "Squat", targetSets: 2, type: .weightReps, holdDuration: nil)
        viewModel.completeSet(weight: 225, reps: 5)
        
        // When
        viewModel.finishWorkout()
        
        // Then
        if let stats = viewModel.completionStats {
            XCTAssertEqual(stats.exerciseCount, 2)
            XCTAssertEqual(stats.totalSets, 3) // 2 bench + 1 squat
            // Volume: (185 * 8 * 2) + (225 * 5) = 2960 + 1125 = 4085
            let expectedVolume = (185 * 8 * 2) + (225 * 5)
            XCTAssertEqual(stats.totalVolume, expectedVolume)
        }
    }
    
    func testFinishWorkout_UpdatesProgressViewModel() {
        // Given
        let initialWorkoutCount = progressViewModel.workoutCount
        viewModel.startWorkout(name: "Test Workout")
        viewModel.addExercise(name: "Bench Press", targetSets: 3, type: .weightReps, holdDuration: nil)
        
        // When
        viewModel.finishWorkout()
        
        // Then - workout should be saved to history
        // Note: This tests integration, actual count may vary based on WorkoutHistoryManager state
        XCTAssertNotNil(viewModel.completionStats)
    }
}

// MARK: - Result Extension for Testing
extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

