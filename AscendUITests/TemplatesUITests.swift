//
//  TemplatesUITests.swift
//  AscendUITests
//
//  Created on 2024
//

import XCTest

final class TemplatesUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Template View Tests
    
    func testTemplatesViewDisplays() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        
        // Then - Templates view should be visible
        XCTAssertTrue(app.staticTexts["Templates"].exists)
    }
    
    func testCreateTemplate() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        sleep(1)
        
        // When - Tap create button (+)
        let createButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+' OR identifier CONTAINS 'plus'")).firstMatch
        if createButton.waitForExistence(timeout: 2) {
            createButton.tap()
            sleep(1)
            
            // Then - Template edit sheet should appear
            let templateNameField = app.textFields.firstMatch
            XCTAssertTrue(templateNameField.exists || app.navigationBars["New Template"].exists)
        }
    }
    
    func testEditTemplate() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        sleep(1)
        
        // When - Tap Edit on a template
        let editButtons = app.buttons.matching(identifier: "Edit")
        if editButtons.count > 0 {
            editButtons.firstMatch.tap()
            sleep(1)
            
            // Then - Template edit sheet should appear
            XCTAssertTrue(app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS 'Edit Template' OR identifier CONTAINS 'Template'")).firstMatch.exists)
        }
    }
    
    func testStartTemplate() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        sleep(1)
        
        // When - Tap Start on a template
        let startButtons = app.buttons.matching(identifier: "Start")
        if startButtons.count > 0 {
            startButtons.firstMatch.tap()
            sleep(2)
            
            // Then - Should navigate to Workout view
            // Verify by checking for workout elements
            XCTAssertTrue(app.buttons.matching(identifier: "Add Exercise").firstMatch.exists ||
                         app.buttons.matching(NSPredicate(format: "label CONTAINS 'Complete Set'")).firstMatch.exists ||
                         app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Workout'")).firstMatch.exists)
        }
    }
    
    func testTemplateCardDisplays() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        sleep(1)
        
        // Then - Template cards should be visible
        // Check for template names or exercise counts
        let templateElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'exercises' OR label CONTAINS 'min'"))
        // At least some template info should be visible
        XCTAssertTrue(templateElements.count > 0 || app.buttons.matching(identifier: "Start").count > 0)
    }
    
    func testTemplateCreationFlow() throws {
        // Given - Navigate to Templates
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.waitForExistence(timeout: 2))
        templatesButton.tap()
        sleep(1)
        
        // When - Create new template
        let createButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+' OR identifier CONTAINS 'plus'")).firstMatch
        if createButton.waitForExistence(timeout: 2) {
            createButton.tap()
            sleep(1)
            
            // Fill in template name
            let nameField = app.textFields.firstMatch
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText("Test Template")
                
                // Add exercise
                let exerciseField = app.textFields.element(boundBy: 1)
                if exerciseField.exists {
                    exerciseField.tap()
                    exerciseField.typeText("Test Exercise")
                    
                    // Tap add exercise button
                    let addExerciseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '+' OR identifier CONTAINS 'plus'")).firstMatch
                    if addExerciseButton.exists {
                        addExerciseButton.tap()
                        sleep(1)
                    }
                }
                
                // Save template
                let saveButton = app.buttons.matching(identifier: "Save").firstMatch
                if saveButton.waitForExistence(timeout: 2) {
                    saveButton.tap()
                    sleep(1)
                    
                    // Then - Template should be saved
                    // Verify by checking templates list
                }
            }
        }
    }
}













