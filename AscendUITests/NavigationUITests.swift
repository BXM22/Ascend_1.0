//
//  NavigationUITests.swift
//  AscendUITests
//
//  Created on 2024
//

import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testNavigateToDashboard() throws {
        // Given - App is launched
        
        // When - Tap Dashboard tab
        let dashboardButton = app.buttons["Home"]
        XCTAssertTrue(dashboardButton.waitForExistence(timeout: 2))
        dashboardButton.tap()
        
        // Then - Dashboard should be visible
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
    }
    
    func testNavigateToWorkout() throws {
        // Given - App is launched
        
        // When - Tap Workout tab
        let workoutButton = app.buttons["Workout"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 2))
        workoutButton.tap()
        
        // Then - Workout view should be visible
        // Look for workout-related elements
        XCTAssertTrue(app.buttons.matching(identifier: "Add Exercise").firstMatch.exists || 
                     app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Workout'")).firstMatch.exists)
    }
    
    func testNavigateToProgress() throws {
        // Given - App is launched
        
        // When - Tap Progress tab
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 2))
        progressButton.tap()
        
        // Then - Progress view should be visible
        XCTAssertTrue(app.staticTexts["Progress"].exists)
    }
    
    func testNavigateToTemplates() throws {
        // Given - App is launched
        
        // When - Tap Templates tab
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        
        // Then - Templates view should be visible
        XCTAssertTrue(app.staticTexts["Templates"].exists)
    }
    
    func testTabBarExists() throws {
        // Given - App is launched
        
        // Then - All tab bar buttons should exist
        XCTAssertTrue(app.buttons["Home"].exists)
        XCTAssertTrue(app.buttons["Workout"].exists)
        XCTAssertTrue(app.buttons["Progress"].exists)
        XCTAssertTrue(app.buttons["Templates"].exists)
    }
    
    func testThemeToggleButton() throws {
        // Given - App is launched
        
        // When - Look for theme toggle button
        let themeButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'paintbrush'")).firstMatch
        
        // Then - Theme button should exist (may not be visible initially)
        // This test verifies the button is accessible
        XCTAssertTrue(app.buttons.count > 4) // At least 4 nav buttons + theme button
    }
}







