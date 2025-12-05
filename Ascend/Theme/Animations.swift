import SwiftUI

// MARK: - Optimized Animation Constants
struct AppAnimations {
    // Fast, responsive animations for interactions
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    
    // Standard animations for UI transitions
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.8)
    
    // Smooth animations for content changes
    static let smooth = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    // Gentle animations for subtle changes
    static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    // Button press animations
    static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.7)
    
    // Tab/selection animations
    static let selection = Animation.spring(response: 0.25, dampingFraction: 0.8)
}

// MARK: - Optimized Transitions
extension AnyTransition {
    static var smoothSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    static var smoothScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    static var smoothFade: AnyTransition {
        .opacity
    }
}

