//
//  WorkoutView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var weight: String = "185"
    @State private var reps: String = "8"
    @State private var holdDuration: String = "30"
    @State private var calisthenicsReps: String = "8"
    @State private var calisthenicsWeight: String = "0"
    @State private var showFinishConfirmation = false
    @State private var selectedExerciseForHistory: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                WorkoutHeader(
                    title: viewModel.currentWorkout?.name ?? "Workout",
                    totalVolume: viewModel.totalWorkoutVolume,
                    onPause: { viewModel.pauseWorkout() },
                    onFinish: { showFinishConfirmation = true },
                    onSettings: { viewModel.showSettingsSheet = true }
                )
                .id("header-volume-\(viewModel.totalWorkoutVolume)")
                .id("header-\(viewModel.totalWorkoutVolume)")
                
                // Workout Timer
                WorkoutTimerBar(
                    time: viewModel.formatTime(viewModel.elapsedTime),
                    isPaused: viewModel.isTimerPausedDuringRest,
                    onAbort: {
                        viewModel.resetTimer()
                    }
                )
                
                // Exercise Navigation
                if let workout = viewModel.currentWorkout, workout.exercises.count > 1 {
                    ExerciseNavigationView(
                        exercises: workout.exercises,
                        currentIndex: viewModel.currentExerciseIndex,
                        onSelect: { index in
                            viewModel.currentExerciseIndex = index
                            viewModel.syncDropsetStateFromCurrentExercise()
                        }
                    )
                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
                    .id("exercise-nav-\(workout.exercises.map { "\($0.id)-\($0.sets.count)" }.joined(separator: "-"))")
                }
                
                // Exercise Card
                if let exercise = viewModel.currentExercise {
                    if exercise.type == .hold {
                        CalisthenicsExerciseCard(
                            exercise: exercise,
                            reps: $calisthenicsReps,
                            additionalWeight: $calisthenicsWeight,
                            onCompleteSet: {
                                if let repsValue = Int(calisthenicsReps),
                                   let weightValue = Double(calisthenicsWeight) {
                                    viewModel.completeCalisthenicsSet(reps: repsValue, additionalWeight: weightValue)
                                }
                            }
                        )
                        .animateOnAppear(delay: 0.1, animation: AppAnimations.smooth)
                    } else {
                        ExerciseCard(
                            exercise: exercise,
                            weight: $weight,
                            reps: $reps,
                            showPRBadge: viewModel.showPRBadge,
                            prMessage: viewModel.prMessage,
                            dropsetsEnabled: $viewModel.dropsetsEnabled,
                            numberOfDropsets: $viewModel.numberOfDropsets,
                            weightReductionPerDropset: $viewModel.weightReductionPerDropset,
                            isCollapsed: viewModel.restTimerActive,
                            showUndoButton: viewModel.showUndoButton,
                            barWeight: viewModel.settingsManager.barWeight,
                            currentExerciseVolume: viewModel.currentExerciseVolume,
                            viewModel: viewModel,
                            onCompleteSet: {
                                viewModel.updateCurrentExerciseDropsetConfiguration()
                                if let weightValue = Double(weight),
                                   let repsValue = Int(reps) {
                                    viewModel.completeSet(weight: weightValue, reps: repsValue)
                                }
                            },
                            onUndoSet: {
                                viewModel.undoLastSet()
                            },
                            onSelectAlternative: { alternativeName in
                                viewModel.switchToAlternative(alternativeName: alternativeName)
                            },
                            onExerciseNameTapped: {
                                selectedExerciseForHistory = exercise.name
                                viewModel.showExerciseHistory = true
                            }
                        )
                        .animateOnAppear(delay: 0.1, animation: AppAnimations.smooth)
                        .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                        .onAppear {
                            viewModel.syncDropsetStateFromCurrentExercise()
                            // Reset calisthenics inputs when exercise appears
                            if let exercise = viewModel.currentExercise, exercise.type == .hold {
                                if calisthenicsWeight.isEmpty || calisthenicsWeight == "" {
                                    calisthenicsWeight = "0"
                                }
                            }
                        }
                        .onChange(of: viewModel.currentExerciseIndex) { oldValue, newValue in
                            viewModel.syncDropsetStateFromCurrentExercise()
                            // Reset calisthenics inputs when switching exercises
                            if let exercise = viewModel.currentExercise, exercise.type == .hold {
                                calisthenicsWeight = "0"
                                calisthenicsReps = "8"
                            }
                        }
                        .onChange(of: exercise.sets.count) { _, _ in
                            // Force update when sets change - volume will recalculate
                        }
                    }
                }
                
                // Rest Timer (appears above alternative exercises)
                if viewModel.restTimerActive {
                    RestTimerView(
                        timeRemaining: max(0, viewModel.restTimeRemaining),
                        totalDuration: max(1, viewModel.restTimerTotalDuration), // Ensure at least 1 to prevent division by zero
                        onSkip: { viewModel.skipRest() },
                        onComplete: { viewModel.completeRest() }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Alternative Exercises Section (appears after rest timer)
                if let exercise = viewModel.currentExercise, exercise.type != .hold {
                    let allAlternatives = ExerciseDataManager.shared.getAlternatives(for: exercise.name)
                    // Limit to 3 alternatives
                    let alternatives = Array(allAlternatives.prefix(3))
                    if !alternatives.isEmpty {
                        AlternativeExercisesView(
                            exerciseName: exercise.name,
                            alternatives: alternatives,
                            onSelectAlternative: { alternativeName in
                                viewModel.switchToAlternative(alternativeName: alternativeName)
                            }
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, 20)
                    }
                }
                
                // Previous Sets
                if let exercise = viewModel.currentExercise, !exercise.sets.isEmpty {
                    PreviousSetsView(
                        sets: exercise.sets,
                        onDeleteSet: { setId in
                            viewModel.deleteSet(setId: setId)
                        }
                    )
                    .id("previous-sets-\(exercise.sets.count)-\(exercise.sets.last?.id.uuidString ?? "")")
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Add Exercise Button
                AddExerciseButton {
                    viewModel.showAddExerciseSheet = true
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Complete Workout Button (always available to end workout early)
                if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
                    Button(action: {
                        showFinishConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Complete Workout")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(AppColors.alabasterGrey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                        .shadow(color: AppColors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish", role: .destructive) {
                viewModel.finishWorkout()
            }
        } message: {
            Text("Are you sure you want to finish this workout? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showAddExerciseSheet) {
            AddExerciseView(
                onAdd: { name, sets, type, holdDuration in
                    viewModel.addExercise(name: name, targetSets: sets, type: type, holdDuration: holdDuration)
                    viewModel.showAddExerciseSheet = false
                },
                onCancel: {
                    viewModel.showAddExerciseSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showExerciseHistory) {
            if let exerciseName = selectedExerciseForHistory ?? viewModel.currentExercise?.name {
                ExerciseHistoryView(exerciseName: exerciseName, progressViewModel: viewModel.progressViewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            if let progressViewModel = viewModel.progressViewModel,
               let templatesViewModel = viewModel.templatesViewModel,
               let programViewModel = viewModel.programViewModel,
               let themeManager = viewModel.themeManager {
                SettingsView(
                    settingsManager: viewModel.settingsManager,
                    progressViewModel: progressViewModel,
                    templatesViewModel: templatesViewModel,
                    programViewModel: programViewModel,
                    themeManager: themeManager
                )
            }
        }
    }
}

struct WorkoutHeader: View {
    let title: String
    let totalVolume: Int
    let onPause: () -> Void
    let onFinish: () -> Void
    let onSettings: () -> Void
    
    private func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                if totalVolume > 0 {
                    Text("\(formatVolume(totalVolume)) lbs")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            HStack(spacing: AppSpacing.md) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: AppConstants.UI.minimumButtonSize, height: AppConstants.UI.minimumButtonSize)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens workout settings")
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onPause()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: AppConstants.UI.minimumButtonSize, height: AppConstants.UI.minimumButtonSize)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .rotationEffect(.degrees(0))
                        .animation(AppAnimations.quick, value: UUID())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Pause Workout")
                .accessibilityHint("Pauses the current workout")
                
                Button(action: {
                    HapticManager.success()
                    onFinish()
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: AppConstants.UI.minimumButtonSize, height: AppConstants.UI.minimumButtonSize)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Finish Workout")
                .accessibilityHint("Completes and saves the current workout")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct WorkoutTimerBar: View {
    let time: String
    let isPaused: Bool
    let onAbort: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPaused ? "pause.circle.fill" : "timer")
                .font(.system(size: 16))
                .foregroundColor(isPaused ? AppColors.accent : AppColors.mutedForeground)
            
            HStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPaused ? AppColors.accent : AppColors.mutedForeground)
                    .contentTransition(.numericText())
                    .animation(AppAnimations.quick, value: time)
                
                if isPaused {
                    Text("(Paused)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.accent)
                }
            }
            .accessibilityLabel(isPaused ? "Workout time paused: \(time)" : "Workout time: \(time)")
            .accessibilityValue(time)
            
            Spacer()
            
            Button(action: onAbort) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Reset")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(AppColors.destructive)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.destructive.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.destructive.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Reset Timer")
            .accessibilityHint("Resets the workout timer to zero")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    @Binding var weight: String
    @Binding var reps: String
    let showPRBadge: Bool
    let prMessage: String
    @Binding var dropsetsEnabled: Bool
    @Binding var numberOfDropsets: Int
    @Binding var weightReductionPerDropset: Double
    let isCollapsed: Bool
    let showUndoButton: Bool
    let barWeight: Double
    let currentExerciseVolume: Int
    let viewModel: WorkoutViewModel
    let onCompleteSet: () -> Void
    let onUndoSet: () -> Void
    let onSelectAlternative: ((String) -> Void)?
    let onExerciseNameTapped: (() -> Void)?
    
    private func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
    }
    
    private var alternatives: [String] {
        if !exercise.alternatives.isEmpty {
            return exercise.alternatives
        }
        return ExerciseDataManager.shared.getAlternatives(for: exercise.name)
    }
    
    private var videoURL: String? {
        exercise.videoURL ?? ExerciseDataManager.shared.getVideoURL(for: exercise.name)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top gradient bar
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color(light: AppColors.prussianBlue, dark: Color(hex: "1c1c1e")),
                        Color(light: AppColors.duskBlue, dark: Color(hex: "2c2c2e")),
                        Color(light: AppColors.dustyDenim, dark: Color(hex: "3a3a3c"))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 4)
            
            if isCollapsed {
                // Collapsed view - show only essential info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                            .lineLimit(1)
                        
                        Text("Set \(exercise.currentSet) of \(exercise.targetSets)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.accent)
                }
                .padding(16)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Expanded view - show all content
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise Header
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    onExerciseNameTapped?()
                                }) {
                                    Text(exercise.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(AppColors.foreground)
                                        .accessibilityAddTraits(.isHeader)
                                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Favorite Button
                                FavoriteButton(exerciseName: exercise.name)
                            }
                            
                            HStack(spacing: 12) {
                                Text("Set \(exercise.currentSet) of \(exercise.targetSets)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.secondary)
                                    .clipShape(Capsule())
                                
                                // Exercise Volume
                                if currentExerciseVolume > 0 {
                                    Text("\(formatVolume(currentExerciseVolume)) lbs")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(AppColors.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // PR Badge
                    if showPRBadge {
                        PRBadge(message: prMessage)
                            .transition(.scaleWithFade)
                            .zIndex(10)
                    }
                    
                    // Smart Weight Suggestions
                    SmartWeightSuggestion(
                        exerciseName: exercise.name,
                        weight: $weight,
                        reps: $reps
                    )
                    
                    // Weight Input
                    InputField(
                        label: "Weight",
                        value: $weight,
                        unit: "lbs",
                        keyboardType: .decimalPad,
                        isWeight: true
                    )
                    
                    // Plate Calculator
                    if let weightValue = Double(weight), weightValue > 0 {
                        PlateCalculator(weight: weightValue, barWeight: barWeight)
                    }
                    
                    // Reps Input
                    InputField(
                        label: "Reps",
                        value: $reps,
                        unit: "reps",
                        keyboardType: .numberPad,
                        isWeight: false,
                        presets: [5, 8, 10, 12, 15]
                    )
                    
                    // Dropset Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $dropsetsEnabled) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(dropsetsEnabled ? AppColors.accent : AppColors.mutedForeground)
                            Text("Dropsets")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                    
                    if dropsetsEnabled {
                        VStack(alignment: .leading, spacing: 16) {
                            // Number of dropsets stepper
                            HStack {
                                Text("Number of dropsets")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                Spacer()
                                HStack(spacing: 16) {
                                    Button(action: {
                                        HapticManager.impact(style: .light)
                                        withAnimation(AppAnimations.quick) {
                                            if numberOfDropsets > 1 {
                                                numberOfDropsets -= 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(numberOfDropsets > 1 ? AppColors.accent : AppColors.mutedForeground)
                                    }
                                    .disabled(numberOfDropsets <= 1)
                                    .buttonStyle(SubtleButtonStyle())
                                    
                                    Text("\(numberOfDropsets)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppColors.foreground)
                                        .frame(minWidth: 30)
                                        .contentTransition(.numericText())
                                        .animation(AppAnimations.quick, value: numberOfDropsets)
                                    
                                    Button(action: {
                                        HapticManager.impact(style: .light)
                                        withAnimation(AppAnimations.quick) {
                                            if numberOfDropsets < 5 {
                                                numberOfDropsets += 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(numberOfDropsets < 5 ? AppColors.accent : AppColors.mutedForeground)
                                    }
                                    .disabled(numberOfDropsets >= 5)
                                    .buttonStyle(SubtleButtonStyle())
                                }
                            }
                            
                            // Weight reduction stepper
                            HStack {
                                Text("Weight reduction per dropset")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                Spacer()
                                HStack(spacing: 16) {
                                    Button(action: {
                                        HapticManager.impact(style: .light)
                                        withAnimation(AppAnimations.quick) {
                                            if weightReductionPerDropset > 5 {
                                                weightReductionPerDropset -= 5
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(weightReductionPerDropset > 5 ? AppColors.accent : AppColors.mutedForeground)
                                    }
                                    .disabled(weightReductionPerDropset <= 5)
                                    .buttonStyle(SubtleButtonStyle())
                                    
                                    Text("\(Int(weightReductionPerDropset)) lbs")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppColors.foreground)
                                        .frame(minWidth: 50)
                                        .contentTransition(.numericText())
                                        .animation(AppAnimations.quick, value: weightReductionPerDropset)
                                    
                                    Button(action: {
                                        HapticManager.impact(style: .light)
                                        withAnimation(AppAnimations.quick) {
                                            if weightReductionPerDropset < 50 {
                                                weightReductionPerDropset += 5
                                            }
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(weightReductionPerDropset < 50 ? AppColors.accent : AppColors.mutedForeground)
                                    }
                                    .disabled(weightReductionPerDropset >= 50)
                                    .buttonStyle(SubtleButtonStyle())
                                }
                            }
                            
                            // Preview text
                            if Double(weight) != nil {
                                Text("After main set: \(numberOfDropsets) dropset\(numberOfDropsets > 1 ? "s" : ""), reducing by \(Int(weightReductionPerDropset)) lbs each")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.mutedForeground)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(AppColors.secondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Video Tutorial Button
                if videoURL != nil {
                    VideoTutorialButton(videoURL: videoURL, exerciseName: exercise.name)
                }
                
                // Warm-up Sets Button
                WarmupSetsButton(
                    exercise: exercise,
                    weight: weight,
                    reps: reps,
                    viewModel: viewModel,
                    onAddWarmup: {
                        if let weightValue = Double(weight), let repsValue = Int(reps) {
                            viewModel.addWarmupSets(for: weightValue, reps: repsValue)
                        }
                    }
                )
                
                // Complete Set Button
                Button(action: onCompleteSet) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("Complete Set")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(LinearGradient.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Undo Last Set Button
                if showUndoButton {
                    Button(action: onUndoSet) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Undo Last Set")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(AppColors.destructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.destructive.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.destructive.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                } // Close inner VStack (expanded view content)
            } // Close else block
        } // Close outer VStack
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    } // Close body
} // Close ExerciseCard struct

// MARK: - Calisthenics Exercise Card
struct CalisthenicsExerciseCard: View {
    let exercise: Exercise
    @Binding var reps: String
    @Binding var additionalWeight: String
    let onCompleteSet: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top gradient bar
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color(light: AppColors.prussianBlue, dark: Color(hex: "1c1c1e")),
                        Color(light: AppColors.duskBlue, dark: Color(hex: "2c2c2e")),
                        Color(light: AppColors.dustyDenim, dark: Color(hex: "3a3a3c"))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 4)
            
            VStack(alignment: .leading, spacing: 20) {
                // Exercise Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.accent)
                        
                        Text(exercise.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                    }
                    
                    Text("Set \(exercise.currentSet) of \(exercise.targetSets)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.secondary)
                        .clipShape(Capsule())
                }
                
                // Reps Input
                InputField(
                    label: "Reps",
                    value: $reps,
                    unit: "reps",
                    keyboardType: .numberPad,
                    isWeight: false,
                    presets: [5, 8, 10, 12, 15]
                )
                
                // Additional Weight Input
                InputField(
                    label: "Additional Weight",
                    value: $additionalWeight,
                    unit: "lbs",
                    keyboardType: .decimalPad,
                    isWeight: true
                )
                
                // Complete Set Button
                Button(action: onCompleteSet) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("Complete Set")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(LinearGradient.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(24)
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            // Reset additional weight to 0 if empty
            if additionalWeight.isEmpty {
                additionalWeight = "0"
            }
        }
    }
}

struct PRBadge: View {
    let message: String
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -5
    @State private var glowIntensity: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Confetti effect using SF Symbols
            if showConfetti {
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .offset(
                                x: CGFloat.random(in: -20...20),
                                y: CGFloat.random(in: -30...10)
                            )
                            .opacity(showConfetti ? 1 : 0)
                    }
                }
                .animation(
                    Animation.easeOut(duration: 0.6)
                        .delay(0.1),
                    value: showConfetti
                )
            }
            
            // Main badge
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .rotationEffect(.degrees(rotation))
                Text("PR! \(message)")
                    .font(.system(size: 15, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundColor(AppColors.alabasterGrey)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(LinearGradient(
                colors: [
                    Color(light: AppColors.prussianBlue, dark: Color(hex: "1c1c1e")),
                    Color(light: AppColors.duskBlue, dark: Color(hex: "2c2c2e")),
                    Color(light: AppColors.dustyDenim, dark: Color(hex: "3a3a3c"))
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(scale)
            .shadow(
                color: Color(light: AppColors.prussianBlue, dark: Color(hex: "000000")).opacity(0.4 + glowIntensity),
                radius: 20 + (glowIntensity * 10),
                x: 0,
                y: 8
            )
            .shadow(
                color: Color(light: AppColors.prussianBlue, dark: Color(hex: "000000")).opacity(0.2 + glowIntensity),
                radius: 8 + (glowIntensity * 5),
                x: 0,
                y: 4
            )
        }
        .onAppear {
            // Trigger haptic feedback
            HapticManager.success()
            
            // Celebration animation sequence
            withAnimation(AppAnimations.celebration) {
                scale = 1.1
                rotation = 5
                glowIntensity = 0.3
                showConfetti = true
            }
            
            // Settle animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(AppAnimations.celebration) {
                    scale = 1.0
                    rotation = 0
                }
            }
            
            // Pulse glow effect
            withAnimation(
                Animation.easeInOut(duration: 0.8)
                    .repeatCount(3, autoreverses: true)
            ) {
                glowIntensity = 0.2
            }
            
            // Hide confetti after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
    }
}

struct InputField: View {
    let label: String
    @Binding var value: String
    let unit: String
    let keyboardType: UIKeyboardType
    let isWeight: Bool // true for weight, false for reps
    let presets: [Int]? // Optional presets for quick selection
    
    init(label: String, value: Binding<String>, unit: String, keyboardType: UIKeyboardType, isWeight: Bool = false, presets: [Int]? = nil) {
        self.label = label
        self._value = value
        self.unit = unit
        self.keyboardType = keyboardType
        self.isWeight = isWeight
        self.presets = presets
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            // Main input field with +/- buttons
            HStack(spacing: 12) {
                // Minus button
                Button(action: {
                    HapticManager.impact(style: .light)
                    adjustValue(by: isWeight ? -5.0 : -1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                }
                .buttonStyle(SubtleButtonStyle())
                
                TextField("", text: $value)
                    .keyboardType(keyboardType)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { gesture in
                                let horizontalAmount = gesture.translation.width
                                if abs(horizontalAmount) > 30 {
                                    if horizontalAmount > 0 {
                                        // Swipe right - increase
                                        adjustValue(by: isWeight ? 5.0 : 1)
                                    } else {
                                        // Swipe left - decrease
                                        adjustValue(by: isWeight ? -5.0 : -1)
                                    }
                                }
                            }
                    )
                    .accessibilityLabel(label)
                    .accessibilityValue(value.isEmpty ? "No value" : "\(value) \(unit)")
                    .accessibilityHint("Enter \(label.lowercased()) in \(unit). Swipe left or right to adjust.")
                
                // Plus button
                Button(action: {
                    HapticManager.impact(style: .light)
                    adjustValue(by: isWeight ? 5.0 : 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                }
                .buttonStyle(SubtleButtonStyle())
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .frame(width: 40)
            }
            
            // Quick adjustment buttons for weight
            if isWeight {
                HStack(spacing: 8) {
                    QuickAdjustButton(value: 5, currentValue: $value, isWeight: true)
                    QuickAdjustButton(value: 10, currentValue: $value, isWeight: true)
                    QuickAdjustButton(value: 25, currentValue: $value, isWeight: true)
                }
            }
            
            // Preset buttons for reps
            if let presets = presets, !isWeight {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        PresetButton(preset: preset, currentValue: $value)
                    }
                }
            }
        }
    }
    
    private func adjustValue(by amount: Double) {
        guard let currentValue = Double(value) else {
            // If value is empty or invalid, set to amount
            value = String(format: "%.0f", abs(amount))
            return
        }
        
        let newValue = max(0, currentValue + amount)
        if isWeight {
            value = String(format: "%.0f", newValue)
        } else {
            value = String(format: "%.0f", newValue)
        }
    }
}

struct QuickAdjustButton: View {
    let value: Int
    @Binding var currentValue: String
    let isWeight: Bool
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            adjustValue(by: Double(value))
        }) {
            Text("+\(value)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(SubtleButtonStyle())
    }
    
    private func adjustValue(by amount: Double) {
        guard let current = Double(currentValue) else {
            currentValue = String(format: "%.0f", amount)
            return
        }
        let newValue = max(0, current + amount)
        currentValue = String(format: "%.0f", newValue)
    }
}

struct PresetButton: View {
    let preset: Int
    @Binding var currentValue: String
    
    var isSelected: Bool {
        guard let current = Int(currentValue) else { return false }
        return current == preset
    }
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            currentValue = "\(preset)"
        }) {
            Text("\(preset)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.accent : AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(SubtleButtonStyle())
    }
}

// MARK: - Favorite Button
struct FavoriteButton: View {
    let exerciseName: String
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    var isFavorite: Bool {
        favoritesManager.isFavorite(exerciseName)
    }
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            favoritesManager.toggleFavorite(exerciseName)
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 20))
                .foregroundColor(isFavorite ? AppColors.accent : AppColors.mutedForeground)
                .frame(width: 40, height: 40)
                .background(isFavorite ? AppColors.accent.opacity(0.1) : AppColors.secondary)
                .clipShape(Circle())
        }
        .buttonStyle(SubtleButtonStyle())
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

// MARK: - Warm-up Sets Button
struct WarmupSetsButton: View {
    let exercise: Exercise
    let weight: String
    let reps: String
    let viewModel: WorkoutViewModel
    let onAddWarmup: () -> Void
    
    private var canAddWarmup: Bool {
        // Only show if exercise has no sets yet and weight/reps are valid
        guard exercise.sets.isEmpty,
              let weightValue = Double(weight), weightValue > 0,
              let repsValue = Int(reps), repsValue > 0 else { return false }
        // Don't show if warm-up sets already exist (safety check)
        return !viewModel.hasWarmupSets()
    }
    
    var body: some View {
        if canAddWarmup {
            Button(action: {
                HapticManager.impact(style: .light)
                onAddWarmup()
            }) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    Text("Warm-up")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Set Templates Button
struct SetTemplatesButton: View {
    @Binding var weight: String
    @Binding var reps: String
    @StateObject private var templatesManager = SetTemplatesManager.shared
    @State private var showTemplates = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            showTemplates = true
        }) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 14))
                Text("Templates")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showTemplates) {
            SetTemplatesView(weight: $weight, reps: $reps)
        }
    }
}

// MARK: - Set Templates View
struct SetTemplatesView: View {
    @Binding var weight: String
    @Binding var reps: String
    @StateObject private var templatesManager = SetTemplatesManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var newTemplateName = ""
    @State private var showCreateTemplate = false
    
    var body: some View {
        NavigationView {
            List {
                // Create Template Section
                Section {
                    Button(action: {
                        if let weightValue = Double(weight), weightValue > 0,
                           let repsValue = Int(reps), repsValue > 0 {
                            let template = templatesManager.createTemplateFromCurrent(weight: weightValue, reps: repsValue)
                            templatesManager.addTemplate(name: template.name, weight: template.weight, reps: template.reps)
                            HapticManager.success()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Save Current Set as Template")
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    .disabled(weight.isEmpty || reps.isEmpty || Double(weight) == nil || Double(weight) ?? 0 <= 0 || Int(reps) == nil || Int(reps) ?? 0 <= 0)
                }
                
                // Templates List
                Section(header: Text("Saved Templates")) {
                    if templatesManager.templates.isEmpty {
                        Text("No templates saved")
                            .foregroundColor(AppColors.mutedForeground)
                            .font(.system(size: 14))
                    } else {
                        ForEach(templatesManager.templates) { template in
                            Button(action: {
                                // Format weight to remove unnecessary decimals
                                if template.weight.truncatingRemainder(dividingBy: 1) == 0 {
                                    weight = "\(Int(template.weight))"
                                } else {
                                    weight = String(format: "%.1f", template.weight)
                                }
                                reps = "\(template.reps)"
                                dismiss()
                                HapticManager.selection()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.foreground)
                                        Text("\(Int(template.weight)) lbs × \(template.reps) reps")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive, action: {
                                    templatesManager.deleteTemplate(template)
                                    HapticManager.impact(style: .medium)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

// MARK: - Plate Calculator
struct PlateCalculator: View {
    let weight: Double
    let barWeight: Double
    
    init(weight: Double, barWeight: Double = 45.0) {
        self.weight = weight
        self.barWeight = barWeight
    }
    
    private var plateCalculation: String {
        guard weight > barWeight else { return "" }
        
        let weightToLoad = weight - barWeight
        let platesPerSide = weightToLoad / 2.0
        
        // Standard plate weights (lbs)
        let plateWeights: [Double] = [45, 35, 25, 10, 5, 2.5]
        var remaining = platesPerSide
        var result: [String] = []
        
        for plateWeight in plateWeights {
            let count = Int(remaining / plateWeight)
            if count > 0 {
                result.append("\(count)×\(Int(plateWeight))")
                remaining -= Double(count) * plateWeight
            }
        }
        
        // Handle odd weights (round to nearest 2.5)
        if remaining > 1.25 {
            result.append("1×2.5")
        }
        
        return result.isEmpty ? "" : result.joined(separator: " + ")
    }
    
    var body: some View {
        if !plateCalculation.isEmpty {
            HStack {
                Image(systemName: "scalemass")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("Plates per side: \(plateCalculation)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Smart Weight Suggestion
struct SmartWeightSuggestion: View {
    let exerciseName: String
    @Binding var weight: String
    @Binding var reps: String
    
    @StateObject private var historyManager = ExerciseHistoryManager.shared
    @State private var lastWeight: Double?
    @State private var lastReps: Int?
    
    var body: some View {
        if let lastWeight = lastWeight, let lastReps = lastReps {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Last time: \(Int(lastWeight)) lbs × \(lastReps) reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticManager.impact(style: .light)
                        self.weight = String(format: "%.0f", lastWeight)
                        self.reps = "\(lastReps)"
                    }) {
                        Text("Use Last")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppColors.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(SubtleButtonStyle())
                }
            }
            .padding(.horizontal, 4)
            .onAppear {
                loadLastWeightReps()
            }
            .onChange(of: exerciseName) {
                loadLastWeightReps()
            }
        } else {
            EmptyView()
                .onAppear {
                    loadLastWeightReps()
                }
                .onChange(of: exerciseName) {
                    loadLastWeightReps()
                }
        }
    }
    
    private func loadLastWeightReps() {
        if let last = historyManager.getLastWeightReps(for: exerciseName) {
            lastWeight = last.weight
            lastReps = last.reps
        } else {
            lastWeight = nil
            lastReps = nil
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .brightness(configuration.isPressed ? -0.05 : (isHovered ? 0.02 : 0))
            .shadow(
                color: configuration.isPressed ? Color.black.opacity(0.15) : (isHovered ? Color.black.opacity(0.25) : Color.black.opacity(0.2)),
                radius: configuration.isPressed ? 6 : (isHovered ? 10 : 8),
                x: 0,
                y: configuration.isPressed ? 3 : (isHovered ? 5 : 4)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.impact(style: .light)
                }
            }
    }
}

struct AddExerciseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("Add Exercise")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(AppColors.alabasterGrey)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
            .shadow(color: AppColors.primary.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Exercise Navigation View
struct ExerciseNavigationView: View {
    let exercises: [Exercise]
    let currentIndex: Int
    let onSelect: (Int) -> Void
    
    // Count only working sets (exclude warm-up sets)
    private func workingSetsCount(for exercise: Exercise) -> Int {
        return exercise.sets.filter { !$0.isWarmup }.count
    }
    
    // Check if exercise is completed
    private func isExerciseCompleted(_ exercise: Exercise) -> Bool {
        let workingSets = workingSetsCount(for: exercise)
        return workingSets >= exercise.targetSets
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    Button(action: {
                        withAnimation(AppAnimations.quick) {
                            onSelect(index)
                        }
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text(exercise.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(index == currentIndex ? AppColors.alabasterGrey : AppColors.foreground)
                                    .lineLimit(1)
                                
                                // Checkmark for completed exercises
                                if isExerciseCompleted(exercise) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(index == currentIndex ? AppColors.alabasterGrey : AppColors.accent)
                                }
                            }
                            
                            let workingSets = workingSetsCount(for: exercise)
                            Text("\(workingSets)/\(exercise.targetSets)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(index == currentIndex ? AppColors.alabasterGrey.opacity(0.8) : AppColors.mutedForeground)
                                .contentTransition(.numericText())
                                .animation(AppAnimations.quick, value: workingSets)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            index == currentIndex ?
                            LinearGradient.primaryGradient :
                            (isExerciseCompleted(exercise) ?
                             LinearGradient(colors: [AppColors.accent.opacity(0.2)], startPoint: .top, endPoint: .bottom) :
                             LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index == currentIndex ? Color.clear :
                                    (isExerciseCompleted(exercise) ? AppColors.accent.opacity(0.5) : AppColors.border),
                                    lineWidth: isExerciseCompleted(exercise) ? 2 : 1
                                )
                        )
                        .animation(AppAnimations.selection, value: currentIndex)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .id("\(exercise.id)-\(workingSetsCount(for: exercise))")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showResetWarning = false
    @State private var showAddCustomExercise = false
    @State private var showCustomExercisesList = false
    
    private let restTimerOptions: [Int] = AppConstants.restTimerOptions
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Rest Timer Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rest Timer")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("Set the default rest time between sets")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        // Current Selection Display
                        HStack {
                            Text("Current: \(formatTime(settingsManager.restTimerDuration))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            Text("\(settingsManager.restTimerDuration) seconds")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        .padding(16)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Quick Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Options")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(restTimerOptions, id: \.self) { duration in
                                    Button(action: {
                                        settingsManager.restTimerDuration = duration
                                    }) {
                                        VStack(spacing: 4) {
                                            Text("\(formatTime(duration))")
                                                .font(.system(size: 16, weight: .semibold))
                                            
                                            Text("\(duration)s")
                                                .font(.system(size: 12, weight: .regular))
                                        }
                                        .foregroundColor(settingsManager.restTimerDuration == duration ? AppColors.alabasterGrey : AppColors.foreground)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(settingsManager.restTimerDuration == duration ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        
                        // Custom Duration Slider
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Duration")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            HStack {
                                Text("30s")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(settingsManager.restTimerDuration) },
                                        set: { settingsManager.restTimerDuration = Int($0) }
                                    ),
                                    in: 30...600,
                                    step: 15
                                )
                                .tint(AppColors.primary)
                                
                                Text("10m")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                            
                            Text("\(formatTime(settingsManager.restTimerDuration))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(LinearGradient.primaryGradient)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        }
                        .padding(16)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                    
                    // Warm-up Sets Section
                    WarmupSettingsSection(settingsManager: settingsManager)
                    
                    // Reset Data Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("Reset all app data including workouts, templates, programs, and progress. This action cannot be undone.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Button(action: {
                            showResetWarning = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Reset All Data")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                    
                    // Custom Exercises Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Exercises")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showAddCustomExercise = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Add Custom Exercise")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(AppColors.alabasterGrey)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            if !exerciseDataManager.customExercises.isEmpty {
                                Button(action: {
                                    showCustomExercisesList = true
                                }) {
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 20))
                                        Text("View Custom Exercises (\(exerciseDataManager.customExercises.count))")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.foreground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.secondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.border, lineWidth: 2)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                }
            }
            .sheet(isPresented: $showCustomExercisesList) {
                CustomExercisesListView()
            }
            .alert("Reset All Data", isPresented: $showResetWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settingsManager.resetAllData(
                        progressViewModel: progressViewModel,
                        templatesViewModel: templatesViewModel,
                        programViewModel: programViewModel,
                        themeManager: themeManager
                    )
                }
            } message: {
                Text("This will permanently delete all your workout data, templates, programs, progress, and settings. This action cannot be undone. Are you sure you want to continue?")
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            if remainingSeconds > 0 {
                return "\(minutes)m \(remainingSeconds)s"
            } else {
                return "\(minutes)m"
            }
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Warm-up Settings Section
struct WarmupSettingsSection: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var editingPercentages: [Double] = []
    @State private var showPreview = false
    @State private var previewWeight: String = "185"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                Text("Warm-up Sets")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.foreground)
            }
            
            Text("Configure warm-up set percentages based on your working weight")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
            
            // Current Warm-up Percentages
            VStack(alignment: .leading, spacing: 12) {
                Text("Warm-up Percentages")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                if settingsManager.warmupPercentages.isEmpty {
                    Text("No warm-up sets configured")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(settingsManager.warmupPercentages.enumerated()), id: \.offset) { index, percentage in
                            WarmupPercentageRow(
                                percentage: percentage,
                                index: index,
                                onDelete: {
                                    var updated = settingsManager.warmupPercentages
                                    updated.remove(at: index)
                                    settingsManager.warmupPercentages = updated
                                },
                                onEdit: { newPercentage in
                                    var updated = settingsManager.warmupPercentages
                                    updated[index] = newPercentage
                                    settingsManager.warmupPercentages = updated.sorted()
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Quick Presets
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Presets")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                HStack(spacing: 12) {
                    WarmupPresetButton(
                        title: "Light",
                        percentages: [40, 60, 80],
                        current: settingsManager.warmupPercentages,
                        onSelect: { settingsManager.warmupPercentages = $0 }
                    )
                    
                    WarmupPresetButton(
                        title: "Standard",
                        percentages: [50, 70, 90],
                        current: settingsManager.warmupPercentages,
                        onSelect: { settingsManager.warmupPercentages = $0 }
                    )
                    
                    WarmupPresetButton(
                        title: "Heavy",
                        percentages: [60, 80, 95],
                        current: settingsManager.warmupPercentages,
                        onSelect: { settingsManager.warmupPercentages = $0 }
                    )
                }
            }
            
            // Add Warm-up Percentage
            Button(action: {
                var updated = settingsManager.warmupPercentages
                // Add a new percentage (default to 50% if empty, otherwise add 10% to the last one)
                let newPercentage = updated.isEmpty ? 50.0 : min(95.0, (updated.last ?? 50.0) + 10.0)
                updated.append(newPercentage)
                settingsManager.warmupPercentages = updated.sorted()
                HapticManager.impact(style: .light)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Warm-up Percentage")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Preview Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Preview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Button(action: {
                        showPreview.toggle()
                        HapticManager.impact(style: .light)
                    }) {
                        Image(systemName: showPreview ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
                
                if showPreview {
                    WarmupPreviewSection(
                        percentages: settingsManager.warmupPercentages,
                        weight: $previewWeight
                    )
                }
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Reset Button
            Button(action: {
                settingsManager.resetWarmupPercentages()
                HapticManager.impact(style: .medium)
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                    Text("Reset to Default")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.mutedForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct WarmupPercentageRow: View {
    let percentage: Double
    let index: Int
    let onDelete: () -> Void
    let onEdit: (Double) -> Void
    @State private var isEditing = false
    @State private var editValue: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Percentage Display/Edit
            if isEditing {
                HStack(spacing: 8) {
                    TextField("", text: $editValue)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                        .frame(width: 60)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("%")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Button(action: {
                        if let newValue = Double(editValue),
                           newValue >= AppConstants.Warmup.minPercentage,
                           newValue <= AppConstants.Warmup.maxPercentage {
                            onEdit(newValue)
                            isEditing = false
                            HapticManager.selection()
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    Button(action: {
                        isEditing = false
                        editValue = String(format: "%.0f", percentage)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
            } else {
                HStack {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Button(action: {
                        isEditing = true
                        editValue = String(format: "%.0f", percentage)
                        HapticManager.impact(style: .light)
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    Button(action: {
                        onDelete()
                        HapticManager.impact(style: .medium)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.destructive)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct WarmupPresetButton: View {
    let title: String
    let percentages: [Double]
    let current: [Double]
    let onSelect: ([Double]) -> Void
    
    var isSelected: Bool {
        current == percentages
    }
    
    var body: some View {
        Button(action: {
            onSelect(percentages)
            HapticManager.impact(style: .light)
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(percentages.map { "\(Int($0))%" }.joined(separator: ", "))
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct WarmupPreviewSection: View {
    let percentages: [Double]
    @Binding var weight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Working Weight:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("185", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                    .frame(width: 80)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("lbs")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            if let workingWeight = Double(weight), workingWeight > 0, !percentages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warm-up Sets:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                        .textCase(.uppercase)
                    
                    ForEach(Array(percentages.sorted().enumerated()), id: \.offset) { _, percentage in
                        let warmupWeight = (workingWeight * percentage / 100.0).rounded(toNearest: 2.5)
                        HStack {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.accent)
                            
                            Text("\(Int(percentage))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 40, alignment: .leading)
                            
                            Text("\(Int(warmupWeight)) lbs")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    WorkoutView(viewModel: WorkoutViewModel(settingsManager: SettingsManager()))
}
