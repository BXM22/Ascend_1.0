import SwiftUI

/// Shared accessibility helpers for Kinetic surfaces (Progress, Workout, Templates).
enum KineticAccessibility {
    /// Tab / segment transitions when Reduce Motion is off.
    static func contentAnimation(reduceMotion: Bool, duration: Double = 0.2) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: duration)
    }

    /// Slightly longer animation for segment switches on Templates.
    static func segmentAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.3)
    }
}

extension View {
    /// Caps Dynamic Type so fixed Kinetic layouts remain usable on phone-sized screens.
    func kineticDynamicTypeClamp() -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
