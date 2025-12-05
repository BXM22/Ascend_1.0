import SwiftUI

struct CalisthenicsSkillView: View {
    let skill: CalisthenicsSkill
    @State private var selectedLevel: Int = 1
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @Environment(\.dismiss) var dismiss
    
    var currentLevel: SkillProgressionLevel {
        skill.progressionLevels.first { $0.level == selectedLevel } ?? skill.progressionLevels[0]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Skill Header
                SkillHeader(skill: skill)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                
                // Video Tutorial
                if let videoURL = skill.videoURL {
                    VideoTutorialButton(videoURL: videoURL, exerciseName: skill.name)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                // Progression Levels
                ProgressionLevelsView(
                    skill: skill,
                    selectedLevel: $selectedLevel
                )
                .padding(.horizontal, AppSpacing.lg)
                
                // Current Level Details
                CurrentLevelCard(level: currentLevel)
                    .padding(.horizontal, AppSpacing.lg)
                
                // Start Workout Button
                Button(action: {
                    startSkillWorkout()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(AppTypography.bodyBold)
                        Text("Start \(skill.name) Training")
                            .font(AppTypography.bodyBold)
                    }
                    .foregroundColor(AppColors.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 100)
            }
        }
        .background(AppColors.background)
    }
    
    private func startSkillWorkout() {
        let level = currentLevel
        let exerciseName = "\(skill.name) - \(level.name)"
        
        // Determine exercise type based on level
        let exerciseType: ExerciseType = level.targetHoldDuration != nil ? .hold : .weightReps
        let holdDuration = level.targetHoldDuration
        
        // Start workout
        if workoutViewModel.currentWorkout == nil {
            workoutViewModel.startWorkout(name: "\(skill.name) Training")
        }
        
        workoutViewModel.addExercise(
            name: exerciseName,
            targetSets: 3,
            type: exerciseType,
            holdDuration: holdDuration
        )
        
        // Close the sheet and navigate to workout
        dismiss()
    }
}

struct SkillHeader: View {
    let skill: CalisthenicsSkill
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(skill.name)
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(skill.category.rawValue)
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.secondary)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            Text(skill.description)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct ProgressionLevelsView: View {
    let skill: CalisthenicsSkill
    @Binding var selectedLevel: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Progression Levels")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(selectedLevel)/\(skill.progressionLevels.count)")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(skill.progressionLevels) { level in
                    ProgressionLevelCard(
                        level: level,
                        isSelected: selectedLevel == level.level,
                        onTap: {
                            selectedLevel = level.level
                        }
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct ProgressionLevelCard: View {
    let level: SkillProgressionLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Level Number
                Text("\(level.level)")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(isSelected ? AppColors.accentForeground : AppColors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? AppColors.primary : AppColors.secondary)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(level.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(level.description)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CurrentLevelCard: View {
    let level: SkillProgressionLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Current Level")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Level \(level.level):")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(level.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(level.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                
                if let holdDuration = level.targetHoldDuration {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(AppColors.accent)
                        Text("Target Hold: \(holdDuration) seconds")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if let reps = level.targetReps {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(AppColors.accent)
                        Text("Target Reps: \(reps) per set")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(LinearGradient.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    CalisthenicsSkillView(
        skill: CalisthenicsSkillManager.shared.skills[0],
        workoutViewModel: WorkoutViewModel()
    )
}

