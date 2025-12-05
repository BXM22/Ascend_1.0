import XCTest
@testable import Ascend

final class ProgressViewModelTests: XCTestCase {
    var viewModel: ProgressViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ProgressViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - PR Management Tests
    
    func testAddInitialExerciseEntry() {
        // Given
        XCTAssertTrue(viewModel.availableExercises.isEmpty)
        
        // When
        viewModel.addInitialExerciseEntry(exercise: "Bench Press", weight: 185, reps: 8)
        
        // Then
        XCTAssertTrue(viewModel.availableExercises.contains("Bench Press"))
        XCTAssertEqual(viewModel.prs.count, 1)
        XCTAssertEqual(viewModel.prs.first?.exercise, "Bench Press")
        XCTAssertEqual(viewModel.prs.first?.weight, 185)
        XCTAssertEqual(viewModel.prs.first?.reps, 8)
    }
    
    func testAddInitialExerciseEntry_DuplicateExercise() {
        // Given
        viewModel.addInitialExerciseEntry(exercise: "Bench Press", weight: 185, reps: 8)
        let initialCount = viewModel.prs.count
        
        // When
        viewModel.addInitialExerciseEntry(exercise: "Bench Press", weight: 200, reps: 5)
        
        // Then - Should not add duplicate
        XCTAssertEqual(viewModel.prs.count, initialCount)
    }
    
    func testAddOrUpdatePR_NewExercise() {
        // Given
        XCTAssertTrue(viewModel.availableExercises.isEmpty)
        
        // When
        let isNewPR = viewModel.addOrUpdatePR(exercise: "Squat", weight: 225, reps: 5)
        
        // Then
        XCTAssertTrue(isNewPR)
        XCTAssertTrue(viewModel.availableExercises.contains("Squat"))
        XCTAssertEqual(viewModel.prs.count, 1)
    }
    
    func testAddOrUpdatePR_BeatsExistingPR() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        let initialCount = viewModel.prs.count
        
        // When - Higher weight
        let isNewPR = viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 200, reps: 8)
        
        // Then
        XCTAssertTrue(isNewPR)
        XCTAssertGreaterThan(viewModel.prs.count, initialCount)
        let maxWeight = viewModel.prs.filter { $0.exercise == "Bench Press" }
            .map { $0.weight }.max() ?? 0
        XCTAssertEqual(maxWeight, 200)
    }
    
    func testAddOrUpdatePR_SameWeightMoreReps() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        let initialCount = viewModel.prs.count
        
        // When - Same weight, more reps
        let isNewPR = viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 10)
        
        // Then
        XCTAssertTrue(isNewPR)
        XCTAssertGreaterThan(viewModel.prs.count, initialCount)
    }
    
    func testAddOrUpdatePR_LowerValue() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 200, reps: 8)
        let initialCount = viewModel.prs.count
        
        // When - Lower weight
        let isNewPR = viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        
        // Then
        XCTAssertFalse(isNewPR)
        XCTAssertEqual(viewModel.prs.count, initialCount)
    }
    
    func testAddOrUpdatePR_SameWeightFewerReps() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 10)
        let initialCount = viewModel.prs.count
        
        // When - Same weight, fewer reps
        let isNewPR = viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        
        // Then
        XCTAssertFalse(isNewPR)
        XCTAssertEqual(viewModel.prs.count, initialCount)
    }
    
    // MARK: - Exercise Selection Tests
    
    func testSelectedExercisePRs() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 200, reps: 5)
        viewModel.addOrUpdatePR(exercise: "Squat", weight: 225, reps: 5)
        viewModel.selectedExercise = "Bench Press"
        
        // When/Then
        let benchPRs = viewModel.selectedExercisePRs
        XCTAssertEqual(benchPRs.count, 1)
        XCTAssertEqual(benchPRs.first?.exercise, "Bench Press")
        
        // When
        viewModel.selectedExercise = "Squat"
        
        // Then
        let squatPRs = viewModel.selectedExercisePRs
        XCTAssertEqual(squatPRs.count, 1)
        XCTAssertEqual(squatPRs.first?.exercise, "Squat")
    }
    
    func testCurrentPR() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 200, reps: 5)
        viewModel.selectedExercise = "Bench Press"
        
        // When/Then
        XCTAssertNotNil(viewModel.currentPR)
        XCTAssertEqual(viewModel.currentPR?.weight, 200) // Should be the newest/highest
    }
    
    func testAvailableExercises() {
        // Given
        viewModel.addOrUpdatePR(exercise: "Bench Press", weight: 185, reps: 8)
        viewModel.addOrUpdatePR(exercise: "Squat", weight: 225, reps: 5)
        viewModel.addOrUpdatePR(exercise: "Deadlift", weight: 315, reps: 1)
        
        // When/Then
        let exercises = viewModel.availableExercises
        XCTAssertEqual(exercises.count, 3)
        XCTAssertTrue(exercises.contains("Bench Press"))
        XCTAssertTrue(exercises.contains("Squat"))
        XCTAssertTrue(exercises.contains("Deadlift"))
    }
    
    // MARK: - Streak Calculation Tests
    
    func testCalculateStreaks_NoWorkouts() {
        // Given
        viewModel.workoutDates = []
        
        // When
        viewModel.calculateStreaks()
        
        // Then
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.longestStreak, 0)
    }
    
    func testCalculateStreaks_CurrentStreak() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        viewModel.workoutDates = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today) ?? today,
            calendar.date(byAdding: .day, value: -2, to: today) ?? today
        ]
        
        // When
        viewModel.calculateStreaks()
        
        // Then
        XCTAssertGreaterThanOrEqual(viewModel.currentStreak, 1)
    }
    
    func testCalculateStreaks_BrokenStreak() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        viewModel.workoutDates = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today) ?? today,
            calendar.date(byAdding: .day, value: -3, to: today) ?? today, // Gap breaks streak
            calendar.date(byAdding: .day, value: -4, to: today) ?? today
        ]
        
        // When
        viewModel.calculateStreaks()
        
        // Then - Current streak should be 2 (today and yesterday)
        XCTAssertEqual(viewModel.currentStreak, 2)
    }
    
    func testAddWorkoutDate() {
        // Given
        let initialCount = viewModel.workoutDates.count
        let newDate = Date()
        
        // When
        viewModel.addWorkoutDate(newDate)
        
        // Then
        XCTAssertEqual(viewModel.workoutDates.count, initialCount + 1)
        XCTAssertTrue(viewModel.workoutDates.contains { Calendar.current.isDate($0, inSameDayAs: newDate) })
    }
    
    func testAddWorkoutDate_DuplicateDate() {
        // Given
        let date = Date()
        viewModel.addWorkoutDate(date)
        let initialCount = viewModel.workoutDates.count
        
        // When - Add same date again
        viewModel.addWorkoutDate(date)
        
        // Then - Should not add duplicate
        XCTAssertEqual(viewModel.workoutDates.count, initialCount)
    }
    
    // MARK: - View Type Tests
    
    func testSelectedView() {
        // Given
        XCTAssertEqual(viewModel.selectedView, .week)
        
        // When
        viewModel.selectedView = .month
        
        // Then
        XCTAssertEqual(viewModel.selectedView, .month)
    }
}






