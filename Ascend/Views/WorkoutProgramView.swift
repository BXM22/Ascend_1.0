import SwiftUI

// MARK: - Program detail (HTML reference layout; no duplicate top glass nav — iOS chrome handles dismiss)

private enum ProgramDetailLayout {
    static let heroImageURL = URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuARTQQmQHP7vFG1BCUZPV-moDVwIjSrs0xwxUeYEVpVeSqNz6Kku8speYeEJKtK-IMisQNbI6ZGxLPTLwYTPRlt-v4XkmyxX27RGn58uK5z53PEfkDDFpW-cNysYfB_SdtzwydLa0Jhnikw3MCC8xwwFZnk1DqDuDsAXFb9fG5UkR0bkX1JgcMMCOpbsBMU-bGDm919HTXTho8W7aU4_BoQbYF0Gcw67cuyXpC7vMyIlZ-NPE8roj7Y8HGVsg8zGeqy_4FO9b42zs4")
}

struct WorkoutProgramView: View {
    let program: WorkoutProgram
    @ObservedObject var workoutViewModel: WorkoutViewModel
    var programViewModel: WorkoutProgramViewModel? = nil
    var templatesViewModel: TemplatesViewModel? = nil
    @State private var selectedDayIndex: Int = 0
    @State private var showGenerateDayAlert = false
    @State private var dayToGenerate: (day: WorkoutDay, dayIndex: Int)?
    @State private var hasCheckedForGeneration = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var effectiveProgramViewModel: WorkoutProgramViewModel? {
        programViewModel ?? workoutViewModel.programViewModel
    }
    
    private var effectiveTemplatesViewModel: TemplatesViewModel? {
        templatesViewModel ?? workoutViewModel.templatesViewModel
    }
    
    private var currentProgram: WorkoutProgram {
        if let programVM = effectiveProgramViewModel,
           let updatedProgram = programVM.programs.first(where: { $0.id == program.id }) {
            return updatedProgram
        }
        return program
    }
    
    var selectedDay: WorkoutDay {
        currentProgram.days[selectedDayIndex]
    }
    
