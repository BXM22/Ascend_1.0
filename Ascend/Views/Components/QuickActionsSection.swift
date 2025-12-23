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
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text("Quick Actions")
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.foreground)
                .padding(.horizontal, 20)
            
            VStack(spacing: AppSpacing.md) {
                // Primary Action Button
                VStack(spacing: 0) {
                    Button(action: {
                        HapticManager.impact(style: .medium)
                        if programViewModel.activeProgram != nil {
                            // Start next program workout
                            if let nextTemplate = programViewModel.nextProgramWorkout() {
                                workoutViewModel.startWorkoutFromTemplate(nextTemplate)
                                onStartWorkout()
                            }
                        } else {
                            // Show generate dialog
                            showGenerateTypeDialog = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: primaryActionIcon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(primaryActionTitle)
                                .font(AppTypography.bodyBold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.lg)
                        .background(
                            LinearGradient.primaryGradient
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(primaryActionTitle)
                .padding(.horizontal, 20)
                
                // Next Workout Preview (if program active)
                    if let preview = nextWorkoutPreview, !preview.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("Next: \(preview.dayName)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            HStack(spacing: 4) {
                                ForEach(preview.exercises.prefix(3), id: \.self) { exercise in
                                    Text(exercise)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(1)
                                    
                                    if exercise != preview.exercises.last {
                                        Text("•")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                    }
                                }
                                
                                if preview.exercises.count > 3 {
                                    Text("+\(preview.exercises.count - 3) more")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.secondary.opacity(0.3))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, AppSpacing.xs)
                    }
                }
                
                // Favorite Templates (Horizontal Scroll)
                if !favoriteTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Templates")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                    }
                    .padding(.top, AppSpacing.sm)
                }
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
    
    private var muscleGroupColor: Color {
        let (primaryGroups, _) = ExerciseDataManager.shared.getMuscleGroups(for: template.name)
        // Map muscle group to color
        if let primaryGroup = primaryGroups.first {
            switch primaryGroup.lowercased() {
            case "chest", "pectorals": return .blue
            case "back", "lats": return .green
            case "legs", "quadriceps", "hamstrings", "glutes": return .purple
            case "arms", "biceps", "triceps": return .orange
            case "shoulders", "deltoids": return .red
            case "core", "abdominals", "abs": return .yellow
            default: return AppColors.accent
            }
        }
        return AppColors.accent
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(muscleGroupColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(muscleGroupColor)
                }
                
                // Template Name
                Text(template.name)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 100, alignment: .leading)
                
                // Exercise Count
                Text("\(template.exercises.count) exercises")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.secondary)
            }
            .frame(width: 120)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
            )
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
