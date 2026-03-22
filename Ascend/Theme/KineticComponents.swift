import SwiftUI

// MARK: - Elevation (DESIGN.md §4 Ambient Shadows)

/// Ambient shadow tint — `on-surface`–style light gray (§4), not pure black.
enum KineticElevation {
    static let ambientTint = Color(hex: "e4e2e1")
    
    /// FAB / modal — blur 40–60pt, opacity 4–8% (use with `.shadow`).
    static func ambientShadow(radius: CGFloat = 48, opacity: Double = 0.06) -> (color: Color, radius: CGFloat) {
        (ambientTint.opacity(opacity), radius)
    }
}

// MARK: - Glassmorphism (§2 — surface 60–80% + blur)

struct KineticGlassBackground: View {
    var surfaceOpacity: Double = 0.72
    
    var body: some View {
        AppColors.surface.opacity(surfaceOpacity)
            .background(.ultraThinMaterial)
    }
}

extension View {
    /// Floating bar / modal header — material + tinted surface (blur via system material).
    func kineticGlassBarSurface(opacity: Double = 0.72) -> some View {
        background {
            KineticGlassBackground(surfaceOpacity: opacity)
        }
    }
}