    private var shouldPromptForGeneration: Bool {
        guard let programVM = workoutViewModel.programViewModel,
              let _ = workoutViewModel.templatesViewModel,
              let active = programVM.activeProgram,
              active.programId == currentProgram.id else {
            return false
        }
        
        let currentDayIndex = active.getCurrentDayIndex(totalDays: currentProgram.days.count)
        guard currentDayIndex < currentProgram.days.count else { return false }
        
        let currentDay = currentProgram.days[currentDayIndex]
        
        let hasNoExercises = currentDay.exercises.isEmpty
        let hasNoTemplate = currentDay.templateId == nil
        let isNotRestDay = !currentDay.isRestDay
        
        return hasNoExercises && hasNoTemplate && isNotRestDay
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProgramHeroSection(program: currentProgram, imageURL: ProgramDetailLayout.heroImageURL)
                
                Group {
                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: 48) {
                            programMainColumn
                            programSidebar
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 32) {
                            programMainColumn
                            programSidebar
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.xl)
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CardDetailCacheManager.shared.cacheProgram(currentProgram)
            hasCheckedForGeneration = false
            
            if let programVM = effectiveProgramViewModel,
               let active = programVM.activeProgram,
               active.programId == currentProgram.id {
                let currentDayIndex = active.getCurrentDayIndex(totalDays: currentProgram.days.count)
                if currentDayIndex < currentProgram.days.count {
                    selectedDayIndex = currentDayIndex
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                checkAndPromptForGeneration()
            }
        }
        .onChange(of: selectedDayIndex) { _, _ in
            hasCheckedForGeneration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                checkAndPromptForGeneration()
            }
        }
        .onChange(of: effectiveProgramViewModel?.activeProgram?.programId) { _, _ in
            hasCheckedForGeneration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkAndPromptForGeneration()
            }
        }
        .alert("Generate Workout for \(dayToGenerate?.day.name ?? "this day")?", isPresented: $showGenerateDayAlert) {
            Button("Cancel", role: .cancel) {
                dayToGenerate = nil
            }
            Button("Generate") {
                if let dayInfo = dayToGenerate {
                    generateDay(day: dayInfo.day, dayIndex: dayInfo.dayIndex)
                }
            }
        } message: {
            Text("This day doesn't have any exercises set. Would you like to generate a workout for \(dayToGenerate?.day.name ?? "this day")?")
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private var programMainColumn: some View {
        VStack(alignment: .leading, spacing: 48) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("The Blueprint")
                    .font(AppTypography.titleLarge)
                    .foregroundColor(.white)
                
                Text(currentProgram.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.tertiaryContainer)
                    .kineticBodyLineHeight()
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack {
                    Text("Weekly Training Schedule")
                        .font(AppTypography.labelSmallUppercase)
                        .foregroundColor(AppColors.primary)
                        .kineticLabelTracking(for: 11)
                    Spacer()
                    Text("Full protocol")
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.mutedForeground)
                        .textCase(.uppercase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppColors.border.opacity(0.4))
                        .frame(height: 1)
                }
                
                ForEach(Array(currentProgram.days.enumerated()), id: \.element.id) { index, day in
                    ProgramScheduleDayCard(
                        day: day,
                        dayIndex: index,
                        onSelectDay: { selectedDayIndex = index },
                        onStartWorkout: {
                            selectedDayIndex = index
                            startWorkoutForDay(day)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var programSidebar: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack {
                    Text("Program access")
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.tertiaryContainer)
                    Spacer()
                    Text("Included")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(.white)
                }
                
                Button {
                    startWorkoutForDay(selectedDay)
                } label: {
                    HStack(spacing: 8) {
                        Text("Start program")
                            .font(AppTypography.buttonLarge)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primaryDim, AppColors.primaryContainer],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Divider().background(AppColors.border.opacity(0.5))
                    
                    ProgramSidebarBenefitRow(icon: "doc.text.fill", text: "Structured progression in-app")
                    ProgramSidebarBenefitRow(icon: "video.fill", text: "Exercise cues & logging")
                    ProgramSidebarBenefitRow(icon: "bubble.left.and.bubble.right.fill", text: "Track alongside your templates")
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: KineticElevation.ambientTint.opacity(0.06), radius: 48, x: 0, y: 24)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 320 : .infinity, alignment: .leading)
    }
    
    private func checkAndPromptForGeneration() {
        guard !hasCheckedForGeneration else { return }
        guard !showGenerateDayAlert else { return }
        
        guard let programVM = effectiveProgramViewModel else { return }
        guard let active = programVM.activeProgram else { return }
        guard active.programId == currentProgram.id else { return }
        
        let currentDayIndex = active.getCurrentDayIndex(totalDays: currentProgram.days.count)
        guard currentDayIndex < currentProgram.days.count else { return }
        guard selectedDayIndex == currentDayIndex else { return }
        
        let currentDay = currentProgram.days[currentDayIndex]
        
        let hasNoExercises = currentDay.exercises.isEmpty
        let hasNoTemplate = currentDay.templateId == nil
        let isNotRestDay = !currentDay.isRestDay
        
        if hasNoExercises && hasNoTemplate && isNotRestDay {
            hasCheckedForGeneration = true
            dayToGenerate = (currentDay, currentDayIndex)
            showGenerateDayAlert = true
        }
    }
    
    private func generateDay(day: WorkoutDay, dayIndex: Int) {
        guard let programVM = effectiveProgramViewModel,
              let templatesVM = effectiveTemplatesViewModel else {
            return
        }
        
        if programVM.ensureTemplateForDay(
            dayIndex: dayIndex,
            inProgram: currentProgram.id,
            settings: templatesVM.generationSettings,
            templatesViewModel: templatesVM
        ) != nil {
            Logger.info("Generated workout for day: \(day.name)", category: .general)
        }
        
        dayToGenerate = nil
    }
    
    private func startWorkoutForDay(_ day: WorkoutDay) {
        let exercises = day.exercises.map { programExercise in
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: programExercise.name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: programExercise.name)
            
            var correctedType = programExercise.exerciseType
            var correctedHoldDuration = programExercise.targetHoldDuration
            if workoutViewModel.isRepBasedCalisthenics(programExercise.name) {
                correctedType = .weightReps
                correctedHoldDuration = nil
            }
            
            return Exercise(
                name: programExercise.name,
                targetSets: programExercise.sets,
                exerciseType: correctedType,
                holdDuration: correctedHoldDuration,
                alternatives: alternatives,
                videoURL: videoURL
            )
        }
        
        workoutViewModel.currentWorkout = Workout(name: "\(currentProgram.name) - \(day.name)", exercises: exercises)
        workoutViewModel.currentExerciseIndex = 0
        workoutViewModel.isFromTemplate = true
        workoutViewModel.startTimer()
        
        for exercise in exercises {
            ExerciseUsageTracker.shared.trackExerciseUsage(exercise.name)
        }
        
        dismiss()
    }
}

