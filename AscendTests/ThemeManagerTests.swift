import XCTest
@testable import Ascend
import SwiftUI

final class ThemeManagerTests: XCTestCase {
    var themeManager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "themeMode")
        themeManager = ThemeManager()
    }
    
    override func tearDown() {
        themeManager = nil
        UserDefaults.standard.removeObject(forKey: "themeMode")
        super.tearDown()
    }
    
    // MARK: - Theme Mode Tests
    
    func testDefaultThemeMode() {
        // Given/When
        // ThemeManager is initialized
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .system)
    }
    
    func testSetThemeMode_Light() {
        // Given/When
        themeManager.themeMode = .light
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .light)
        XCTAssertEqual(themeManager.colorScheme, .light)
    }
    
    func testSetThemeMode_Dark() {
        // Given/When
        themeManager.themeMode = .dark
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .dark)
        XCTAssertEqual(themeManager.colorScheme, .dark)
    }
    
    func testSetThemeMode_System() {
        // Given
        themeManager.themeMode = .light
        
        // When
        themeManager.themeMode = .system
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .system)
        XCTAssertNil(themeManager.colorScheme)
    }
    
    // MARK: - Persistence Tests
    
    func testThemeModePersistence() {
        // Given
        themeManager.themeMode = .dark
        
        // When - Create new instance
        let newManager = ThemeManager()
        
        // Then - Should load saved value
        XCTAssertEqual(newManager.themeMode, .dark)
    }
    
    func testThemeModeUserDefaults() {
        // Given
        themeManager.themeMode = .light
        
        // When
        let savedValue = UserDefaults.standard.string(forKey: "themeMode")
        
        // Then
        XCTAssertEqual(savedValue, "Light")
    }
}






