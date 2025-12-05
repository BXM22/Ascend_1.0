//
//  AscendUITests.swift
//  AscendUITests
//
//  Created by Brennen Meregillano on 11/17/25.
//

import XCTest

final class AscendUITests: XCTestCase {
    // This file serves as the main UI test suite entry point.
    // Individual UI test files are organized by feature:
    // - NavigationUITests.swift: Tab navigation and basic navigation tests
    // - WorkoutFlowUITests.swift: Workout creation, exercise management, set completion
    // - TemplatesUITests.swift: Template creation, editing, and starting
    // - ProgressUITests.swift: Progress tracking and PR display
    // - SettingsUITests.swift: Settings and rest timer configuration
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
