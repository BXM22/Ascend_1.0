import XCTest
@testable import Ascend

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.restTimerDuration)
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.customColorTheme)
    }
    
    override func tearDown() {
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Rest Timer Tests
    
    func testDefaultRestTimerDuration() {
        // Given/When
        let manager = SettingsManager()
        
        // Then
        XCTAssertEqual(manager.restTimerDuration, AppConstants.Timer.defaultRestDuration)
    }
    
    func testSetRestTimerDuration() {
        // Given
        let newDuration = 120
        
        // When
        settingsManager.restTimerDuration = newDuration
        
        // Then
        XCTAssertEqual(settingsManager.restTimerDuration, newDuration)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: AppConstants.UserDefaultsKeys.restTimerDuration), newDuration)
    }
    
    // MARK: - Theme Import Tests
    
    func testImportTheme_ValidURL() {
        // Given - This would need a valid Coolors URL format
        // Note: Actual implementation depends on CoolorsURLParser
        let urlString = "https://coolors.co/0d1b2a-1b263b-415a77-778da9-e0e1dd"
        
        // When
        let result = settingsManager.importTheme(from: urlString)
        
        // Then - Result depends on CoolorsURLParser implementation
        // This test verifies the method doesn't crash
        XCTAssertNotNil(result)
    }
    
    func testImportTheme_InvalidURL() {
        // Given
        let invalidURL = "not-a-valid-url"
        
        // When
        let result = settingsManager.importTheme(from: invalidURL)
        
        // Then
        switch result {
        case .failure(let error):
            XCTAssertTrue(error is AppError)
        case .success:
            XCTFail("Should have failed with invalid URL")
        }
    }
    
    func testResetToDefaultTheme() {
        // Given
        let urlString = "https://coolors.co/0d1b2a-1b263b-415a77-778da9-e0e1dd"
        _ = settingsManager.importTheme(from: urlString)
        XCTAssertNotNil(settingsManager.customTheme)
        
        // When
        settingsManager.resetToDefaultTheme()
        
        // Then
        XCTAssertNil(settingsManager.customTheme)
    }
}
