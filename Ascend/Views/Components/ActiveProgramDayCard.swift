//
//  ActiveProgramDayCard.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Card showing the current day's workout from an active program
struct ActiveProgramDayCard: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    
    private var activeProgramInfo: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)? {
        guard let active = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == active.programId }),
              let currentDay = programViewModel.getCurrentDay(for: program) else {
            return nil
        }
        
        let dayIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        return (program, currentDay, dayIndex)
    }
    
    var body: some View {
        if let info = activeProgramInfo {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Workout")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                        
                        Text(info.currentDay.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text(info.program.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Day indicator
                    VStack(spacing: 4) {
                        Text("Day")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                        
                        Text("\(info.dayIndex + 1)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Exercises preview
                if !info.currentDay.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercises")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(info.currentDay.exercises.prefix(4), id: \.id) { exercise in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(AppColors.primary.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(exercise.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    Spacer()
                                    
                                    Text("\(exercise.sets) sets")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.foreground.opacity(0.7))
                                }
                            }
                            
                            if info.currentDay.exercises.count > 4 {
                                Text("+\(info.currentDay.exercises.count - 4) more exercises")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.foreground.opacity(0.7))
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
                
                // Start button
                Button(action: {
                    HapticManager.impact(style: .medium)
                    if let templateId = info.currentDay.templateId,
                       let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                        templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                        onStartWorkout()
                    } else if !info.currentDay.exercises.isEmpty {
                        startProgramDay(info.currentDay, programName: info.program.name)
                        onStartWorkout()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Start Workout")
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func startProgramDay(_ day: WorkoutDay, programName: String) {
        let exercises = day.exercises.map { programExercise in
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: programExercise.name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: programExercise.name)
            
            return Exercise(
                name: programExercise.name,
                targetSets: programExercise.sets,
                exerciseType: programExercise.exerciseType,
                holdDuration: programExercise.targetHoldDuration,
                alternatives: alternatives,
                videoURL: videoURL
            )
        }
        
        workoutViewModel.currentWorkout = Workout(name: "\(programName) - \(day.name)", exercises: exercises)
        workoutViewModel.currentExerciseIndex = 0
        workoutViewModel.startTimer()
    }
}


