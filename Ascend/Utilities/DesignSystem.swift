//
//  DesignSystem.swift
//  Ascend
//
//  Professional design system for consistent UI
//

import SwiftUI

// Note: AppSpacing is defined in Theme/Spacing.swift
// Note: AppTypography is defined in Theme/Typography.swift
// Note: AppAnimations is defined in Theme/Animations.swift

// MARK: - Shadow System
struct AppShadow {
    // Subtle elevation
    static let subtle = Shadow(
        color: Color.black.opacity(0.04),
        radius: 2,
        x: 0,
        y: 1
    )
    
    // Medium elevation
    static let medium = Shadow(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )
    
    // Prominent elevation
    static let prominent = Shadow(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )
    
    // Floating (for modals, sheets)
    static let floating = Shadow(
        color: Color.black.opacity(0.16),
        radius: 24,
        x: 0,
        y: 12
    )
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Corner Radius System
enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let xxlarge: CGFloat = 24
    static let round: CGFloat = 999 // For fully rounded elements
}

// MARK: - View Extensions for Design System
extension View {
    // Apply shadow levels
    func applyShadow(_ shadow: AppShadow.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    // Apply multiple shadows for depth
    @ViewBuilder
    func applyElevation(_ level: ElevationLevel) -> some View {
        switch level {
        case .subtle:
            self.shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        case .medium:
            self
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        case .prominent:
            self
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
        case .floating:
            self
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)
        }
    }
}

enum ElevationLevel {
    case subtle, medium, prominent, floating
}

// Note: animateOnAppear is defined in Theme/Animations.swift
// Note: AnimateOnAppearModifier is defined in Theme/Animations.swift

// MARK: - Input Field Style (HIG-Compliant)
struct InputFieldStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(AppColors.input)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func inputFieldStyle() -> some View {
        self.modifier(InputFieldStyle())
    }
    
    // Keep neumorphic for backwards compatibility but make it HIG-compliant
    func neumorphic(isPressed: Bool = false) -> some View {
        self.modifier(InputFieldStyle())
    }
}

// MARK: - Glassmorphic Style
struct GlassmorphicStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
    }
}

extension View {
    func glassmorphic() -> some View {
        self.modifier(GlassmorphicStyle())
    }
}

// Note: ScaleButtonStyle is defined in WorkoutView.swift

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

