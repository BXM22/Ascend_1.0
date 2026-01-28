import SwiftUI
import UIKit

// MARK: - Accessibility Announcements Manager
/// Centralized manager for VoiceOver announcements
struct AccessibilityAnnouncer {
    
    // MARK: - Workout Announcements
    
    /// Announces when a set is completed
    static func announceSetCompleted(setNumber: Int, of totalSets: Int, exerciseName: String) {
        let message: String
        if setNumber >= totalSets {
            message = "Set \(setNumber) of \(totalSets) completed for \(exerciseName). All sets finished!"
        } else {
            message = "Set \(setNumber) of \(totalSets) completed for \(exerciseName)"
        }
        announce(message)
    }
    
    /// Announces when a new PR is achieved
    static func announcePR(message: String) {
        announce("New personal record! \(message)", priority: .high)
    }
    
    /// Announces when rest timer completes
    static func announceRestComplete() {
        announce("Rest time complete. Ready for your next set.", priority: .high)
    }
    
    /// Announces rest timer starting
    static func announceRestStarted(seconds: Int) {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        let timeString: String
        if minutes > 0 && remainingSeconds > 0 {
            timeString = "\(minutes) minute\(minutes > 1 ? "s" : "") and \(remainingSeconds) seconds"
        } else if minutes > 0 {
            timeString = "\(minutes) minute\(minutes > 1 ? "s" : "")"
        } else {
            timeString = "\(remainingSeconds) seconds"
        }
        
        announce("Rest timer started. \(timeString) remaining.")
    }
    
    /// Announces workout started
    static func announceWorkoutStarted(exerciseCount: Int) {
        let exerciseText = exerciseCount == 1 ? "1 exercise" : "\(exerciseCount) exercises"
        announce("Workout started with \(exerciseText)")
    }
    
    /// Announces workout completed
    static func announceWorkoutCompleted(totalSets: Int, duration: TimeInterval) {
        let minutes = Int(duration) / 60
        let timeText = minutes > 0 ? "\(minutes) minutes" : "less than a minute"
        announce("Workout completed! \(totalSets) total sets in \(timeText).", priority: .high)
    }
    
    /// Announces exercise added
    static func announceExerciseAdded(exerciseName: String, position: Int) {
        announce("\(exerciseName) added as exercise \(position)")
    }
    
    /// Announces exercise removed
    static func announceExerciseRemoved(exerciseName: String) {
        announce("\(exerciseName) removed from workout")
    }
    
    /// Announces exercise reordered
    static func announceExerciseReordered(exerciseName: String, newPosition: Int) {
        announce("\(exerciseName) moved to position \(newPosition)")
    }
    
    // MARK: - Navigation Announcements
    
    /// Announces current exercise focus
    static func announceExerciseFocused(exerciseName: String, setNumber: Int, of totalSets: Int) {
        announce("Now on \(exerciseName), set \(setNumber) of \(totalSets)")
    }
    
    // MARK: - Error Announcements
    
    /// Announces an error
    static func announceError(_ message: String) {
        announce("Error: \(message)", priority: .high)
    }
    
    /// Announces a success
    static func announceSuccess(_ message: String) {
        announce(message, priority: .high)
    }
    
    // MARK: - Core Announcement Function
    
    enum AnnouncementPriority {
        case low
        case normal
        case high
    }
    
    /// Posts a VoiceOver announcement
    static func announce(_ message: String, priority: AnnouncementPriority = .normal) {
        // Only announce if VoiceOver is running
        guard UIAccessibility.isVoiceOverRunning else { return }
        
        let priorityValue: UIAccessibility.Notification
        switch priority {
        case .low:
            priorityValue = .announcement
        case .normal:
            priorityValue = .announcement
        case .high:
            // For high priority, we use announcement with a slight delay
            // to ensure it interrupts current speech
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
            return
        }
        
        UIAccessibility.post(notification: priorityValue, argument: message)
    }
}

// MARK: - View Extension for Announcements
extension View {
    /// Announces a message when a value changes
    func announceOnChange<V: Equatable>(of value: V, message: @escaping (V) -> String?) -> some View {
        self.onChange(of: value) { oldValue, newValue in
            if let message = message(newValue) {
                AccessibilityAnnouncer.announce(message)
            }
        }
    }
    
    /// Announces when this view appears
    func announceOnAppear(_ message: String, priority: AccessibilityAnnouncer.AnnouncementPriority = .normal) -> some View {
        self.onAppear {
            AccessibilityAnnouncer.announce(message, priority: priority)
        }
    }
}

// MARK: - Accessibility Focus Management
struct AccessibilityFocusModifier: ViewModifier {
    @Binding var isFocused: Bool
    @AccessibilityFocusState private var accessibilityFocus: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($accessibilityFocus)
            .onChange(of: isFocused) { _, newValue in
                accessibilityFocus = newValue
            }
            .onChange(of: accessibilityFocus) { _, newValue in
                isFocused = newValue
            }
    }
}

extension View {
    /// Manages accessibility focus state with a binding
    func accessibilityFocus(_ isFocused: Binding<Bool>) -> some View {
        modifier(AccessibilityFocusModifier(isFocused: isFocused))
    }
}
