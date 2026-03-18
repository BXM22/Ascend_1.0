//
//  QuickActionsSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Quick actions section with primary workout button and template shortcuts
struct QuickActionsSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    
    @State private var showGenerateTypeDialog = false
    
    private enum GeneratedDayType {
        case custom, push, pull, legs, fullBody
    }
    
    private func generateAndStartWorkout(for type: GeneratedDayType) {
        let template: WorkoutTemplate
        switch type {
        case .custom:
            template = templatesViewModel.generateWorkout()
        case .push:
            template = templatesViewModel.generatePushWorkout()
        case .pull:
            template = templatesViewModel.generatePullWorkout()
        case .legs:
            template = templatesViewModel.generateLegWorkout()
        case .fullBody:
            template = templatesViewModel.generateFullBodyWorkout()
        }
        
        workoutViewModel.startWorkoutFromTemplate(template)
        onStartWorkout()
    }
    
    private var favoriteTemplates: [WorkoutTemplate] {
        // Get up to 3 templates (sorted by name for consistency)
        templatesViewModel.templates
            .sorted(by: { $0.name < $1.name })
            .prefix(3)
            .map { $0 }
    }
    
    private var primaryActionTitle: String {
        if let activeProgram = programViewModel.activeProgram,
           let program = programViewModel.programs.first(where: { $0.id == activeProgram.programId }),
           let currentDay = programViewModel.getCurrentDay(for: program) {
            return currentDay.name
        } else if programViewModel.activeProgram != nil {
            return "Continue Program"
        } else if progressViewModel.isRestDay {
            return "Light Activity"
        } else {
            return "Start Workout (Generate)"
        }
    }
    
    private var primaryActionIcon: String {
        if programViewModel.activeProgram != nil {
            return "play.circle.fill"
        } else if progressViewModel.isRestDay {
            return "figure.walk"
        } else {
            return "plus.circle.fill"
        }
    }
    
    private var nextWorkoutPreview: (dayName: String, exercises: [String])? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == activeProgram.programId }),
              let currentDay = programViewModel.getCurrentDay(for: program) else {
            return nil
        }
        
        let exerciseNames = currentDay.exercises.prefix(3).map { $0.name }
        return (currentDay.name, Array(exerciseNames))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Primary Action Button
            Button(action: {
                HapticManager.impact(style: .medium)
                if programViewModel.activeProgram != nil {
                    if let nextTemplate = programViewModel.nextProgramWorkout() {
                        workoutViewModel.startWorkoutFromTemplate(nextTemplate)
                        onStartWorkout()
                    }
                } else {
                    showGenerateTypeDialog = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: primaryActionIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(primaryActionTitle)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(primaryActionTitle)
            .padding(.horizontal, 20)
            
            // Quick Templates
            if !favoriteTemplates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoriteTemplates) { template in
                            QuickTemplateCard(template: template) {
                                HapticManager.impact(style: .light)
                                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                onStartWorkout()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .confirmationDialog("Generate workout", isPresented: $showGenerateTypeDialog, titleVisibility: .visible) {
            Button("Custom") { generateAndStartWorkout(for: .custom) }
            Button("Push") { generateAndStartWorkout(for: .push) }
            Button("Pull") { generateAndStartWorkout(for: .pull) }
            Button("Legs") { generateAndStartWorkout(for: .legs) }
            Button("Full Body") { generateAndStartWorkout(for: .fullBody) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select the day type to auto-generate and start your workout.")
        }
    }
}

/// Compact template card for quick access horizontal scroll
struct QuickTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    private var templateGradient: LinearGradient {
        let name = template.name.lowercased()
        if name.contains("push") || name.contains("chest") {
            return LinearGradient.chestGradient
        } else if name.contains("pull") || name.contains("back") {
            return LinearGradient.backGradient
        } else if name.contains("leg") {
            return LinearGradient.legsGradient
        } else if name.contains("arm") {
            return LinearGradient.armsGradient
        } else if name.contains("core") || name.contains("abs") {
            return LinearGradient.coreGradient
        } else if name.contains("full") || name.contains("body") {
            return LinearGradient.primaryGradient
        } else {
            return LinearGradient.primaryGradient
        }
    }
    
    private var templateIcon: String {
        let name = template.name.lowercased()
        if name.contains("push") || name.contains("chest") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("pull") || name.contains("back") {
            return "figure.climbing"
        } else if name.contains("leg") {
            return "figure.run"
        } else if name.contains("arm") {
            return "figure.flexibility"
        } else if name.contains("core") || name.contains("abs") {
            return "figure.core.training"
        } else {
            return "dumbbell.fill"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(templateGradient.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: templateIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(templateGradient)
                }
                
                Text(template.name)
                    .font(AppTypography.bodySmallMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 32, alignment: .top)
                
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    Text("\(template.exercises.count)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .frame(width: 120, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
            )
            .shadow(color: AppColors.foreground.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(template.name), \(template.exercises.count) exercises")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        QuickActionsSection(
            progressViewModel: ProgressViewModel(),
            workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager(), progressViewModel: ProgressViewModel()),
            templatesViewModel: TemplatesViewModel(),
            programViewModel: WorkoutProgramViewModel(),
            onStartWorkout: {}
        )
    }
    .background(AppColors.background)
}
