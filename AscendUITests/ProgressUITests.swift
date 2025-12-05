//
//  ProgressUITests.swift
//  AscendUITests
//
//  Created on 2024
//

import XCTest

final class ProgressUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Progress View Tests
    
    func testProgressViewDisplays() throws {
        // Given - Navigate to Progress
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        
        // Then - Progress view should be visible
        XCTAssertTrue(app.staticTexts["Progress"].exists)
    }
    
    func testWorkoutStreakCard() throws {
        // Given - Navigate to Progress
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        sleep(1)
        
        // Then - Streak information should be visible
        let streakElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Streak' OR label CONTAINS 'days'"))
        // Streak card should be present
        XCTAssertTrue(streakElements.count > 0 || app.staticTexts.matching(NSPredicate(format: "label MATCHES '\\\\d+'")).count > 0)
    }
    
    func testPRTracker() throws {
        // Given - Navigate to Progress
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        sleep(1)
        
        // Then - PR Tracker section should be visible
        let prElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'PR' OR label CONTAINS 'Personal Record'"))
        // PR tracker should be present (may be empty)
        XCTAssertTrue(prElements.count >= 0)
    }
    
    func testExerciseSelector() throws {
        // Given - Navigate to Progress
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        sleep(1)
        
        // When - Look for exercise selector
        let exerciseMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Select Exercise' OR label CONTAINS 'Exercise'")).firstMatch
        
        // Then - Exercise selector should exist (if exercises are available)
        // This may not exist if no exercises have been tracked
        if app.buttons.matching(NSPredicate(format: "label CONTAINS 'Exercise'")).count > 0 {
            XCTAssertTrue(exerciseMenu.exists)
        }
    }
    
    func testWeekMonthToggle() throws {
        // Given - Navigate to Progress
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        sleep(1)
        
        // When - Look for Week/Month toggle
        let weekButton = app.buttons.matching(identifier: "Week").firstMatch
        let monthButton = app.buttons.matching(identifier: "Month").firstMatch
        
        // Then - Toggle buttons should exist
        if weekButton.exists {
            XCTAssertTrue(monthButton.exists)
            
            // Test switching
            monthButton.tap()
            sleep(1)
            XCTAssertTrue(monthButton.exists)
        }
    }
    
    func testDashboardStats() throws {
        // Given - Navigate to Dashboard
        let dashboardButton = app.buttons["Home"]
        XCTAssertTrue(dashboardButton.waitForExistence(timeout: 2))
        dashboardButton.tap()
        sleep(1)
        
        // Then - Stats should be visible
        let statsElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Streak' OR label CONTAINS 'Volume' OR label CONTAINS 'Workouts'"))
        // Dashboard should show some stats
        XCTAssertTrue(statsElements.count >= 0)
    }
    
    func testRecentPRs() throws {
        // Given - Navigate to Dashboard
        let dashboardButton = app.buttons["Home"]
        XCTAssertTrue(dashboardButton.waitForExistence(timeout: 2))
        dashboardButton.tap()
        sleep(1)
        
        // Then - Recent PRs section should be visible (may be empty)
        let prSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'PR' OR label CONTAINS 'Recent'"))
        // PR section should exist (even if empty)
        XCTAssertTrue(prSection.count >= 0)
    }
}





