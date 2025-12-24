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
            // Removed alert - now auto-generates instead
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
            print("🔵 ActiveProgramDayCard button tapped")
            Logger.info("ActiveProgramDayCard button tapped", category: .general)
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
        print("🔵 ActiveProgramDayCard: handleStartButton called for day: \(info.currentDay.name)")
        Logger.info("ActiveProgramDayCard: Starting workout for day: \(info.currentDay.name)", category: .general)
        
        if let templateId = info.currentDay.templateId {
            print("🔵 ActiveProgramDayCard: Day has templateId: \(templateId)")
            let template = CardDetailCacheManager.shared.getCachedTemplate(templateId) ?? 
                         templatesViewModel.templates.first(where: { $0.id == templateId })
            if let template = template {
                print("🔵 ActiveProgramDayCard: Template found: \(template.name) with \(template.exercises.count) exercises")
                Logger.info("ActiveProgramDayCard: Found template: \(template.name)", category: .general)
                if CardDetailCacheManager.shared.getCachedTemplate(templateId) == nil {
                    CardDetailCacheManager.shared.cacheTemplate(template)
                }
                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                print("🔵 ActiveProgramDayCard: Template started, workout: \(workoutViewModel.currentWorkout?.name ?? "nil")")
                // Workout is set synchronously, call callback immediately
                print("🔵 ActiveProgramDayCard: Calling onStartWorkout callback")
                onStartWorkout()
            } else {
                print("❌ ActiveProgramDayCard: Template not found for ID: \(templateId), generating new one")
                Logger.error("ActiveProgramDayCard: Template not found for ID: \(templateId), generating", category: .general)
                // Template ID exists but template not found, generate a new one
                generateAndStartWorkout()
            }
        } else if !info.currentDay.exercises.isEmpty {
            print("🔵 ActiveProgramDayCard: Day has \(info.currentDay.exercises.count) exercises")
            Logger.info("ActiveProgramDayCard: Starting program day with \(info.currentDay.exercises.count) exercises", category: .general)
            startProgramDay(info.currentDay, programName: info.program.name)
            print("🔵 ActiveProgramDayCard: Program day started, workout: \(workoutViewModel.currentWorkout?.name ?? "nil")")
            // Call callback immediately
            print("🔵 ActiveProgramDayCard: Calling onStartWorkout callback for program day")
            onStartWorkout()
        } else {
            print("🔵 ActiveProgramDayCard: No template or exercises, auto-generating workout")
            Logger.info("ActiveProgramDayCard: No template or exercises, auto-generating workout", category: .general)
            // Auto-generate instead of showing prompt
            generateAndStartWorkout()
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
        guard let info = activeProgramInfo else {
            print("❌ ActiveProgramDayCard: No active program info for generate")
            Logger.error("ActiveProgramDayCard: No active program info for generate", category: .general)
            return
        }
        
        // Calculate current day index based on start date (not just using stored dayIndex)
        guard let active = programViewModel.activeProgram else {
            print("❌ ActiveProgramDayCard: No active program")
            return
        }
        
        let currentDayIndex = active.getCurrentDayIndex(totalDays: info.program.days.count)
        print("🔵 ActiveProgramDayCard: Generating workout for day \(currentDayIndex) (calculated from start date)")
        Logger.info("ActiveProgramDayCard: Generating workout for day \(currentDayIndex)", category: .general)
        
        // Generate template using current generation settings
        print("🔵 ActiveProgramDayCard: Calling ensureTemplateForDay with dayIndex: \(currentDayIndex), programId: \(info.program.id)")
        
        guard let result = programViewModel.ensureTemplateForDay(
            dayIndex: currentDayIndex,
            inProgram: info.program.id,
            settings: templatesViewModel.generationSettings,
            templatesViewModel: templatesViewModel
        ) else {
            print("❌ ActiveProgramDayCard: ensureTemplateForDay returned nil")
            Logger.error("ActiveProgramDayCard: Failed to generate template - ensureTemplateForDay returned nil. Day index: \(currentDayIndex), Program days count: \(info.program.days.count)", category: .general)
            return
        }
        
        print("🔵 ActiveProgramDayCard: Generated template: \(result.template.name) with \(result.template.exercises.count) exercises")
        Logger.info("ActiveProgramDayCard: Generated template: \(result.template.name) with \(result.template.exercises.count) exercises", category: .general)
        
        // Show alert if it was just generated
        if result.wasGenerated {
            generatedTemplateInfo = (name: result.template.name, intensity: result.intensity)
        }
        
        // Start the workout
        print("🔵 ActiveProgramDayCard: Starting template: \(result.template.name)")
        templatesViewModel.startTemplate(result.template, workoutViewModel: workoutViewModel)
        
        // Check immediately if workout was set
        if let workout = workoutViewModel.currentWorkout {
            print("🔵 ActiveProgramDayCard: Workout set successfully: \(workout.name) with \(workout.exercises.count) exercises")
            Logger.info("ActiveProgramDayCard: Workout set successfully: \(workout.name)", category: .general)
            onStartWorkout()
        } else {
            print("❌ ActiveProgramDayCard: Workout was not set after starting template")
            Logger.error("ActiveProgramDayCard: Workout was not set after starting template", category: .general)
            // Try again after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.workoutViewModel.currentWorkout != nil {
                    print("🔵 ActiveProgramDayCard: Workout set on retry, calling callback")
                    self.onStartWorkout()
                } else {
                    print("❌ ActiveProgramDayCard: Workout still not set after retry")
                }
            }
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