// MARK: - Hero

private struct ProgramHeroSection: View {
    let program: WorkoutProgram
    let imageURL: URL?
    
    private var titleLines: String {
        program.name.uppercased()
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroBackground
            LinearGradient(
                colors: [AppColors.background, AppColors.background.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(program.category.rawValue)
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.onPrimaryContainer)
                    .textCase(.uppercase)
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.primaryDim.opacity(0.9))
                    .clipShape(Capsule())
                
                Text(titleLines)
                    .font(AppTypography.displayMedium)
                    .foregroundColor(.white)
                    .kineticDisplayTracking(for: 32)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)
                
                HStack(alignment: .top, spacing: 0) {
                    statColumn(label: "Duration", value: "\(program.days.count) days", valueColor: AppColors.primary)
                    statDivider
                    statColumn(label: "Intensity", value: program.category.rawValue, valueColor: .white)
                    statDivider
                    statColumn(label: "Frequency", value: program.frequency, valueColor: .white)
                }
                .padding(.top, AppSpacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(height: 320)
        .clipped()
    }
    
    @ViewBuilder
    private var heroBackground: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    AppColors.surfaceContainerHigh
                case .empty:
                    AppColors.surfaceContainerHigh
                        .overlay { SwiftUI.ProgressView().tint(AppColors.primary) }
                @unknown default:
                    AppColors.surfaceContainerHigh
                }
            }
        } else {
            AppColors.surfaceContainerHigh
        }
    }
    
    private func statColumn(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.labelSmallUppercase)
                .foregroundColor(AppColors.mutedForeground)
                .kineticLabelTracking(for: 10)
            Text(value)
                .font(AppTypography.titleMedium)
                .foregroundColor(valueColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var statDivider: some View {
        Rectangle()
            .fill(AppColors.border.opacity(0.5))
            .frame(width: 1, height: 44)
            .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Day card

private struct ProgramScheduleDayCard: View {
    let day: WorkoutDay
    let dayIndex: Int
    var onSelectDay: () -> Void
    var onStartWorkout: () -> Void
    
    private var isRest: Bool { day.isRestDay }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: AppSpacing.md) {
                    Text(String(format: "%02d", dayIndex + 1))
                        .font(AppTypography.captionBold)
                        .foregroundColor(isRest ? AppColors.mutedForeground : AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(isRest ? AppColors.surfaceContainerHigh : AppColors.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.name.uppercased())
                            .font(AppTypography.bodyBold)
                            .foregroundColor(isRest ? AppColors.mutedForeground : .white)
                            .lineLimit(2)
                        if !day.description.isEmpty {
                            Text(day.description)
                                .font(AppTypography.footnoteMedium)
                                .foregroundColor(AppColors.mutedForeground)
                                .lineLimit(2)
                        }
                    }
                }
                Spacer()
                if isRest {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .padding(AppSpacing.lg)
            .background(isRest ? AppColors.surfaceContainerLow.opacity(0.85) : AppColors.surfaceContainerHigh.opacity(0.6))
            
            if !isRest {
                VStack(spacing: 0) {
                    ForEach(Array(day.exercises.enumerated()), id: \.element.id) { i, exercise in
                        ProgramDetailExerciseRow(exercise: exercise, isLast: i == day.exercises.count - 1)
                    }
                    
                    Button(action: onStartWorkout) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start \(day.name)")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundColor(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primaryDim, AppColors.primaryContainer],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(AppSpacing.lg)
                    .onTapGesture { onSelectDay() }
                }
                .background(AppColors.surfaceContainerHigh.opacity(0.35))
                .overlay(
                    Rectangle()
                        .fill(AppColors.border.opacity(0.2))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .opacity(isRest ? 0.72 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            if !isRest { onSelectDay() }
        }
    }
}

private struct ProgramDetailExerciseRow: View {
    let exercise: ProgramExercise
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(exercise.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.foreground)
                Spacer()
                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.primary)
            }
            .padding(.vertical, 10)
            if !isLast {
                Divider()
                    .background(AppColors.border.opacity(0.15))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

private struct ProgramSidebarBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            Text(text)
                .font(AppTypography.subheadlineMedium)
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

/// Shared row for program exercises (used by `WorkoutDayDetailSheet` and elsewhere).
struct ProgramExerciseRow: View {
    let exercise: ProgramExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(exercise.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(exercise.sets)×\(exercise.reps)")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primary.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.leading, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationView {
        WorkoutProgramView(
            program: WorkoutProgramManager.shared.programs[0],
            workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager())
        )
    }
}
