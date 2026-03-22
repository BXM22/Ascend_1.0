//
//  ActiveProgramDayWorkoutStart.swift
//  Ascend
//
//  Shared start flow for the current day of an active program (dashboard + program card).
//

import Foundation

enum ActiveProgramDayWorkoutStart {
    /// Starts the workout for the given program day (template, inline exercises, or generate).
    static func start(
        program: WorkoutProgram,
        currentDay: WorkoutDay,
        programViewModel: WorkoutProgramViewModel,
        templatesViewModel: TemplatesViewModel,
        workoutViewModel: WorkoutViewModel,
        onWorkoutReady: @escaping () -> Void,
        onGeneratedTemplate: ((String, WorkoutIntensity) -> Void)? = nil
    ) {
        if let templateId = currentDay.templateId {
            let template = CardDetailCacheManager.shared.getCachedTemplate(templateId)
                ?? templatesViewModel.templates.first(where: { $0.id == templateId })
            if let template = template {
                if CardDetailCacheManager.shared.getCachedTemplate(templateId) == nil {
                    CardDetailCacheManager.shared.cacheTemplate(template)
                }
                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                onWorkoutReady()
            } else {
                generateAndStart(
                    program: program,
                    programViewModel: programViewModel,
                    templatesViewModel: templatesViewModel,
                    workoutViewModel: workoutViewModel,
                    onWorkoutReady: onWorkoutReady,
                    onGeneratedTemplate: onGeneratedTemplate
                )
            }
        } else if !currentDay.exercises.isEmpty {
            startProgramDay(currentDay, programName: program.name, workoutViewModel: workoutViewModel)
            onWorkoutReady()
        } else {
            generateAndStart(
                program: program,
                programViewModel: programViewModel,
                templatesViewModel: templatesViewModel,
                workoutViewModel: workoutViewModel,
                onWorkoutReady: onWorkoutReady,
                onGeneratedTemplate: onGeneratedTemplate
            )
        }
    }

    private static func generateAndStart(
        program: WorkoutProgram,
        programViewModel: WorkoutProgramViewModel,
        templatesViewModel: TemplatesViewModel,
        workoutViewModel: WorkoutViewModel,
        onWorkoutReady: @escaping () -> Void,
        onGeneratedTemplate: ((String, WorkoutIntensity) -> Void)?
    ) {
        guard let active = programViewModel.activeProgram else { return }

        let currentDayIndex = active.getCurrentDayIndex(totalDays: program.days.count)

        guard let result = programViewModel.ensureTemplateForDay(
            dayIndex: currentDayIndex,
            inProgram: program.id,
            settings: templatesViewModel.generationSettings,
            templatesViewModel: templatesViewModel
        ) else {
            Logger.error(
                "ActiveProgramDayWorkoutStart: ensureTemplateForDay returned nil (day \(currentDayIndex))",
                category: .general
            )
            return
        }

        if result.wasGenerated {
            onGeneratedTemplate?(result.template.name, result.intensity)
        }

        templatesViewModel.startTemplate(result.template, workoutViewModel: workoutViewModel)

        if workoutViewModel.currentWorkout != nil {
            onWorkoutReady()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if workoutViewModel.currentWorkout != nil {
                    onWorkoutReady()
                } else {
                    Logger.error("ActiveProgramDayWorkoutStart: workout not set after start", category: .general)
                }
            }
        }
    }

    private static func startProgramDay(_ day: WorkoutDay, programName: String, workoutViewModel: WorkoutViewModel) {
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
