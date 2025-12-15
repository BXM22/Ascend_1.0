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
    
    // Card entrance animations (staggered appearance)
    static let cardEntrance = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // Celebration animations (bouncy for achievements)
    static let celebration = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // Bouncy animation for playful interactions
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // Snappy animation for quick transitions
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    
    // List item animations (staggered entrance)
    static let listItem = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    // Shimmer effect for loading states
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
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
    
    // Slide from bottom for sheet presentations
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    // Scale with fade for modal appearances
    static var scaleWithFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
    }
    
    // Card flip for card interactions
    static var cardFlip: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 1.05).combined(with: .opacity)
        )
    }
}

// MARK: - Reusable View Modifiers
extension View {
    /// Animates view appearance with optional delay for staggered effects
    func animateOnAppear(delay: Double = 0, animation: Animation = AppAnimations.cardEntrance) -> some View {
        self.modifier(AnimateOnAppearModifier(delay: delay, animation: animation))
    }
    
    /// Adds a pulse effect for attention-grabbing elements
    func pulseEffect(scale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PulseEffectModifier(scale: scale, duration: duration))
    }
    
    /// Adds a shimmer effect for loading states
    func shimmerEffect() -> some View {
        self.modifier(ShimmerEffectModifier())
    }
}

// MARK: - Animation Modifiers
struct AnimateOnAppearModifier: ViewModifier {
    let delay: Double
    let animation: Animation
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }
}

struct PulseEffectModifier: ViewModifier {
    let scale: CGFloat
    let duration: Double
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

struct ShimmerEffectModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(AppAnimations.shimmer) {
                    phase = 200
                }
            }
    }
}

// MARK: - Button Styles
struct SubtleButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.85 : (isHovered ? 0.95 : 1.0))
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.impact(style: .light)
                }
            }
    }
}

struct CardButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
            .brightness(configuration.isPressed ? -0.03 : (isHovered ? 0.02 : 0))
            .shadow(
                color: configuration.isPressed ? Color.black.opacity(0.1) : (isHovered ? Color.black.opacity(0.15) : Color.black.opacity(0.12)),
                radius: configuration.isPressed ? 4 : (isHovered ? 6 : 5),
                x: 0,
                y: configuration.isPressed ? 2 : (isHovered ? 3 : 2)
            )
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.impact(style: .light)
                }
            }
    }
}

