import SwiftUI

/// Compact chip used in the horizontal master exercise list.
struct ExerciseChip: View {
    let exercise: Exercise
    let isCurrent: Bool
    let workingSetsCompleted: Int
    let targetSets: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var progressText: String {
        guard targetSets > 0 else { return "\(workingSetsCompleted)" }
        return "\(workingSetsCompleted)/\(targetSets)"
    }
    
    private var isCompleted: Bool {
        targetSets > 0 && workingSetsCompleted >= targetSets
    }
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isCurrent ? AppColors.alabasterGrey : AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 4)
                    
                    // Quick delete button (only shows on completed or non-current chips)
                    Button(role: .destructive, action: {
                        HapticManager.impact(style: .light)
                        onDelete()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.textSecondary.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 11))
                    
                    Text(progressText)
                        .font(.system(size: 11, weight: .medium))
                    
                    Spacer(minLength: 0)
                }
                .foregroundColor(isCurrent ? AppColors.alabasterGrey.opacity(0.9) : AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                ZStack {
                    if isCurrent {
                        LinearGradient.primaryGradient
                    } else {
                        AppColors.card
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCurrent ? AppColors.primary.opacity(0.9) : AppColors.border.opacity(0.4),
                        lineWidth: isCurrent ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.foreground.opacity(isCurrent ? 0.18 : 0.08), radius: isCurrent ? 10 : 4, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseChip(
        exercise: Exercise(name: "Bench Press", targetSets: 4, exerciseType: .weightReps),
        isCurrent: true,
        workingSetsCompleted: 2,
        targetSets: 4,
        onTap: {},
        onDelete: {}
    )
    .padding()
    .background(AppColors.background)
}

