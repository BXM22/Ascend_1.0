//
//  ThemeManager.swift
//  Ascend
//
//  Manager for app theme mode (light/dark/system)
//

import Foundation
import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil // set by updateColorScheme(); default mode is .dark
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    /// Defaults to **Dark** so the charcoal palette and contrast tokens apply until the user changes appearance.
    @Published var themeMode: ThemeMode = .dark {
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
        } else {
            themeMode = .dark
        }
        updateColorScheme()
    }
}
