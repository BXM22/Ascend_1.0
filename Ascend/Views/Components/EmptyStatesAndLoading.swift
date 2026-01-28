import SwiftUI

// MARK: - Empty State View
/// A reusable empty state component with customizable content
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var style: Style = .standard
    
    enum Style {
        case standard
        case compact
        case motivational
    }
    
    var body: some View {
        VStack(spacing: style == .compact ? 12 : 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundGradient)
                    .frame(width: iconSize, height: iconSize)
                
                Image(systemName: icon)
                    .font(.system(size: iconFontSize, weight: .semibold))
                    .foregroundStyle(iconGradient)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(style == .compact ? AppTypography.bodyBold : AppTypography.heading4)
                    .foregroundColor(AppColors.foreground)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(style == .compact ? AppTypography.caption : AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(actionTitle)
                            .font(AppTypography.buttonBold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(style == .compact ? 16 : 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
    
    private var iconSize: CGFloat {
        switch style {
        case .standard: return 80
        case .compact: return 56
        case .motivational: return 100
        }
    }
    
    private var iconFontSize: CGFloat {
        switch style {
        case .standard: return 36
        case .compact: return 24
        case .motivational: return 44
        }
    }
    
    private var iconBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.primary.opacity(0.15), AppColors.accent.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconGradient: LinearGradient {
        LinearGradient.primaryGradient
    }
}

// MARK: - No Previous Sets View
struct NoPreviousSetsView: View {
    let exerciseName: String
    
    var body: some View {
        EmptyStateView(
            icon: "list.bullet.clipboard",
            title: "No Sets Yet",
            message: "Complete your first set of \(exerciseName) to see your history here.",
            style: .compact
        )
    }
}

// MARK: - No Exercise History View
struct NoExerciseHistoryView: View {
    var body: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "No History Yet",
            message: "Your workout history will appear here as you complete exercises. Every rep counts!",
            style: .motivational
        )
    }
}

// MARK: - Loading Skeleton View
struct SkeletonView: View {
    @State private var isAnimating = false
    var width: CGFloat = .infinity
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.secondary,
                        AppColors.secondary.opacity(0.5),
                        AppColors.secondary
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(maxWidth: width == .infinity ? nil : width, maxHeight: height)
            .frame(height: height)
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Exercise Card Skeleton
struct ExerciseCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                SkeletonView(width: 120, height: 24, cornerRadius: 12)
                Spacer()
                SkeletonView(width: 24, height: 24, cornerRadius: 12)
            }
            
            // Set indicator
            SkeletonView(width: 100, height: 16, cornerRadius: 8)
            
            // Input placeholders
            VStack(spacing: 12) {
                HStack {
                    SkeletonView(width: 60, height: 14, cornerRadius: 6)
                    Spacer()
                }
                SkeletonView(height: 56, cornerRadius: 12)
            }
            
            VStack(spacing: 12) {
                HStack {
                    SkeletonView(width: 40, height: 14, cornerRadius: 6)
                    Spacer()
                }
                SkeletonView(height: 56, cornerRadius: 12)
            }
            
            // Presets
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonView(width: 44, height: 32, cornerRadius: 16)
                }
            }
            
            // Button
            SkeletonView(height: 52, cornerRadius: 14)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                SwiftUI.ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColors.accent)
                
                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.foreground)
            }
            .padding(24)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.foreground.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading. \(message)")
    }
}

// MARK: - Button Loading State
struct LoadingButton<Label: View>: View {
    let isLoading: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        Button(action: action) {
            ZStack {
                label()
                    .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    SwiftUI.ProgressView()
                        .tint(.white)
                }
            }
        }
        .disabled(isLoading)
    }
}

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 32) {
            EmptyStateView(
                icon: "dumbbell.fill",
                title: "No Exercises Yet",
                message: "Add exercises to start tracking your workout.",
                actionTitle: "Add Exercise"
            ) {}
            
            NoPreviousSetsView(exerciseName: "Bench Press")
            
            NoExerciseHistoryView()
        }
        .padding()
    }
    .background(AppColors.background)
}

#Preview("Skeletons") {
    VStack(spacing: 20) {
        ExerciseCardSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
