import SwiftUI

struct CalisthenicsSkillsSection: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var skillManager: CalisthenicsSkillManager = CalisthenicsSkillManager.shared
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
                    ForEach(skillManager.skills) { skill in
                        CalisthenicsSkillCard(
                            skill: skill,
                            skillManager: skillManager,
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
                        workoutViewModel: workoutViewModel,
                        templatesViewModel: templatesViewModel
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
    @ObservedObject var skillManager: CalisthenicsSkillManager
    let onTap: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            GradientBorderedCard(gradient: AppColors.categoryGradient(for: skill.name)) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        // Custom indicator badge
                        if skill.isCustom {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.primary)
                        }
                        
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
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(2)
                    
                    Text("\(skill.progressionLevels.count) levels")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
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
            }
            .frame(width: 170, height: 170)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if skill.isCustom {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Skill", systemImage: "trash")
                }
            }
        }
        .alert("Delete Custom Skill?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                skillManager.deleteCustomSkill(skill)
            }
        } message: {
            Text("Are you sure you want to delete \"\(skill.name)\"? This action cannot be undone.")
        }
    }
}

#Preview {
    CalisthenicsSkillsSection(
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        templatesViewModel: TemplatesViewModel(),
        onStart: {}
    )
    .padding()
    .background(AppColors.background)
}

