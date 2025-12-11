#if canImport(UIKit)
import UIKit

// MARK: - Haptic Feedback Manager
struct HapticManager {
    /// Light impact feedback for button presses
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Success notification for achievements (e.g., PR badges)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification for important alerts
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification for failures
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Selection feedback for tab changes and selections
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Medium impact for more pronounced feedback
    static func mediumImpact() {
        impact(style: .medium)
    }
    
    /// Heavy impact for significant actions
    static func heavyImpact() {
        impact(style: .heavy)
    }
}
#endif








