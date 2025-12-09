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
    
    @Published var barWeight: Double {
        didSet {
            UserDefaults.standard.set(barWeight, forKey: "barWeight")
        }
    }
    
    @Published var warmupPercentages: [Double] {
        didSet {
            saveWarmupPercentages()
        }
    }
    
    @Published var pauseTimerDuringRest: Bool {
        didSet {
            UserDefaults.standard.set(pauseTimerDuringRest, forKey: AppConstants.UserDefaultsKeys.pauseTimerDuringRest)
        }
    }
    
    init() {
        // Load saved rest timer duration, default to 90 seconds
        self.restTimerDuration = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.restTimerDuration) as? Int ?? AppConstants.Timer.defaultRestDuration
        
        // Load bar weight, default to 45 lbs
        self.barWeight = UserDefaults.standard.object(forKey: "barWeight") as? Double ?? 45.0
        
        // Load warm-up percentages, default to [50%, 70%, 90%]
        // Inline the logic to avoid calling instance method before all properties are initialized
        if let saved = UserDefaults.standard.array(forKey: AppConstants.UserDefaultsKeys.warmupPercentages) as? [Double] {
            self.warmupPercentages = saved
        } else {
            self.warmupPercentages = AppConstants.Warmup.defaultPercentages
        }
        
        // Load pause timer during rest setting, default to false
        self.pauseTimerDuringRest = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.pauseTimerDuringRest)
        
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
    
    // MARK: - Warm-up Settings
    
    private func saveWarmupPercentages() {
        UserDefaults.standard.set(warmupPercentages, forKey: AppConstants.UserDefaultsKeys.warmupPercentages)
    }
    
    private func loadWarmupPercentages() -> [Double] {
        if let saved = UserDefaults.standard.array(forKey: AppConstants.UserDefaultsKeys.warmupPercentages) as? [Double] {
            return saved
        }
        return AppConstants.Warmup.defaultPercentages
    }
    
    func resetWarmupPercentages() {
        warmupPercentages = AppConstants.Warmup.defaultPercentages
    }
    
    // MARK: - Reset Data
    
    /// Reset all app data with a completion handler
    func resetAllData(
        progressViewModel: ProgressViewModel,
        templatesViewModel: TemplatesViewModel,
        programViewModel: WorkoutProgramViewModel,
        themeManager: ThemeManager
    ) {
        // Clear ALL UserDefaults keys used by the app
        let keysToRemove = [
            AppConstants.UserDefaultsKeys.restTimerDuration,
            AppConstants.UserDefaultsKeys.customColorTheme,
            AppConstants.UserDefaultsKeys.themeMode,
            AppConstants.UserDefaultsKeys.savedWorkoutPrograms,
            AppConstants.UserDefaultsKeys.activeWorkoutProgram,
            AppConstants.UserDefaultsKeys.savedWorkoutTemplates,
            AppConstants.UserDefaultsKeys.customExercises,
            AppConstants.UserDefaultsKeys.completedWorkouts,
            AppConstants.UserDefaultsKeys.personalRecords,
            AppConstants.UserDefaultsKeys.workoutDates,
            AppConstants.UserDefaultsKeys.restDays,
            // Rest timer state
            AppConstants.UserDefaultsKeys.restTimerActive,
            AppConstants.UserDefaultsKeys.restTimerRemaining,
            AppConstants.UserDefaultsKeys.restTimerTotalDuration,
            AppConstants.UserDefaultsKeys.restTimerStartTime
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset SettingsManager properties
        self.restTimerDuration = AppConstants.Timer.defaultRestDuration
        self.customTheme = nil
        
        // Reset ThemeManager
        themeManager.themeMode = .system
        
        // Reset ProgressViewModel (clear both in-memory and UserDefaults)
        progressViewModel.prs = []
        progressViewModel.workoutDates = []
        progressViewModel.restDays = []
        progressViewModel.currentStreak = 0
        progressViewModel.longestStreak = 0
        progressViewModel.totalVolume = 0
        progressViewModel.workoutCount = 0
        progressViewModel.selectedExercise = ""
        
        // Reset WorkoutHistoryManager (shared singleton)
        WorkoutHistoryManager.shared.completedWorkouts = []
        
        // Reset ExerciseDataManager (shared singleton)
        ExerciseDataManager.shared.clearAllCustomExercises()
        
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





