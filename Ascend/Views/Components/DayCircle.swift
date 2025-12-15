import SwiftUI

struct DayCircle: View {
    let letter: String
    let isToday: Bool
    let hasWorkout: Bool
    let intensity: WorkoutIntensity?
    let progress: Double // 0.0 to 1.0
    let onTap: (() -> Void)?
    
    init(
        letter: String,
        isToday: Bool,
        hasWorkout: Bool,
        intensity: WorkoutIntensity? = nil,
        progress: Double = 0.0,
        onTap: (() -> Void)? = nil
    ) {
        self.letter = letter
        self.isToday = isToday
        self.hasWorkout = hasWorkout
        self.intensity = intensity
        self.progress = progress
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap?()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(fillColor)
                    .frame(width: circleSize, height: circleSize)
                
                // Progress ring (only for days with workouts)
                if hasWorkout {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progressRingColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: circleSize + 6, height: circleSize + 6)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
                
                // Intensity indicator (small badge at top-right)
                if let intensity = intensity, hasWorkout {
                    Circle()
                        .fill(intensityColor(for: intensity))
                        .frame(width: 8, height: 8)
                        .offset(x: circleSize / 2 - 2, y: -circleSize / 2 + 2)
                }
                
                // Border for today
                if isToday {
                    Circle()
                        .strokeBorder(LinearGradient.primaryGradient, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                }
                
                // Day letter
                Text(letter)
                    .font(.system(size: fontSize, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
            }
            .frame(width: circleSize + 6, height: circleSize + 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var circleSize: CGFloat {
        isToday ? 44 : 40
    }
    
    private var fontSize: CGFloat {
        isToday ? 16 : 14
    }
    
    private var fillColor: Color {
        if hasWorkout {
            return AppColors.accent.opacity(0.9)
        } else {
            return AppColors.secondary.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        if hasWorkout {
            return AppColors.onPrimary
        } else if isToday {
            return AppColors.textPrimary
        } else {
            return AppColors.mutedForeground
        }
    }
    
    private func intensityColor(for intensity: WorkoutIntensity) -> Color {
        switch intensity {
        case .light:
            return AppColors.success
        case .moderate:
            return AppColors.primary
        case .intense:
            return AppColors.warning
        case .extreme:
            return AppColors.destructive
        }
    }
    
    private var progressRingColor: Color {
        if let intensity = intensity {
            return intensityColor(for: intensity)
        }
        return AppColors.accent
    }
}

