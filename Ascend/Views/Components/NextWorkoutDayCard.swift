//
//  NextWorkoutDayCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct NextWorkoutDayCard: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    
    private var nextWorkoutInfo: (program: WorkoutProgram, day: WorkoutDay, dayNumber: Int)? {
        guard let active = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == active.programId }) else {
            return nil
        }
        
        // Get the next day index (current day + 1, wrapping around)
        let currentIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        let nextIndex = (currentIndex + 1) % program.days.count
        
        guard nextIndex < program.days.count else { return nil }
        let nextDay = program.days[nextIndex]
        
        return (program, nextDay, nextIndex + 1)
    }
    
    var body: some View {
        if let info = nextWorkoutInfo {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Workout")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text("Day \(info.dayNumber): \(info.day.name)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LinearGradient.primaryGradient)
                    }
                    
                    Spacer()
                    
                    // Calendar icon
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                // Exercises preview
                if let template = templatesViewModel.templates.first(where: { $0.id == info.day.templateId }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.mutedForeground)
                            .textCase(.uppercase)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(template.exercises.prefix(3), id: \.id) { exercise in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(AppColors.primary.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(exercise.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                        .lineLimit(1)
                                }
                            }
                            
                            if template.exercises.count > 3 {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(AppColors.mutedForeground.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                    
                                    Text("+\(template.exercises.count - 3) more exercises")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                            }
                        }
                    }
                }
                
                // Start button
                Button(action: {
                    // Start the workout from the next day's template
                    if let template = templatesViewModel.templates.first(where: { $0.id == info.day.templateId }) {
                        workoutViewModel.startWorkoutFromTemplate(template)
                        HapticManager.success()
                        onStartWorkout()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Start Next Workout")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(LinearGradient.primaryGradient.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }
}

#Preview {
    NextWorkoutDayCard(
        programViewModel: WorkoutProgramViewModel(),
        templatesViewModel: TemplatesViewModel(),
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        onStartWorkout: {}
    )
    .padding()
    .background(AppColors.background)
}

