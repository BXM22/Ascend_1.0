import XCTest
@testable import Ascend

final class SettingsManagerTests: XCTestCase {
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "restTimerDuration")
        settingsManager = SettingsManager()
    }
    
    override func tearDown() {
        settingsManager = nil
        UserDefaults.standard.removeObject(forKey: "restTimerDuration")
        super.tearDown()
    }
    
    // MARK: - Rest Timer Duration Tests
    
    func testDefaultRestTimerDuration() {
        // Given/When
        // SettingsManager is initialized
        
        // Then
        XCTAssertGreaterThan(settingsManager.restTimerDuration, 0)
        XCTAssertLessThanOrEqual(settingsManager.restTimerDuration, 600)
    }
    
    func testSetRestTimerDuration() {
        // Given
        let newDuration = 120
        
        // When
        settingsManager.restTimerDuration = newDuration
        
        // Then
        XCTAssertEqual(settingsManager.restTimerDuration, newDuration)
    }
    
    func testRestTimerDurationPersistence() {
        // Given
        let duration = 90
        settingsManager.restTimerDuration = duration
        
        // When - Create new instance
        let newManager = SettingsManager()
        
        // Then - Should load saved value
        XCTAssertEqual(newManager.restTimerDuration, duration)
    }
    
    func testRestTimerDurationUserDefaults() {
        // Given
        let duration = 60
        settingsManager.restTimerDuration = duration
        
        // When
        let savedValue = UserDefaults.standard.integer(forKey: "restTimerDuration")
        
        // Then
        XCTAssertEqual(savedValue, duration)
    }
}





