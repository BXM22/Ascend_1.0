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
    @ObservedObject var progressViewModel: ProgressViewModel
    let onStartWorkout: () -> Void
    @State private var showGeneratePrompt = false
    @State private var generatedTemplateInfo: (name: String, intensity: WorkoutIntensity)?
    @State private var cachedTemplate: WorkoutTemplate?
    @State private var hasCheckedForGeneration = false
    @State private var showDayPicker = false
    
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
    
    private func isRestProgramDay(_ day: WorkoutDay) -> Bool {
        day.isRestDay || day.name.lowercased().contains("rest")
    }
    
    @ViewBuilder
    private func cardContent(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
        let baseContent = VStack(alignment: .leading, spacing: 14) {
            cardHeader(for: info)
            weekDotsRow(for: info)
            if isRestProgramDay(info.currentDay) {
                restDayContent
            } else {
                exercisesPreview(for: info.currentDay)
                startButton(for: info)
            }
        }
        .padding(16)
        .background(cardBackground)
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 8, x: 0, y: 3)
        
        baseContent
            .onAppear {
                preloadTemplateData()
                checkAndPromptForGeneration()
            }
            .onChange(of: programViewModel.programs.count) {
                hasCheckedForGeneration = false
                checkAndPromptForGeneration()
            }
            .onChange(of: programViewModel.activeProgram?.programId) {
                hasCheckedForGeneration = false
                checkAndPromptForGeneration()
            }
            .onChange(of: currentDayTemplateId) {
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(info.currentDay.name)
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.foreground)
                
                Text(info.program.name)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func weekDotsRow(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
        if info.program.days.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
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
    
    private var restDayContent: some View {
        Group {
            if progressViewModel.isRestDay {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.accent)
                    Text("Logged as rest today")
                        .font(AppTypography.bodySmallMedium)
                        .foregroundColor(AppColors.foreground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button(action: {
                    HapticManager.impact(style: .medium)
                    progressViewModel.markRestDay()
                }) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Mark as rest")
                            .font(AppTypography.buttonBold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private func startButton(for info: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)) -> some View {
        Button(action: {
            Logger.debug("ActiveProgramDayCard button tapped", category: .general)
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
        Logger.info("ActiveProgramDayCard: Starting workout for day: \(info.currentDay.name)", category: .general)
        ActiveProgramDayWorkoutStart.start(
            program: info.program,
            currentDay: info.currentDay,
            programViewModel: programViewModel,
            templatesViewModel: templatesViewModel,
            workoutViewModel: workoutViewModel,
            onWorkoutReady: onStartWorkout,
            onGeneratedTemplate: { name, intensity in
                generatedTemplateInfo = (name: name, intensity: intensity)
            }
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.card)
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
    
    private func checkAndPromptForGeneration() {
        guard let info = activeProgramInfo,
              !hasCheckedForGeneration,
              !isRestProgramDay(info.currentDay) else {
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


