import Foundation
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil // nil = system, .light = light, .dark = dark
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    @Published var themeMode: ThemeMode = .system {
        didSet {
            updateColorScheme()
            saveThemePreference()
        }
    }
    
    init() {
        loadThemePreference()
    }
    
    private func updateColorScheme() {
        switch themeMode {
        case .system:
            colorScheme = nil
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
    
    private func saveThemePreference() {
        UserDefaults.standard.set(themeMode.rawValue, forKey: AppConstants.UserDefaultsKeys.themeMode)
    }
    
    private func loadThemePreference() {
        if let saved = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.themeMode),
           let mode = ThemeMode(rawValue: saved) {
            themeMode = mode
        }
        updateColorScheme()
    }
}





