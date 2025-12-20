import SwiftUI

struct SuggestedWorkoutCard: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    
    @ObservedObject private var workoutHistoryManager = WorkoutHistoryManager.shared
    @ObservedObject private var personalizationManager = PersonalizationManager.shared
    
    @State private var showGeneratedAlert = false
    @State private var generatedWorkoutInfo: (name: String, intensity: WorkoutIntensity)?
    
    // Check if there's an active program
    private var activeProgramDay: (name: String, day: WorkoutDay, programName: String)? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = WorkoutProgramManager.shared.programs.first(where: { $0.id == activeProgram.programId }),
              activeProgram.currentDayIndex < program.days.count else {
            return nil
        }
        
        let day = program.days[activeProgram.currentDayIndex]
        return (day.name, day, program.name)
    }
    
    // Get suggested template from available templates
    private var suggestedTemplate: (name: String, template: WorkoutTemplate, icon: String, gradient: LinearGradient, reasoning: String?)? {
        // Filter out progression templates
        let availableTemplates = templatesViewModel.templates.filter { !$0.name.contains("Progression") }
        
        guard !availableTemplates.isEmpty else { return nil }
        
        // Try to get personalized recommendation
        let personalizedRec = personalizationManager.getPersonalizedRecommendations()
        
        // Get recently used template names
        let recentTemplateNames = Set(workoutHistoryManager.completedWorkouts
            .prefix(5)
            .map { $0.name })
        
        // If we have a personalized recommendation, try to match it
        if let rec = personalizedRec {
            let recommendedType = rec.workoutType.lowercased()
            if let matchingTemplate = availableTemplates.first(where: { template in
                let templateName = template.name.lowercased()
                return (recommendedType == "push" && (templateName.contains("push") || templateName.contains("chest"))) ||
                       (recommendedType == "pull" && (templateName.contains("pull") || templateName.contains("back"))) ||
                       (recommendedType == "legs" && templateName.contains("leg")) ||
                       (recommendedType == "full body" && templateName.contains("full"))
            }) {
                let info = templateInfo(for: matchingTemplate)
                return (info.name, info.template, info.icon, info.gradient, rec.reasoning)
            }
        }
        
        // Find first template not recently used
        if let template = availableTemplates.first(where: { !recentTemplateNames.contains($0.name) }) {
            let info = templateInfo(for: template)
            return (info.name, info.template, info.icon, info.gradient, nil)
        }
        
        // Otherwise return first available template
        let info = templateInfo(for: availableTemplates[0])
        return (info.name, info.template, info.icon, info.gradient, nil)
    }
    
    private var personalizedReasoning: String? {
        suggestedTemplate?.reasoning
    }
    
    private func templateInfo(for template: WorkoutTemplate) -> (name: String, template: WorkoutTemplate, icon: String, gradient: LinearGradient) {
        let name = template.name
        let icon = "dumbbell.fill"
        
        // Determine gradient based on template name
        let gradient: LinearGradient
        if name.lowercased().contains("chest") || name.lowercased().contains("push") {
            gradient = LinearGradient.chestGradient
        } else if name.lowercased().contains("back") || name.lowercased().contains("pull") {
            gradient = LinearGradient.backGradient
        } else if name.lowercased().contains("leg") {
            gradient = LinearGradient.legsGradient
        } else if name.lowercased().contains("arm") {
            gradient = LinearGradient.armsGradient
        } else if name.lowercased().contains("core") {
            gradient = LinearGradient.coreGradient
        } else {
            gradient = LinearGradient.primaryGradient
        }
        
        return (name, template, icon, gradient)
    }
    
    private func startSuggestedWorkout() {
        // If there's an active program, start that day
        if let programDay = activeProgramDay {
            // Check if day has template or exercises
            if let templateId = programDay.day.templateId,
               let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                onStartWorkout()
            } else if !programDay.day.exercises.isEmpty {
                startProgramDay(programDay.day, programName: programDay.programName)
                onStartWorkout()
            } else {
                // Generate workout for this day
                if let active = programViewModel.activeProgram,
                   let program = programViewModel.programs.first(where: { $0.id == active.programId }) {
                    let dayIndex = active.getCurrentDayIndex(totalDays: program.days.count)
                    if let result = programViewModel.ensureTemplateForDay(
                        dayIndex: dayIndex,
                        inProgram: program.id,
                        settings: templatesViewModel.generationSettings,
                        templatesViewModel: templatesViewModel
                    ) {
                        if result.wasGenerated {
                            generatedWorkoutInfo = (name: result.template.name, intensity: result.intensity)
                            showGeneratedAlert = true
                        }
                        templatesViewModel.startTemplate(result.template, workoutViewModel: workoutViewModel)
                        onStartWorkout()
                    }
                }
            }
        }
        // Otherwise start suggested template
        else if let suggestion = suggestedTemplate {
            templatesViewModel.startTemplate(suggestion.template, workoutViewModel: workoutViewModel)
            onStartWorkout()
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
    
    var body: some View {
        // Determine what to show
        let title: String
        let name: String
        let icon: String
        let gradient: LinearGradient
        
        if let programDay = activeProgramDay {
            title = "Active Program"
            name = programDay.name
            icon = "calendar"
            gradient = LinearGradient.primaryGradient
        } else if let template = suggestedTemplate {
            title = "Suggested Workout"
            name = template.name
            icon = template.icon
            gradient = template.gradient
        } else {
            title = "No Templates"
            name = "Create a template to get started"
            icon = "plus.circle"
            gradient = LinearGradient.primaryGradient
        }
        
        return Button(action: {
            HapticManager.impact(style: .medium)
            startSuggestedWorkout()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                    
                    Text(name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    if let reasoning = personalizedReasoning {
                        Text(reasoning)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppColors.foreground.opacity(0.7))
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                    
                    HStack(spacing: 8) {
                        Text("Start Session")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.card)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Icon circle
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(gradient)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "d4f14e").opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color(hex: "d4f14e").opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(suggestedTemplate == nil && activeProgramDay == nil)
        .alert("Workout Generated", isPresented: $showGeneratedAlert, presenting: generatedWorkoutInfo) { info in
            Button("Got it", role: .cancel) { }
        } message: { info in
            Text("A \(info.intensity.rawValue) intensity workout has been generated for \(info.name).")
        }
    }
}

#Preview {
    SuggestedWorkoutCard(
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        templatesViewModel: TemplatesViewModel(),
        programViewModel: WorkoutProgramViewModel(),
        onStartWorkout: {}
    )
    .padding()
    .background(AppColors.background)
}

