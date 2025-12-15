import SwiftUI

struct HeroSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    let onGenerateWorkout: () -> Void
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    private var hasWorkedOutToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return progressViewModel.workoutDates.contains { 
            calendar.startOfDay(for: $0) == today
        } || progressViewModel.restDays.contains {
            calendar.startOfDay(for: $0) == today
        }
    }
    
    private var todayStatusText: String {
        if hasWorkedOutToday {
            return "Great work today! 🔥"
        } else if progressViewModel.currentStreak > 0 {
            return "Keep your \(progressViewModel.currentStreak)-day streak going!"
        } else {
            return "Ready to start your journey?"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Greeting and Status
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(todayStatusText)
                    .font(AppTypography.heading1)
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Quick Stats Row
            HStack(spacing: 16) {
                // Streak Card
                QuickStatCard(
                    icon: "flame.fill",
                    value: "\(progressViewModel.currentStreak)",
                    label: progressViewModel.currentStreak == 1 ? "Day Streak" : "Day Streak",
                    gradient: LinearGradient(
                        colors: [Color(hex: "ff6b35"), Color(hex: "f7931e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Workout Count Card
                QuickStatCard(
                    icon: "dumbbell.fill",
                    value: "\(progressViewModel.workoutCount)",
                    label: progressViewModel.workoutCount == 1 ? "Workout" : "Workouts",
                    gradient: LinearGradient.primaryGradient
                )
            }
            
            // Generate Workout Button
            Button(action: {
                HapticManager.impact(style: .medium)
                onGenerateWorkout()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Generate Workout")
                        .font(AppTypography.heading4)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    LinearGradient.primaryGradient
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: AppColors.primary.opacity(0.4),
                    radius: 20,
                    x: 0,
                    y: 8
                )
                .shadow(
                    color: AppColors.primary.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(HeroButtonStyle())
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(AppColors.background)
        )
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(gradient)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(gradient.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct HeroButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .brightness(configuration.isPressed ? -0.1 : (isHovered ? 0.05 : 0))
            .animation(AppAnimations.quick, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
    }
}

#Preview {
    HeroSection(
        progressViewModel: ProgressViewModel(),
        onGenerateWorkout: {}
    )
    .background(AppColors.background)
}

