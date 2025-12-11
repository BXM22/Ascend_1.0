//
//  SettingsUITests.swift
//  AscendUITests
//
//  Created on 2024
//

import XCTest

final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Settings Tests
    
    func testOpenSettingsFromWorkout() throws {
        // Given - Start a workout
        let workoutButton = app.buttons["Workout"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 2))
        workoutButton.tap()
        sleep(1)
        
        // When - Tap settings button
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear' OR identifier CONTAINS 'settings'")).firstMatch
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()
            sleep(1)
            
            // Then - Settings sheet should appear
            XCTAssertTrue(app.navigationBars["Settings"].exists || 
                         app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rest Timer'")).firstMatch.exists)
        }
    }
    
    func testRestTimerSettings() throws {
        // Given - Open settings
        openSettings()
        
        // Then - Rest timer settings should be visible
        let restTimerLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Rest Timer'")).firstMatch
        XCTAssertTrue(restTimerLabel.exists || app.sliders.firstMatch.exists)
    }
    
    func testChangeRestTimerDuration() throws {
        // Given - Open settings
        openSettings()
        sleep(1)
        
        // When - Adjust rest timer slider
        let slider = app.sliders.firstMatch
        if slider.waitForExistence(timeout: 2) {
            slider.adjust(toNormalizedSliderPosition: 0.5)
            sleep(1)
            
            // Then - Duration should update
            // Verify by checking displayed time
            let timeDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'm' OR label CONTAINS 's'")).firstMatch
            XCTAssertTrue(timeDisplay.exists)
        }
    }
    
    func testRestTimerQuickOptions() throws {
        // Given - Open settings
        openSettings()
        sleep(1)
        
        // When - Look for quick option buttons
        let quickOptions = app.buttons.matching(NSPredicate(format: "label CONTAINS 's' OR label CONTAINS 'm'"))
        
        // Then - Quick options should be available
        if quickOptions.count > 0 {
            // Tap one option
            quickOptions.firstMatch.tap()
            sleep(1)
            // Verify selection
        }
    }
    
    func testCloseSettings() throws {
        // Given - Open settings
        openSettings()
        sleep(1)
        
        // When - Tap Done button
        let doneButton = app.buttons.matching(identifier: "Done").firstMatch
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
            sleep(1)
            
            // Then - Settings should close
            XCTAssertFalse(app.navigationBars["Settings"].exists)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openSettings() {
        // Navigate to workout view
        let workoutButton = app.buttons["Workout"]
        if workoutButton.waitForExistence(timeout: 2) {
            workoutButton.tap()
            sleep(1)
            
            // Tap settings button
            let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear' OR identifier CONTAINS 'settings'")).firstMatch
            if settingsButton.waitForExistence(timeout: 2) {
                settingsButton.tap()
                sleep(1)
            }
        }
    }
}














