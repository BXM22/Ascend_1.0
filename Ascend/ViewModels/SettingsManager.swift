import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var restTimerDuration: Int {
        didSet {
            UserDefaults.standard.set(restTimerDuration, forKey: "restTimerDuration")
        }
    }
    
    @Published var customTheme: ColorTheme? {
        didSet {
            saveCustomTheme()
            // Notify AppColors to update
            NotificationCenter.default.post(name: .colorThemeDidChange, object: nil)
        }
    }
    
    init() {
        // Load saved rest timer duration, default to 90 seconds
        self.restTimerDuration = UserDefaults.standard.object(forKey: "restTimerDuration") as? Int ?? 90
        
        // Load custom theme
        loadCustomTheme()
    }
    
    // MARK: - Color Theme Import
    
    func importTheme(from urlString: String) -> Result<ColorTheme, Error> {
        guard let colors = CoolorsURLParser.parse(urlString: urlString) else {
            return .failure(ColorThemeError.invalidURL)
        }
        
        guard colors.count >= 3 else {
            return .failure(ColorThemeError.insufficientColors)
        }
        
        let theme = ColorTheme(
            name: "Custom Theme",
            colors: colors
        )
        
        customTheme = theme
        return .success(theme)
    }
    
    func resetToDefaultTheme() {
        customTheme = nil
    }
    
    // MARK: - Persistence
    
    private func saveCustomTheme() {
        if let theme = customTheme,
           let encoded = try? JSONEncoder().encode(theme) {
            UserDefaults.standard.set(encoded, forKey: "customColorTheme")
        } else {
            UserDefaults.standard.removeObject(forKey: "customColorTheme")
        }
    }
    
    private func loadCustomTheme() {
        if let data = UserDefaults.standard.data(forKey: "customColorTheme"),
           let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
            self.customTheme = theme
        }
    }
}

// MARK: - Color Theme Errors
enum ColorThemeError: LocalizedError {
    case invalidURL
    case insufficientColors
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Coolors.co URL. Please check the format."
        case .insufficientColors:
            return "Theme must contain at least 3 colors."
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let colorThemeDidChange = Notification.Name("colorThemeDidChange")
}





