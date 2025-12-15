import SwiftUI

struct WorkoutDayDetailSheet: View {
    let workoutDay: WorkoutDay
    let date: Date
    let intensity: WorkoutIntensity
    let isCompleted: Bool
    @Environment(\.dismiss) var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private var exerciseCount: Int {
        // Filter out warm-up exercises
        workoutDay.exercises.filter { 
            !($0.notes?.lowercased().contains("warm-up") ?? false) 
        }.count
    }
    
    private var intensityColor: Color {
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(dateString)
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(workoutDay.name)
                                    .font(AppTypography.heading2)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if !workoutDay.description.isEmpty {
                                    Text(workoutDay.description)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Completion indicator
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .padding(.bottom, AppSpacing.sm)
                    
                    // Summary Cards
                    HStack(spacing: AppSpacing.md) {
                        // Exercise Count
                        SummaryCard(
                            icon: "dumbbell.fill",
                            value: "\(exerciseCount)",
                            label: exerciseCount == 1 ? "Exercise" : "Exercises",
                            color: AppColors.primary
                        )
                        
                        // Duration
                        if workoutDay.estimatedDuration > 0 {
                            SummaryCard(
                                icon: "clock.fill",
                                value: "\(workoutDay.estimatedDuration)",
                                label: "Minutes",
                                color: AppColors.accent
                            )
                        }
                    }
                    
                    // Intensity Badge
                    HStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(intensityColor)
                            .frame(width: 12, height: 12)
                        
                        Text(intensity.rawValue)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(intensity.description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.horizontal, AppSpacing.md)
                    .background(intensityColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Rest Day Message
                    if workoutDay.isRestDay {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accent)
                            
                            Text("Rest Day")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppSpacing.lg)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}


