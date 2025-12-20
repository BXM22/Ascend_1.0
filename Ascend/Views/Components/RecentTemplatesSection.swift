//
//  RecentTemplatesSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Section displaying top 3 most recently used templates
struct RecentTemplatesSection: View {
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    
    private var recentTemplates: [WorkoutTemplate] {
        let historyManager = WorkoutHistoryManager.shared
        let recentWorkouts = Array(historyManager.completedWorkouts.prefix(20)) // Last 20 workouts
        
        // Extract template names from recent workouts
        let recentWorkoutNames = Set(recentWorkouts.map { $0.name })
        
        // Match templates to recent workouts by name
        var matchedTemplates: [WorkoutTemplate] = []
        var unmatchedTemplates: [WorkoutTemplate] = []
        
        for template in templatesViewModel.templates {
            // Check if template name matches any recent workout name
            let isRecent = recentWorkoutNames.contains { workoutName in
                workoutName.contains(template.name) || template.name.contains(workoutName)
            }
            
            if isRecent {
                matchedTemplates.append(template)
            } else {
                unmatchedTemplates.append(template)
            }
        }
        
        // Sort matched templates by most recent (prioritize those that appear in more recent workouts)
        matchedTemplates.sort { template1, template2 in
            let index1 = recentWorkouts.firstIndex { $0.name.contains(template1.name) || template1.name.contains($0.name) } ?? Int.max
            let index2 = recentWorkouts.firstIndex { $0.name.contains(template2.name) || template2.name.contains($0.name) } ?? Int.max
            return index1 < index2
        }
        
        // Combine: recent matches first, then others
        let combined = matchedTemplates + unmatchedTemplates
        
        // Return top 3
        return Array(combined.prefix(3))
    }
    
    var body: some View {
        let templates = recentTemplates
        
        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Section Title
                Text("Recent Templates")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 20)
                
                // Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                            RecentTemplateCard(
                                template: template,
                                isPrimary: index == 0, // First template is most recent/primary
                                onTap: {
                                    HapticManager.impact(style: .light)
                                    workoutViewModel.startWorkoutFromTemplate(template)
                                    onStartWorkout()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

/// Recent template card with hierarchy (darker for most recent)
struct RecentTemplateCard: View {
    let template: WorkoutTemplate
    let isPrimary: Bool
    let onTap: () -> Void
    
    private var muscleGroupColor: Color {
        let (primaryGroups, _) = ExerciseDataManager.shared.getMuscleGroups(for: template.name)
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
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isPrimary ? muscleGroupColor.opacity(0.3) : muscleGroupColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isPrimary ? muscleGroupColor : muscleGroupColor.opacity(0.8))
                }
                
                Spacer()
                
                // Template Name
                Text(template.name)
                    .font(.system(size: 15, weight: isPrimary ? .bold : .semibold))
                    .foregroundColor(isPrimary ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Exercise Count
                Text("\(template.exercises.count) exercises")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPrimary ? AppColors.textSecondary : AppColors.mutedForeground)
            }
            .frame(width: 140, height: 160)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPrimary ? AppColors.card : AppColors.secondary.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .shadow(color: isPrimary ? AppColors.foreground.opacity(0.1) : Color.clear, radius: isPrimary ? 8 : 0, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(template.name), \(template.exercises.count) exercises")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        RecentTemplatesSection(
            templatesViewModel: TemplatesViewModel(),
            workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager(), progressViewModel: ProgressViewModel()),
            onStartWorkout: {}
        )
    }
    .background(AppColors.background)
}

