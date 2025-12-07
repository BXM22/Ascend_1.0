import XCTest
@testable import Ascend
import SwiftUI

final class ThemeManagerTests: XCTestCase {
    var themeManager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        themeManager = ThemeManager()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.themeMode)
    }
    
    override func tearDown() {
        themeManager = nil
        super.tearDown()
    }
    
    // MARK: - Theme Mode Tests
    
    func testDefaultThemeMode() {
        // Given/When
        let manager = ThemeManager()
        
        // Then
        XCTAssertEqual(manager.themeMode, .system)
    }
    
    func testSetThemeMode_Light() {
        // When
        themeManager.themeMode = .light
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .light)
        XCTAssertEqual(themeManager.colorScheme, .light)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.themeMode), "Light")
    }
    
    func testSetThemeMode_Dark() {
        // When
        themeManager.themeMode = .dark
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .dark)
        XCTAssertEqual(themeManager.colorScheme, .dark)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.themeMode), "Dark")
    }
    
    func testSetThemeMode_System() {
        // Given
        themeManager.themeMode = .light
        
        // When
        themeManager.themeMode = .system
        
        // Then
        XCTAssertEqual(themeManager.themeMode, .system)
        XCTAssertNil(themeManager.colorScheme)
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.themeMode), "System")
    }
    
    func testThemeModePersistence() {
        // Given
        themeManager.themeMode = .dark
        
        // When - Create new instance
        let newManager = ThemeManager()
        
        // Then - Should load saved preference
        XCTAssertEqual(newManager.themeMode, .dark)
    }
}
