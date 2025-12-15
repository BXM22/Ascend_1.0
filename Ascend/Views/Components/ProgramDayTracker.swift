import SwiftUI

struct ProgramDayTracker: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    
    var activeProgramInfo: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)? {
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
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                    Text("Current Program")
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                
                // Program Info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(info.program.name)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let splitType = info.program.splitType {
                        Text(splitType.description)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Day Progress
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    let progress = Double(info.dayIndex + 1) / Double(info.program.days.count)
                    
                    HStack {
                        Text("Day \(info.dayIndex + 1) of \(info.program.days.count)")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        // Progress indicator
                        Text("\(Int(progress * 100))%")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.accent)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.secondary)
                                .frame(height: 6)
                                .clipShape(Capsule())
                            
                            Rectangle()
                                .fill(LinearGradient.primaryGradient)
                                .frame(width: geometry.size.width * progress, height: 6)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(height: 6)
                }
                
                // Current Day Info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    if info.currentDay.isRestDay {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(AppColors.textSecondary)
                            Text("Rest Day")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .italic()
                        }
                    } else {
                        HStack {
                            Text(info.currentDay.name)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if let templateId = info.currentDay.templateId,
                               let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                                Button(action: {
                                    templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                    onStartWorkout()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.circle.fill")
                                        Text("Start")
                                    }
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(AppColors.accent)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.accent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            } else if !info.currentDay.exercises.isEmpty {
                                Button(action: {
                                    startProgramDay(info.currentDay, programName: info.program.name)
                                    onStartWorkout()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.circle.fill")
                                        Text("Start")
                                    }
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(AppColors.accent)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.accent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                
                // Week Overview
                if info.program.splitType != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(Array(info.program.days.enumerated()), id: \.element.id) { index, day in
                                DayIndicator(
                                    day: day,
                                    dayNumber: index + 1,
                                    isCurrent: index == info.dayIndex,
                                    isCompleted: programViewModel.isDayCompleted(index, inProgram: info.program.id)
                                )
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.foreground.opacity(0.3), radius: 8, x: 0, y: 4)
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

struct DayIndicator: View {
    let day: WorkoutDay
    let dayNumber: Int
    let isCurrent: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day.isRestDay ? "R" : "\(dayNumber)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isCurrent ? AppColors.alabasterGrey : (isCompleted ? AppColors.accent : AppColors.textPrimary))
            
            Text(day.name.components(separatedBy: " ").first ?? "")
                .font(.system(size: 8))
                .foregroundColor(isCurrent ? AppColors.alabasterGrey.opacity(0.8) : AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 40, height: 50)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Group {
                if isCurrent {
                    LinearGradient.primaryGradient
                } else if isCompleted {
                    AppColors.accent.opacity(0.1)
                } else {
                    AppColors.secondary
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.clear : AppColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

