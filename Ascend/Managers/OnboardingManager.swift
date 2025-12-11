import Foundation 
import SwiftUI
import Combine

/// Manages onboarding and tutorial state
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var hasCompletedTutorial: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedTutorial, forKey: AppConstants.UserDefaultsKeys.hasCompletedTutorial)
        }
    }
    
    @Published var currentTutorialStep: Int = 0
    @Published var showTutorial: Bool = false
    
    private let tutorialKey = AppConstants.UserDefaultsKeys.hasCompletedTutorial
    
    private init() {
        self.hasCompletedTutorial = UserDefaults.standard.bool(forKey: tutorialKey)
        // Show tutorial if not completed
        self.showTutorial = !hasCompletedTutorial
    }
    
    func completeTutorial() {
        hasCompletedTutorial = true
        showTutorial = false
        currentTutorialStep = 0
    }
    
    func resetTutorial() {
        hasCompletedTutorial = false
        showTutorial = true
        currentTutorialStep = 0
    }
    
    func nextStep() {
        if currentTutorialStep < TutorialStep.allCases.count - 1 {
            currentTutorialStep += 1
        } else {
            completeTutorial()
        }
    }
    
    var currentStep: TutorialStep {
        TutorialStep(rawValue: currentTutorialStep) ?? .welcome
    }
    
    func previousStep() {
        if currentTutorialStep > 0 {
            currentTutorialStep -= 1
        }
    }
    
    func skipTutorial() {
        completeTutorial()
    }
}

// MARK: - Tutorial Steps

enum TutorialStep: Int, CaseIterable {
    case welcome = 0
    case dashboard
    case workout
    case progress
    case templates
    case theme
    case complete
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Ascend!"
        case .dashboard:
            return "Dashboard"
        case .workout:
            return "Track Your Workouts"
        case .progress:
            return "Monitor Progress"
        case .templates:
            return "Workout Templates"
        case .theme:
            return "Customize Your Theme"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Your personal workout companion for tracking exercises, monitoring progress, and achieving your fitness goals."
        case .dashboard:
            return "Start here! View your workout streak, quick stats, and access your favorite templates. Tap any template to begin a workout."
        case .workout:
            return "Log your sets, track weight and reps, and use the rest timer between exercises. Complete sets to see your progress in real-time."
        case .progress:
            return "View your workout history, personal records, and track your progress over time with detailed charts and statistics."
        case .templates:
            return "Create custom workout templates or generate new ones based on your preferences. Organize your workouts for easy access."
        case .theme:
            return "Personalize your app! Tap the paintbrush button to change the color palette and make Ascend match your style."
        case .complete:
            return "Start your fitness journey! Swipe through the tabs to explore all features. You can always access this tutorial from Settings."
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "figure.strengthtraining.traditional"
        case .dashboard:
            return "house.fill"
        case .workout:
            return "dumbbell.fill"
        case .progress:
            return "chart.line.uptrend.xyaxis"
        case .templates:
            return "list.bullet.rectangle"
        case .theme:
            return "paintbrush.fill"
        case .complete:
            return "checkmark.circle.fill"
        }
    }
    
    var callout: TutorialCallout? {
        switch self {
        case .dashboard:
            return TutorialCallout(
                title: "Dashboard",
                description: "Start here! View your workout streak, quick stats, and access your favorite templates.",
                position: .top
            )
        case .workout:
            return TutorialCallout(
                title: "Track Your Workouts",
                description: "Log your sets, track weight and reps, and use the rest timer between exercises.",
                position: .top
            )
        case .progress:
            return TutorialCallout(
                title: "Monitor Progress",
                description: "View your workout history, personal records, and track your progress over time.",
                position: .top
            )
        case .templates:
            return TutorialCallout(
                title: "Workout Templates",
                description: "Create custom workout templates or generate new ones based on your preferences.",
                position: .top
            )
        case .theme:
            return TutorialCallout(
                title: "Customize Your Theme",
                description: "Personalize your app! Tap the paintbrush button to change the color palette and make Ascend match your style.",
                position: .top
            )
        case .welcome:
            return TutorialCallout(
                title: "Welcome to Ascend!",
                description: "Your personal workout companion for tracking exercises, monitoring progress, and achieving your fitness goals.",
                position: .top
            )
        case .complete:
            return TutorialCallout(
                title: "You're All Set!",
                description: "Start your fitness journey! Swipe through the tabs to explore all features.",
                position: .top
            )
        }
    }
    
    var highlightTab: ContentView.Tab? {
        switch self {
        case .dashboard:
            return .dashboard
        case .workout:
            return .workout
        case .progress:
            return .progress
        case .templates:
            return .templates
        default:
            return nil
        }
    }
    
    var highlightedElement: TutorialElement? {
        switch self {
        case .dashboard:
            return .dashboardTab
        case .workout:
            return .workoutTab
        case .progress:
            return .progressTab
        case .templates:
            return .templatesTab
        case .theme:
            return .themeButton
        case .welcome:
            return nil
        case .complete:
            return nil
        }
    }
}
