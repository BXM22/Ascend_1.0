import SwiftUI
import Combine

// MARK: - Feature Discovery Manager
/// Tracks which features the user has discovered to avoid showing hints repeatedly
class FeatureDiscoveryManager: ObservableObject {
    static let shared = FeatureDiscoveryManager()
    
    @Published private var updateTrigger = false
    private let userDefaults = UserDefaults.standard
    private let prefix = "feature_discovered_"
    
    enum Feature: String, CaseIterable {
        case longPressExercise = "long_press_exercise"
        case swipeExerciseCard = "swipe_exercise_card"
        case alternativeExercises = "alternative_exercises"
        case quickPresets = "quick_presets"
        case reorderExercises = "reorder_exercises"
        case warmupToggle = "warmup_toggle"
    }
    
    func hasDiscovered(_ feature: Feature) -> Bool {
        userDefaults.bool(forKey: prefix + feature.rawValue)
    }
    
    func markDiscovered(_ feature: Feature) {
        userDefaults.set(true, forKey: prefix + feature.rawValue)
        objectWillChange.send()
    }
    
    func resetAllHints() {
        Feature.allCases.forEach { feature in
            userDefaults.removeObject(forKey: prefix + feature.rawValue)
        }
        objectWillChange.send()
    }
}

// MARK: - Tooltip View
/// A floating tooltip that points to a feature
struct FeatureTooltip: View {
    let message: String
    let icon: String
    var arrowPosition: ArrowPosition = .top
    let onDismiss: () -> Void
    
    enum ArrowPosition {
        case top, bottom, left, right
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if arrowPosition == .top {
                arrow
            }
            
            HStack(spacing: 0) {
                if arrowPosition == .left {
                    arrow
                }
                
                tooltipContent
                
                if arrowPosition == .right {
                    arrow
                }
            }
            
            if arrowPosition == .bottom {
                arrow
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private var tooltipContent: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accent)
            
            Text(message)
                .font(AppTypography.captionMedium)
                .foregroundColor(AppColors.foreground)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .accessibilityLabel("Dismiss hint")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: AppColors.foreground.opacity(0.15), radius: 12, x: 0, y: 4)
    }
    
    private var arrow: some View {
        Triangle()
            .fill(AppColors.card)
            .frame(width: 16, height: 8)
            .rotationEffect(arrowRotation)
    }
    
    private var arrowRotation: Angle {
        switch arrowPosition {
        case .top: return .degrees(0)
        case .bottom: return .degrees(180)
        case .left: return .degrees(-90)
        case .right: return .degrees(90)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Long Press Hint Overlay
/// A subtle pulsing ring to indicate long-press capability
struct LongPressHint: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .stroke(AppColors.primary.opacity(0.3), lineWidth: 2)
            .frame(width: 44, height: 44)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0 : 0.6)
            .animation(
                Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Swipe Indicator
/// A subtle animated indicator showing swipe capability
struct SwipeIndicator: View {
    @State private var offset: CGFloat = 0
    let direction: Direction
    
    enum Direction {
        case left, right, horizontal
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if direction == .left || direction == .horizontal {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground.opacity(0.5))
            }
            
            Image(systemName: "hand.draw")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mutedForeground.opacity(0.6))
                .offset(x: offset)
            
            if direction == .right || direction == .horizontal {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground.opacity(0.5))
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                offset = direction == .left ? -8 : 8
            }
        }
    }
}

// MARK: - Context Menu Hint Badge
/// A small badge indicating more options are available
struct MoreOptionsBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.tap")
                .font(.system(size: 10))
            Text("Hold")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(AppColors.mutedForeground)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(AppColors.secondary)
        .clipShape(Capsule())
    }
}

// MARK: - First Time Hint View Modifier
struct FirstTimeHintModifier: ViewModifier {
    let feature: FeatureDiscoveryManager.Feature
    let message: String
    let icon: String
    @StateObject private var discoveryManager = FeatureDiscoveryManager.shared
    @State private var showHint = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showHint && !discoveryManager.hasDiscovered(feature) {
                    FeatureTooltip(
                        message: message,
                        icon: icon,
                        arrowPosition: .bottom
                    ) {
                        withAnimation(AppAnimations.smooth) {
                            discoveryManager.markDiscovered(feature)
                            showHint = false
                        }
                    }
                    .offset(y: -50)
                    .zIndex(100)
                }
            }
            .onAppear {
                // Show hint after a short delay
                if !discoveryManager.hasDiscovered(feature) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(AppAnimations.smooth) {
                            showHint = true
                        }
                        // Auto-dismiss after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(AppAnimations.smooth) {
                                showHint = false
                            }
                        }
                    }
                }
            }
    }
}

extension View {
    /// Shows a first-time hint for a feature
    func firstTimeHint(
        for feature: FeatureDiscoveryManager.Feature,
        message: String,
        icon: String = "lightbulb.fill"
    ) -> some View {
        modifier(FirstTimeHintModifier(feature: feature, message: message, icon: icon))
    }
}

#Preview {
    VStack(spacing: 40) {
        FeatureTooltip(
            message: "Long press for more options",
            icon: "hand.tap.fill",
            arrowPosition: .bottom
        ) {}
        
        SwipeIndicator(direction: .horizontal)
        
        LongPressHint()
        
        MoreOptionsBadge()
    }
    .padding()
    .background(AppColors.background)
}
