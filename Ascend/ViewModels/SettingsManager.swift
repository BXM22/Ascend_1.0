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
    
    // MARK: - Reset Data
    
    /// Reset all app data with a completion handler
    func resetAllData(
        progressViewModel: ProgressViewModel,
        templatesViewModel: TemplatesViewModel,
        programViewModel: WorkoutProgramViewModel,
        themeManager: ThemeManager
    ) {
        // Clear all UserDefaults keys
        let keysToRemove = [
            "restTimerDuration",
            "customColorTheme",
            "themeMode",
            "savedWorkoutPrograms",
            "activeWorkoutProgram",
            "savedWorkoutTemplates"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset SettingsManager properties
        self.restTimerDuration = 90
        self.customTheme = nil
        
        // Reset ThemeManager
        themeManager.themeMode = .system
        
        // Reset ProgressViewModel
        progressViewModel.prs = []
        progressViewModel.workoutDates = []
        progressViewModel.currentStreak = 0
        progressViewModel.longestStreak = 0
        progressViewModel.totalVolume = 0
        progressViewModel.workoutCount = 0
        progressViewModel.selectedExercise = ""
        
        // Reset TemplatesViewModel
        templatesViewModel.templates = []
        templatesViewModel.loadSampleTemplates()
        templatesViewModel.loadCalisthenicsTemplates()
        
        // Reset WorkoutProgramViewModel
        programViewModel.programs = []
        programViewModel.activeProgram = nil
        programViewModel.loadDefaultPrograms()
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





