import SwiftUI

struct CalisthenicsSkillsSection: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStart: () -> Void
    @State private var selectedSkill: CalisthenicsSkill?
    @State private var showSkillDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Calisthenics Skills")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Master advanced bodyweight movements")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(CalisthenicsSkillManager.shared.skills) { skill in
                        CalisthenicsSkillCard(
                            skill: skill,
                            onTap: {
                                selectedSkill = skill
                                showSkillDetail = true
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .sheet(isPresented: $showSkillDetail) {
            NavigationView {
                if let skill = selectedSkill {
                    CalisthenicsSkillView(
                        skill: skill,
                        workoutViewModel: workoutViewModel
                    )
                    .navigationTitle(skill.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSkillDetail = false
                            }
                            .foregroundColor(AppColors.primary)
                        }
                    }
                    .onChange(of: workoutViewModel.currentWorkout) { _, newValue in
                        if newValue != nil {
                            // Workout started, close sheet and navigate
                            showSkillDetail = false
                            onStart()
                        }
                    }
                }
            }
        }
    }
}

struct CalisthenicsSkillCard: View {
    let skill: CalisthenicsSkill
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Spacer()
                    
                    Text(skill.category.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.secondary)
                        .clipShape(Capsule())
                }
                
                Text(skill.name)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text("\(skill.progressionLevels.count) levels")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                // Progress indicator
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < min(3, skill.progressionLevels.count) ? AppColors.primary : AppColors.secondary)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(AppSpacing.md)
            .frame(width: 200)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalisthenicsSkillsSection(
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        onStart: {}
    )
    .padding()
    .background(AppColors.background)
}

