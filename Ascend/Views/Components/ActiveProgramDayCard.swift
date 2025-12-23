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
    @State private var showGeneratePrompt = false
    @State private var generatedTemplateInfo: (name: String, intensity: WorkoutIntensity)?
    @State private var cachedTemplate: WorkoutTemplate?
    @State private var hasCheckedForGeneration = false
    
    private var activeProgramInfo: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)? {
        guard let active = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == active.programId }),
              let currentDay = programViewModel.getCurrentDay(for: program) else {
            return nil
        }
        
        let dayIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        return (program, currentDay, dayIndex)
    }
    
    private var currentDayTemplateId: UUID? {
        activeProgramInfo?.currentDay.templateId
    }
    
    var body: some View {
        Group {
            if let info = activeProgramInfo {
                cardContent(for: info)
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func cardContent(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
        let baseContent = VStack(alignment: .leading, spacing: 16) {
            cardHeader(for: info)
            exercisesPreview(for: info.currentDay)
            startButton(for: info)
        }
        .padding(20)
        .background(cardBackground)
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 4)
        
        baseContent
            .onAppear {
                preloadTemplateData()
                checkAndPromptForGeneration()
            }
            .onChange(of: programViewModel.programs.count) { _ in
                hasCheckedForGeneration = false
                checkAndPromptForGeneration()
            }
            .onChange(of: programViewModel.activeProgram?.programId) { _ in
                hasCheckedForGeneration = false
                checkAndPromptForGeneration()
            }
            .onChange(of: currentDayTemplateId) { _ in
                hasCheckedForGeneration = false
                checkAndPromptForGeneration()
            }
            .alert("Generate Workout?", isPresented: $showGeneratePrompt) {
                Button("Cancel", role: .cancel) { }
                Button("Generate") {
                    generateAndStartWorkout()
                }
            } message: {
                generateWorkoutMessage
            }
            .alert("Workout Generated", isPresented: Binding(
                get: { generatedTemplateInfo != nil },
                set: { if !$0 { generatedTemplateInfo = nil } }
            ), presenting: generatedTemplateInfo) { info in
                Button("Got it", role: .cancel) { }
            } message: { info in
                Text("A \(info.intensity.rawValue) intensity workout has been generated for \(info.name).")
            }
    }
    
    @ViewBuilder
    private func cardHeader(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
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
            
            dayIndicator(dayIndex: info.dayIndex)
        }
    }
    
    @ViewBuilder
    private func dayIndicator(dayIndex: Int) -> some View {
        VStack(spacing: 4) {
            Text("Day")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.foreground.opacity(0.7))
            
            Text("\(dayIndex + 1)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func exercisesPreview(for day: WorkoutDay) -> some View {
        if !day.exercises.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercises")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.foreground.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(day.exercises.prefix(4), id: \.id) { exercise in
                        exerciseRow(exercise: exercise)
                    }
                    
                    if day.exercises.count > 4 {
                        Text("+\(day.exercises.count - 4) more exercises")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                            .padding(.leading, 14)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRow(exercise: ProgramExercise) -> some View {
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
    
    @ViewBuilder
    private func startButton(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
        Button(action: {
            handleStartButton(for: info)
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
    
    private func handleStartButton(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) {
        HapticManager.impact(style: .medium)
        if let templateId = info.currentDay.templateId {
            let template = CardDetailCacheManager.shared.getCachedTemplate(templateId) ?? 
                         templatesViewModel.templates.first(where: { $0.id == templateId })
            if let template = template {
                if CardDetailCacheManager.shared.getCachedTemplate(templateId) == nil {
                    CardDetailCacheManager.shared.cacheTemplate(template)
                }
                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                onStartWorkout()
            }
        } else if !info.currentDay.exercises.isEmpty {
            startProgramDay(info.currentDay, programName: info.program.name)
            onStartWorkout()
        } else {
            showGeneratePrompt = true
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border.opacity(0.5), lineWidth: 1.5)
            )
    }
    
    private var generateWorkoutMessage: Text {
        guard let info = activeProgramInfo else {
            return Text("No workout assigned for this day. Would you like to generate one?")
        }
        let dayType = info.currentDay.name
        if let extractedType = WorkoutDayTypeExtractor.extract(from: dayType) {
            return Text("No workout assigned for this \(extractedType) day. Would you like to generate one?")
        } else {
            return Text("No workout assigned for this day. Would you like to generate one?")
        }
    }
    
    private func generateAndStartWorkout() {
        guard let info = activeProgramInfo else { return }
        
        // Generate template using current generation settings
        if let result = programViewModel.ensureTemplateForDay(
            dayIndex: info.dayIndex,
            inProgram: info.program.id,
            settings: templatesViewModel.generationSettings,
            templatesViewModel: templatesViewModel
        ) {
            // Show alert if it was just generated
            if result.wasGenerated {
                generatedTemplateInfo = (name: result.template.name, intensity: result.intensity)
            }
            
            // Start the workout
            templatesViewModel.startTemplate(result.template, workoutViewModel: workoutViewModel)
            onStartWorkout()
        }
    }
    
    private func preloadTemplateData() {
        guard let info = activeProgramInfo,
              let templateId = info.currentDay.templateId else { return }
        
        // Check cache first - if already cached, we're done
        if CardDetailCacheManager.shared.getCachedTemplate(templateId) != nil {
            return
        }
        
        // Preload on background queue - capture values explicitly
        let templatesVM = templatesViewModel
        DispatchQueue.global(qos: .userInitiated).async {
            if let template = templatesVM.templates.first(where: { $0.id == templateId }) {
                // Cache the template (this is thread-safe)
                CardDetailCacheManager.shared.cacheTemplate(template)
            }
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
    
    private func checkAndPromptForGeneration() {
        guard let info = activeProgramInfo,
              !hasCheckedForGeneration,
              !info.currentDay.isRestDay else {
            return
        }
        
        // Check if day has no template and no exercises
        let hasNoTemplate = info.currentDay.templateId == nil
        let hasNoExercises = info.currentDay.exercises.isEmpty
        
        if hasNoTemplate && hasNoExercises {
            hasCheckedForGeneration = true
            // Small delay to ensure view is fully rendered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showGeneratePrompt = true
            }
        }
    }
}


