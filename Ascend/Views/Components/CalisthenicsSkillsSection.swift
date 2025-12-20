import SwiftUI

struct CalisthenicsSkillsSection: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var skillManager: CalisthenicsSkillManager = CalisthenicsSkillManager.shared
    let onStart: () -> Void
    @State private var selectedSkill: CalisthenicsSkill?
    @State private var showSkillDetail = false
    @State private var showCreateCustomSkill = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Calisthenics Skills")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            
            // Add Skill Button (full-width at top)
            Button(action: {
                showCreateCustomSkill = true
                HapticManager.impact(style: .medium)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create Custom Skill")
                        .font(AppTypography.bodyBold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .accessibilityLabel("Create new calisthenics skill")
            
            if skillManager.skills.isEmpty {
                // Empty state
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.primary.opacity(0.6))
                    
                    Text("No Skills Yet")
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Calisthenics skills will appear here")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // List view matching Templates View
                ForEach(skillManager.skills, id: \.id) { skill in
                    CalisthenicsSkillCard(
                        skill: skill,
                        skillManager: skillManager,
                        onTap: {
                            selectedSkill = skill
                            showSkillDetail = true
                            HapticManager.impact(style: .light)
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if skill.isCustom {
                            Button(role: .destructive) {
                                skillManager.deleteCustomSkill(skill)
                                HapticManager.success()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete \(skill.name)")
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showCreateCustomSkill) {
            CreateCustomSkillView(skillManager: skillManager)
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
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: skill.name)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: skill.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(gradient)
                }
                
                // Skill Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(skill.name)
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.foreground)
                            .lineLimit(1)
                        
                        // Custom indicator
                        if skill.isCustom {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .accessibilityLabel(skill.name)
                    
                    HStack(spacing: 8) {
                        Label("\(skill.progressionLevels.count) levels", systemImage: "chart.bar.fill")
                            .font(AppTypography.caption)
                        
                        Text("•")
                        
                        Text(skill.category.rawValue)
                            .font(AppTypography.caption)
                            .foregroundStyle(gradient)
                    }
                    .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Quick action button
                Button(action: onTap) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(gradient)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Start \(skill.name)")
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
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

