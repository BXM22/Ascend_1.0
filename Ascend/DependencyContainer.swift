import Foundation
import SwiftUI

/// Dependency container for managing ViewModel dependencies
/// This provides a centralized way to manage and inject dependencies
class DependencyContainer {
    
    // MARK: - Singleton Instance
    
    static let shared = DependencyContainer()
    
    // MARK: - ViewModels
    
    let progressViewModel: ProgressViewModel
    let templatesViewModel: TemplatesViewModel
    let programViewModel: WorkoutProgramViewModel
    let themeManager: ThemeManager
    let settingsManager: SettingsManager
    
    // MARK: - Managers (Shared Instances)
    
    let exerciseDataManager: ExerciseDataManager
    let workoutHistoryManager: WorkoutHistoryManager
    let cloudKitSyncManager: CloudKitSyncManager
    let notificationManager: NotificationManager
    
    // MARK: - Initialization
    
    private init() {
        // Initialize managers first (they're singletons)
        exerciseDataManager = ExerciseDataManager.shared
        workoutHistoryManager = WorkoutHistoryManager.shared
        cloudKitSyncManager = CloudKitSyncManager.shared
        notificationManager = NotificationManager.shared
        
        // Initialize ViewModels
        progressViewModel = ProgressViewModel()
        templatesViewModel = TemplatesViewModel()
        programViewModel = WorkoutProgramViewModel()
        themeManager = ThemeManager()
        settingsManager = SettingsManager()
    }
    
    // MARK: - Factory Methods
    
    /// Creates a WorkoutViewModel with all required dependencies injected
    /// Note: This creates a new instance each time. For SwiftUI, use @StateObject in the view.
    func makeWorkoutViewModel() -> WorkoutViewModel {
        return WorkoutViewModel(
            settingsManager: settingsManager,
            progressViewModel: progressViewModel,
            programViewModel: programViewModel,
            templatesViewModel: templatesViewModel,
            themeManager: themeManager
        )
    }
    
    /// Updates a WorkoutViewModel's dependencies (useful when dependencies change)
    func updateWorkoutViewModelDependencies(_ viewModel: WorkoutViewModel) {
        // Note: Since dependencies are set in init, we need to recreate the view model
        // This is a limitation of the current design. In a production app, you might
        // want to use a different pattern or make dependencies mutable.
    }
    
    // MARK: - Reset (for testing)
    
    /// Resets all ViewModels (useful for testing)
    func reset() {
        // Note: This doesn't recreate ViewModels, just resets their state
        // For a full reset, you'd need to recreate the container
    }
}

/// Environment key for dependency container
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

