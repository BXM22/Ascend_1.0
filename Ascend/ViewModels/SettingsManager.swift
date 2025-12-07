import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var restTimerDuration: Int {
        didSet {
            UserDefaults.standard.set(restTimerDuration, forKey: AppConstants.UserDefaultsKeys.restTimerDuration)
        }
    }
    
    @Published var customTheme: ColorTheme? {
        didSet {
            saveCustomTheme()
        // Notify AppColors to update
        NotificationCenter.default.post(name: AppConstants.Notification.colorThemeDidChange, object: nil)
        }
    }
    
    init() {
        // Load saved rest timer duration, default to 90 seconds
        self.restTimerDuration = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.restTimerDuration) as? Int ?? AppConstants.Timer.defaultRestDuration
        
        // Load custom theme
        loadCustomTheme()
    }
    
    // MARK: - Color Theme Import
    
    func importTheme(from urlString: String) -> AppResult<ColorTheme> {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.themeImportError("URL cannot be empty"))
        }
        
        guard let colors = CoolorsURLParser.parse(urlString: urlString) else {
            return .failure(.themeImportError("Invalid Coolors.co URL format"))
        }
        
        guard colors.count >= 3 else {
            return .failure(.themeImportError("Theme must contain at least 3 colors"))
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
        do {
            if let theme = customTheme {
                let encoded = try JSONEncoder().encode(theme)
                UserDefaults.standard.set(encoded, forKey: AppConstants.UserDefaultsKeys.customColorTheme)
            } else {
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.customColorTheme)
            }
        } catch {
            // Log error but don't crash - theme saving is not critical
            Logger.error("Failed to save custom theme", error: error, category: .persistence)
        }
    }
    
    private func loadCustomTheme() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.customColorTheme) else {
            return
        }
        
        do {
            let theme = try JSONDecoder().decode(ColorTheme.self, from: data)
            self.customTheme = theme
        } catch {
            // Log error but don't crash - invalid theme data
            Logger.error("Failed to load custom theme", error: error, category: .persistence)
            // Clear invalid data
            UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.customColorTheme)
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
            AppConstants.UserDefaultsKeys.restTimerDuration,
            AppConstants.UserDefaultsKeys.customColorTheme,
            AppConstants.UserDefaultsKeys.themeMode,
            AppConstants.UserDefaultsKeys.savedWorkoutPrograms,
            AppConstants.UserDefaultsKeys.activeWorkoutProgram,
            AppConstants.UserDefaultsKeys.savedWorkoutTemplates
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset SettingsManager properties
        self.restTimerDuration = AppConstants.Timer.defaultRestDuration
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
        
        // Reset TemplatesViewModel - but preserve default templates
        templatesViewModel.templates = []
        // Reload default templates after reset
        templatesViewModel.loadDefaultTemplates()
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
    static let colorThemeDidChange = AppConstants.Notification.colorThemeDidChange
}





