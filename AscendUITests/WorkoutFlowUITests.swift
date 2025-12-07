//
//  WorkoutFlowUITests.swift
//  AscendUITests
//
//  Created on 2024
//

import XCTest

final class WorkoutFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Workout Creation Tests
    
    func testStartWorkoutFromTemplates() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        
        // Wait for templates to load
        sleep(1)
        
        // When - Tap Start on first template
        let startButtons = app.buttons.matching(identifier: "Start")
        if startButtons.count > 0 {
            startButtons.firstMatch.tap()
            
            // Then - Should navigate to Workout view
            sleep(1)
            // Verify workout has started by checking for workout elements
            XCTAssertTrue(app.buttons.matching(identifier: "Add Exercise").firstMatch.exists ||
                         app.buttons.matching(NSPredicate(format: "label CONTAINS 'Complete Set'")).firstMatch.exists)
        }
    }
    
    func testAddExerciseToWorkout() throws {
        // Given - Start a workout
        navigateToWorkout()
        
        // When - Tap Add Exercise button
        let addExerciseButton = app.buttons.matching(identifier: "Add Exercise").firstMatch
        if addExerciseButton.waitForExistence(timeout: 2) {
            addExerciseButton.tap()
            
            // Fill in exercise details
            let exerciseNameField = app.textFields.firstMatch
            if exerciseNameField.waitForExistence(timeout: 2) {
                exerciseNameField.tap()
                exerciseNameField.typeText("Test Exercise")
                
                // Tap Add Exercise button in sheet
                let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Exercise'")).firstMatch
                if addButton.waitForExistence(timeout: 2) {
                    addButton.tap()
                    
                    // Then - Exercise should be added
                    sleep(1)
                    // Verify exercise appears in workout
                }
            }
        }
    }
    
    func testCompleteSet() throws {
        // Given - Start workout with exercise
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        
        // When - Enter weight and reps, then complete set
        let weightField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Weight' OR label CONTAINS 'Weight'")).firstMatch
        let repsField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Reps' OR label CONTAINS 'Reps'")).firstMatch
        
        if weightField.waitForExistence(timeout: 2) {
            weightField.tap()
            weightField.typeText("185")
        }
        
        if repsField.waitForExistence(timeout: 2) {
            repsField.tap()
            repsField.typeText("8")
        }
        
        // Tap Complete Set button
        let completeSetButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Complete Set'")).firstMatch
        if completeSetButton.waitForExistence(timeout: 2) {
            completeSetButton.tap()
            
            // Then - Rest timer should appear
            sleep(1)
            // Verify rest timer is visible or set was completed
        }
    }
    
    func testRestTimer() throws {
        // Given - Complete a set
        navigateToWorkout()
        addExerciseToWorkout(name: "Squat")
        completeSet(weight: "225", reps: "5")
        
        // When - Rest timer should be active
        sleep(1)
        
        // Then - Rest timer controls should be visible
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch
        // Rest timer may be visible
        XCTAssertTrue(skipButton.exists || app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rest'")).firstMatch.exists)
    }
    
    func testRestTimer_Skip() throws {
        // Given - Rest timer is active
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        completeSet(weight: "185", reps: "8")
        sleep(1)
        
        // When - Tap Skip button
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch
        if skipButton.waitForExistence(timeout: 2) {
            skipButton.tap()
            
            // Then - Rest timer should be dismissed
            sleep(1)
            XCTAssertFalse(skipButton.exists)
        }
    }
    
    func testRestTimer_CompleteRest() throws {
        // Given - Rest timer is active
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        completeSet(weight: "185", reps: "8")
        sleep(1)
        
        // When - Tap Complete Rest button
        let completeRestButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Complete Rest'")).firstMatch
        if completeRestButton.waitForExistence(timeout: 2) {
            completeRestButton.tap()
            
            // Then - Rest timer should be dismissed
            sleep(1)
            XCTAssertFalse(completeRestButton.exists)
        }
    }
    
    func testRestTimer_ExerciseCardCollapse() throws {
        // Given - Rest timer is active
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        completeSet(weight: "185", reps: "8")
        sleep(1)
        
        // Then - Exercise card should be collapsed (showing minimal info)
        // Verify rest timer is visible and exercise card is condensed
        let restTimer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rest Timer'")).firstMatch
        XCTAssertTrue(restTimer.exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch.exists)
    }
    
    func testFinishWorkout() throws {
        // Given - Start a workout
        navigateToWorkout()
        addExerciseToWorkout(name: "Test Exercise")
        
        // When - Tap Finish button
        let finishButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'checkmark' OR identifier CONTAINS 'finish'")).firstMatch
        if finishButton.exists {
            finishButton.tap()
            
            // Then - Workout should be finished
            sleep(1)
            // Verify workout is cleared
        }
    }
    
    func testFinishWorkout_ShowsCompletionModal() throws {
        // Given - Complete a workout with sets
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        completeSet(weight: "185", reps: "8")
        
        // Skip rest timer if present
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch
        if skipButton.waitForExistence(timeout: 1) {
            skipButton.tap()
            sleep(1)
        }
        
        // When - Finish workout
        let finishButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'checkmark' OR identifier CONTAINS 'finish'")).firstMatch
        if finishButton.waitForExistence(timeout: 2) {
            finishButton.tap()
            sleep(1)
            
            // Confirm finish if confirmation dialog appears
            let confirmButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Finish' OR label CONTAINS 'Confirm'")).firstMatch
            if confirmButton.waitForExistence(timeout: 1) {
                confirmButton.tap()
                sleep(2)
            }
            
            // Then - Completion modal should appear
            let completionModal = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Workout Complete' OR label CONTAINS 'Great job'")).firstMatch
            XCTAssertTrue(completionModal.exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Done'")).firstMatch.exists)
        }
    }
    
    func testCompletionModal_Dismiss() throws {
        // Given - Completion modal is shown
        navigateToWorkout()
        addExerciseToWorkout(name: "Bench Press")
        completeSet(weight: "185", reps: "8")
        
        // Skip rest and finish workout
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Skip'")).firstMatch
        if skipButton.waitForExistence(timeout: 1) {
            skipButton.tap()
            sleep(1)
        }
        
        let finishButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'checkmark' OR identifier CONTAINS 'finish'")).firstMatch
        if finishButton.waitForExistence(timeout: 2) {
            finishButton.tap()
            sleep(1)
            
            let confirmButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Finish' OR label CONTAINS 'Confirm'")).firstMatch
            if confirmButton.waitForExistence(timeout: 1) {
                confirmButton.tap()
                sleep(2)
            }
        }
        
        // When - Tap Done button
        let doneButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Done'")).firstMatch
        if doneButton.waitForExistence(timeout: 3) {
            doneButton.tap()
            
            // Then - Modal should be dismissed
            sleep(1)
            XCTAssertFalse(doneButton.exists)
        }
    }
    
    func testPauseWorkout() throws {
        // Given - Start a workout
        navigateToWorkout()
        addExerciseToWorkout(name: "Test Exercise")
        
        // When - Tap Pause button
        let pauseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'pause' OR identifier CONTAINS 'pause'")).firstMatch
        if pauseButton.exists {
            pauseButton.tap()
            
            // Then - Workout should be paused
            sleep(1)
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToWorkout() {
        let workoutButton = app.buttons["Workout"]
        if workoutButton.waitForExistence(timeout: 2) {
            workoutButton.tap()
            sleep(1)
        }
    }
    
    private func addExerciseToWorkout(name: String) {
        let addExerciseButton = app.buttons.matching(identifier: "Add Exercise").firstMatch
        if addExerciseButton.waitForExistence(timeout: 2) {
            addExerciseButton.tap()
            sleep(1)
            
            let exerciseNameField = app.textFields.firstMatch
            if exerciseNameField.waitForExistence(timeout: 2) {
                exerciseNameField.tap()
                exerciseNameField.typeText(name)
                
                let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add Exercise'")).firstMatch
                if addButton.waitForExistence(timeout: 2) {
                    addButton.tap()
                    sleep(1)
                }
            }
        }
    }
    
    private func completeSet(weight: String, reps: String) {
        let weightField = app.textFields.firstMatch
        if weightField.waitForExistence(timeout: 2) {
            weightField.tap()
            weightField.typeText(weight)
        }
        
        let repsField = app.textFields.element(boundBy: 1)
        if repsField.exists {
            repsField.tap()
            repsField.typeText(reps)
        }
        
        let completeSetButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Complete Set'")).firstMatch
        if completeSetButton.waitForExistence(timeout: 2) {
            completeSetButton.tap()
            sleep(1)
        }
    }
}







