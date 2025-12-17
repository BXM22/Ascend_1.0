//
//  WorkoutView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI
import HealthKit

struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var weight: String = "185"
    @State private var reps: String = "8"
    @State private var holdDuration: String = "30"
    @State private var calisthenicsReps: String = "8"
    @State private var calisthenicsWeight: String = "0"
    @State private var showFinishConfirmation = false
    @State private var selectedExerciseForHistory: String?
    @State private var showDeleteExerciseConfirmation = false
    @State private var exerciseToDelete: Int?
    @State private var currentSetIsWarmup = false
    
    // Helper to render exercise card based on type
    @ViewBuilder
    private func exerciseCardView(for exercise: Exercise, isCurrent: Bool) -> some View {
        let sectionType = viewModel.getSectionType(for: exercise)
        
        Group {
            if sectionType == .stretch {
                // Stretch-specific card: track by sets only (no weight/reps inputs)
                StretchExerciseCard(
                    exercise: exercise,
                    onCompleteSet: {
                        if isCurrent {
                            viewModel.completeStretchSet()
                        }
                    }
                )
                .id("exercise-\(exercise.id)-stretch-\(exercise.sets.count)")
            } else if viewModel.isCardioExercise(exercise) {
                // Cardio: time and set based only (no weight)
                CardioExerciseCard(
                    exercise: exercise,
                    holdDuration: $holdDuration,
                    showPRBadge: isCurrent ? viewModel.showPRBadge : false,
                    prMessage: isCurrent ? viewModel.prMessage : "",
                    onCompleteSet: {
                        if isCurrent, let duration = Int(holdDuration) {
                            viewModel.completeCalisthenicsHoldSet(duration: duration, additionalWeight: 0)
                        }
                    }
                )
                .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
                )
                .onAppear {
                    if isCurrent {
                        calisthenicsWeight = "0"
                        if exercise.targetHoldDuration != nil {
                            holdDuration = String(exercise.targetHoldDuration ?? 300)
                        } else {
                            holdDuration = "300"
                        }
                    }
                }
            } else if viewModel.isCalisthenicsExercise(exercise) {
                if exercise.targetHoldDuration != nil {
                    // Hold-based calisthenics
                    CalisthenicsHoldExerciseCard(
                        exercise: exercise,
                        holdDuration: $holdDuration,
                        additionalWeight: $calisthenicsWeight,
                        showPRBadge: isCurrent ? viewModel.showPRBadge : false,
                        prMessage: isCurrent ? viewModel.prMessage : "",
                        onCompleteSet: {
                            if isCurrent, let duration = Int(holdDuration),
                               let weightValue = Double(calisthenicsWeight) {
                                viewModel.completeCalisthenicsHoldSet(duration: duration, additionalWeight: weightValue)
                            }
                        }
                    )
                    .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
                    )
                    .onAppear {
                        if isCurrent {
                            if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                calisthenicsWeight = String(format: "%.0f", lastWeight)
                            } else {
                                calisthenicsWeight = "0"
                            }
                            if exercise.targetHoldDuration != nil {
                                holdDuration = String(exercise.targetHoldDuration ?? 30)
                            }
                        }
                    }
                } else {
                    // Rep-based calisthenics
                    CalisthenicsExerciseCard(
                        exercise: exercise,
                        reps: $calisthenicsReps,
                        additionalWeight: $calisthenicsWeight,
                        showPRBadge: isCurrent ? viewModel.showPRBadge : false,
                        prMessage: isCurrent ? viewModel.prMessage : "",
                        onCompleteSet: {
                            if isCurrent, let repsValue = Int(calisthenicsReps),
                               let weightValue = Double(calisthenicsWeight) {
                                viewModel.completeCalisthenicsSet(reps: repsValue, additionalWeight: weightValue)
                            }
                        }
                    )
                    .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
                    )
                    .onAppear {
                        if isCurrent {
                            if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                calisthenicsWeight = String(format: "%.0f", lastWeight)
                            } else {
                                calisthenicsWeight = "0"
                            }
                        }
                    }
                }
            } else {
                // Regular exercise card
                let isCompleted = viewModel.isExerciseCompleted(exercise)
                // Collapse all inactive exercises. Keep ONLY the active one open while doing the set.
                // During rest, even the active exercise collapses.
                let isDoingSet = isCurrent && !viewModel.restTimerActive
                let shouldCollapse = !isDoingSet || isCompleted
                
                ExerciseCard(
                    exercise: exercise,
                    weight: $weight,
                    reps: $reps,
                    showPRBadge: isCurrent ? viewModel.showPRBadge : false,
                    prMessage: isCurrent ? viewModel.prMessage : "",
                    dropsetsEnabled: $viewModel.dropsetsEnabled,
                    numberOfDropsets: $viewModel.numberOfDropsets,
                    weightReductionPerDropset: $viewModel.weightReductionPerDropset,
                    currentSetIsWarmup: $currentSetIsWarmup,
                    isCollapsed: shouldCollapse,
                    showUndoButton: isCurrent ? viewModel.showUndoButton : false,
                    barWeight: viewModel.settingsManager.barWeight,
                    currentExerciseVolume: isCurrent ? viewModel.currentExerciseVolume : 0,
                    viewModel: viewModel,
                    onCompleteSet: {
                        if isCurrent {
                            viewModel.updateCurrentExerciseDropsetConfiguration()
                            if let weightValue = Double(weight),
                               let repsValue = Int(reps) {
                                viewModel.completeSet(weight: weightValue, reps: repsValue, isWarmup: currentSetIsWarmup)
                                currentSetIsWarmup = false
                            }
                        }
                    },
                    onUndoSet: {
                        if isCurrent {
                            viewModel.undoLastSet()
                        }
                    },
                    onSelectAlternative: { alternativeName in
                        if isCurrent {
                            viewModel.switchToAlternative(alternativeName: alternativeName)
                        }
                    },
                    onExerciseNameTapped: {
                        if isCurrent {
                            selectedExerciseForHistory = exercise.name
                            viewModel.showExerciseHistory = true
                        }
                    }
                )
                .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
                )
                .onAppear {
                    if isCurrent {
                        viewModel.syncDropsetStateFromCurrentExercise()
                        if let lastWeight = viewModel.getLastWeight(for: exercise.name), lastWeight > 0 {
                            weight = String(format: "%.0f", lastWeight)
                        }
                    }
                }
            }
        }
        // Context menu on every card for quick delete (follows HIG: destructive action via contextual affordance)
        .contextMenu {
            if let workout = viewModel.currentWorkout,
               let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                Button(role: .destructive) {
                    if !exercise.sets.isEmpty {
                        // Confirm before deleting if there are completed sets
                        showDeleteExerciseConfirmation = true
                        exerciseToDelete = index
                    } else {
                        viewModel.removeExercise(at: index)
                    }
                } label: {
                    Label("Delete Exercise", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, isCurrent ? 8 : 4)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                // Header
                WorkoutHeader(
                    title: viewModel.currentWorkout?.name ?? "Workout",
                    totalVolume: viewModel.totalWorkoutVolume,
                    elapsedTime: viewModel.formatTime(viewModel.elapsedTime),
                    autoAdvanceEnabled: viewModel.autoAdvanceEnabled,
                    onPause: { viewModel.pauseWorkout() },
                    onFinish: { showFinishConfirmation = true },
                    onSettings: { viewModel.showSettingsSheet = true },
                    onToggleAutoAdvance: { viewModel.toggleAutoAdvance() }
                )
                .id("header-\(viewModel.totalWorkoutVolume)-\(viewModel.elapsedTime)")
                
                // Sticky Rest Timer (always visible)
                VStack(spacing: 0) {
                    if viewModel.restTimerActive {
                        RestTimerView(
                            timeRemaining: max(0, viewModel.restTimeRemaining),
                            totalDuration: max(1, viewModel.restTimerTotalDuration),
                            onSkip: { viewModel.quickSkipRest() },
                            onComplete: { viewModel.completeRest() },
                            onAddTime: { viewModel.addTimeToRest(30) },
                            onSubtractTime: { viewModel.subtractTimeFromRest(30) }
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    } else {
                        // Collapsed/minimal timer view when not active
                        HStack {
                            Image(systemName: "timer")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                            Text("Rest Timer")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("Ready")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.secondary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
                .background(AppColors.card)
                
                // Workout Timer
                WorkoutTimerBar(
                    time: viewModel.formatTime(viewModel.elapsedTime),
                    isPaused: viewModel.isTimerPausedDuringRest,
                    onAbort: {
                        viewModel.resetTimer()
                    }
                )
                
                // Collapsible Exercise Sections
                if let workout = viewModel.currentWorkout {
                    let exercisesBySection = viewModel.exercisesBySection
                    let sectionOrder: [ExerciseSectionType] = [.warmup, .stretch, .workingSets, .cardio]
                    let currentExerciseId = viewModel.currentExercise?.id
                    
                    ForEach(sectionOrder, id: \.self) { sectionType in
                        if let exercises = exercisesBySection[sectionType], !exercises.isEmpty {
                            CollapsibleSectionView(
                                sectionType: sectionType,
                                exercises: exercises,
                                isExpanded: viewModel.expandedSections.contains(sectionType),
                                currentExerciseId: currentExerciseId,
                                onToggle: {
                                    withAnimation(AppAnimations.smooth) {
                                        viewModel.toggleSection(sectionType)
                                    }
                                },
                                onExerciseSelect: { exercise in
                                    // Find and set the exercise index
                                    if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                                        viewModel.currentExerciseIndex = index
                                        viewModel.ensureSectionExpanded(for: exercise)
                                        viewModel.syncDropsetStateFromCurrentExercise()
                                        
                                        // Scroll directly to the tapped exercise card
                                        let exerciseId = "exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)"
                                        withAnimation(AppAnimations.smooth) {
                                            proxy.scrollTo(exerciseId, anchor: .top)
                                        }
                                    }
                                }
                            ) {
                                // Exercise cards content
                                ForEach(exercises) { exercise in
                                    exerciseCardView(
                                        for: exercise,
                                        isCurrent: exercise.id == currentExerciseId
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Allow user to select any exercise card as active
                                        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                                            HapticManager.impact(style: .light)
                                            viewModel.currentExerciseIndex = index
                                            viewModel.ensureSectionExpanded(for: exercise)
                                            viewModel.syncDropsetStateFromCurrentExercise()
                                            
                                            // Scroll to the selected exercise card
                                            let exerciseId = "exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)"
                                            withAnimation(AppAnimations.smooth) {
                                                proxy.scrollTo(exerciseId, anchor: .top)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Legacy single exercise card (hidden, kept for reference)
                if false, let exercise = viewModel.currentExercise {
                    // Check if it's a cardio exercise (time-based, not calisthenics)
                    if viewModel.isCardioExercise(exercise) {
                        // Cardio exercises use hold card for time input
                        CalisthenicsHoldExerciseCard(
                            exercise: exercise,
                            holdDuration: $holdDuration,
                            additionalWeight: $calisthenicsWeight,
                            showPRBadge: viewModel.showPRBadge,
                            prMessage: viewModel.prMessage,
                            onCompleteSet: {
                                if let duration = Int(holdDuration) {
                                    // Cardio exercises don't use additional weight
                                    viewModel.completeCalisthenicsHoldSet(duration: duration, additionalWeight: 0)
                                }
                            }
                        )
                        .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                        .animateOnAppear(delay: 0.1, animation: AppAnimations.smooth)
                        .onAppear {
                            calisthenicsWeight = "0" // Cardio doesn't use weight
                            if exercise.targetHoldDuration != nil {
                                holdDuration = String(exercise.targetHoldDuration ?? 300)
                            } else {
                                holdDuration = "300" // Default 5 minutes
                            }
                        }
                        .onChange(of: viewModel.currentExerciseIndex) {
                            calisthenicsWeight = "0" // Cardio doesn't use weight
                            if exercise.targetHoldDuration != nil {
                                holdDuration = String(exercise.targetHoldDuration ?? 300)
                            } else {
                                holdDuration = "300" // Default 5 minutes
                            }
                        }
                    } else if viewModel.isCalisthenicsExercise(exercise) {
                        // If it's a hold-based calisthenics exercise (has targetHoldDuration), use hold card
                        if exercise.targetHoldDuration != nil {
                            CalisthenicsHoldExerciseCard(
                                exercise: exercise,
                                holdDuration: $holdDuration,
                                additionalWeight: $calisthenicsWeight,
                                showPRBadge: viewModel.showPRBadge,
                                prMessage: viewModel.prMessage,
                                onCompleteSet: {
                                    if let duration = Int(holdDuration),
                                       let weightValue = Double(calisthenicsWeight) {
                                        viewModel.completeCalisthenicsHoldSet(duration: duration, additionalWeight: weightValue)
                                    }
                                }
                            )
                            .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                            .animateOnAppear(delay: 0.1, animation: AppAnimations.smooth)
                            .onAppear {
                                // Load last additional weight for hold-based calisthenics
                                if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                    calisthenicsWeight = String(format: "%.0f", lastWeight)
                                } else {
                                    calisthenicsWeight = "0"
                                }
                                if exercise.targetHoldDuration != nil {
                                    holdDuration = String(exercise.targetHoldDuration ?? 30)
                                }
                            }
                            .onChange(of: viewModel.currentExerciseIndex) {
                                // Load last additional weight when switching exercises
                                if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                    calisthenicsWeight = String(format: "%.0f", lastWeight)
                                } else {
                                    calisthenicsWeight = "0"
                                }
                                if exercise.targetHoldDuration != nil {
                                    holdDuration = String(exercise.targetHoldDuration ?? 30)
                                }
                            }
                        } else {
                            // Rep-based calisthenics exercise (reps + additional weight, NO hold duration)
                            CalisthenicsExerciseCard(
                                exercise: exercise,
                                reps: $calisthenicsReps,
                                additionalWeight: $calisthenicsWeight,
                                showPRBadge: viewModel.showPRBadge,
                                prMessage: viewModel.prMessage,
                                onCompleteSet: {
                                    if let repsValue = Int(calisthenicsReps),
                                       let weightValue = Double(calisthenicsWeight) {
                                        viewModel.completeCalisthenicsSet(reps: repsValue, additionalWeight: weightValue)
                                    }
                                }
                            )
                            .id("exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)")
                            .animateOnAppear(delay: 0.1, animation: AppAnimations.smooth)
                            .onAppear {
                                // Load last additional weight for rep-based calisthenics
                                if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                    calisthenicsWeight = String(format: "%.0f", lastWeight)
                                } else {
                                    calisthenicsWeight = "0"
                                }
                            }
                            .onChange(of: viewModel.currentExerciseIndex) {
                                // Load last additional weight when switching exercises
                                if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                    calisthenicsWeight = String(format: "%.0f", lastWeight)
                                } else {
                                    calisthenicsWeight = "0"
                                }
                                calisthenicsReps = "8"
                            }
                        }
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
                            currentSetIsWarmup: $currentSetIsWarmup,
                            isCollapsed: viewModel.restTimerActive,
                            showUndoButton: viewModel.showUndoButton,
                            barWeight: viewModel.settingsManager.barWeight,
                            currentExerciseVolume: viewModel.currentExerciseVolume,
                            viewModel: viewModel,
                            onCompleteSet: {
                                viewModel.updateCurrentExerciseDropsetConfiguration()
                                if let weightValue = Double(weight),
                                   let repsValue = Int(reps) {
                                    viewModel.completeSet(weight: weightValue, reps: repsValue, isWarmup: currentSetIsWarmup)
                                    currentSetIsWarmup = false
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
                            // Load last weight for current exercise
                            if let exercise = viewModel.currentExercise {
                                if viewModel.isCalisthenicsExercise(exercise) {
                                    // For calisthenics, load last additional weight
                                    if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                        calisthenicsWeight = String(format: "%.0f", lastWeight)
                                    } else {
                                        calisthenicsWeight = "0"
                                    }
                                    // Set default hold duration if it's a hold exercise
                                    if exercise.targetHoldDuration != nil {
                                        holdDuration = String(exercise.targetHoldDuration ?? 30)
                                    }
                                } else {
                                    // For regular exercises, load last weight
                                    if let lastWeight = viewModel.getLastWeight(for: exercise.name), lastWeight > 0 {
                                        weight = String(format: "%.0f", lastWeight)
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.currentExerciseIndex) {
                            viewModel.syncDropsetStateFromCurrentExercise()
                            // Load last weight when switching exercises
                            if let exercise = viewModel.currentExercise {
                                if viewModel.isCalisthenicsExercise(exercise) {
                                    // For calisthenics, load last additional weight
                                    if let lastWeight = viewModel.getLastWeight(for: exercise.name) {
                                        calisthenicsWeight = String(format: "%.0f", lastWeight)
                                    } else {
                                        calisthenicsWeight = "0"
                                    }
                                    if exercise.targetHoldDuration != nil {
                                        holdDuration = String(exercise.targetHoldDuration ?? 30)
                                    } else {
                                        calisthenicsReps = "8"
                                    }
                                } else {
                                    // For regular exercises, load last weight
                                    if let lastWeight = viewModel.getLastWeight(for: exercise.name), lastWeight > 0 {
                                        weight = String(format: "%.0f", lastWeight)
                                    }
                                }
                            }
                        }
                        .onChange(of: exercise.sets.count) { _, _ in
                            // Force update when sets change - volume will recalculate
                        }
                    }
                }
                
                // PR Badge (shown when PR is achieved, appears below sticky timer)
                if viewModel.showPRBadge && !viewModel.restTimerActive {
                    VStack(spacing: 16) {
                        if !viewModel.prMessage.isEmpty {
                            PRBadge(message: viewModel.prMessage)
                                .transition(.scale.combined(with: .opacity))
                                .animation(AppAnimations.celebration, value: viewModel.showPRBadge)
                                .zIndex(10)
                                .id("pr-badge-\(viewModel.prMessage)")
                                .onAppear {
                                    Logger.info("✅ PR BADGE VIEW APPEARED: '\(viewModel.prMessage)'", category: .general)
                                }
                        } else {
                            // Debug: Badge flag is true but message is empty
                            Text("PR Badge Debug: showPRBadge=true but prMessage is empty")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .onChange(of: viewModel.showPRBadge) { oldValue, newValue in
                        Logger.debug("PR Badge state changed: \(oldValue) -> \(newValue), message: '\(viewModel.prMessage)'", category: .general)
                    }
                    .onChange(of: viewModel.prMessage) { oldValue, newValue in
                        Logger.debug("PR Message changed: '\(oldValue)' -> '\(newValue)', showPRBadge: \(viewModel.showPRBadge)", category: .general)
                    }
                }
                
                // PR Badge (shown beneath rest timer when active)
                if viewModel.showPRBadge && viewModel.restTimerActive {
                    VStack(spacing: 16) {
                        if !viewModel.prMessage.isEmpty {
                            PRBadge(message: viewModel.prMessage)
                                .transition(.scale.combined(with: .opacity))
                                .animation(AppAnimations.celebration, value: viewModel.showPRBadge)
                                .zIndex(10)
                                .id("pr-badge-\(viewModel.prMessage)")
                                .onAppear {
                                    Logger.info("✅ PR BADGE VIEW APPEARED: '\(viewModel.prMessage)'", category: .general)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // Alternative Exercises Section (appears after rest timer)
                if let exercise = viewModel.currentExercise, !viewModel.isCalisthenicsExercise(exercise) {
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
                                
                Spacer()
                    .frame(height: 100)
                }
            }
            .onChange(of: viewModel.readyForNextSet) { _, _ in
                // Automatically scroll to exercise card when ready for next set
                if let exercise = viewModel.currentExercise {
                    // Ensure section is expanded
                    viewModel.ensureSectionExpanded(for: exercise)
                    let exerciseId = "exercise-\(exercise.id)-\(viewModel.currentExerciseVolume)-\(exercise.sets.count)"
                    withAnimation(AppAnimations.smooth) {
                        proxy.scrollTo(exerciseId, anchor: .top)
                    }
                }
            }
            .onAppear {
                // Ensure current exercise's section is expanded on view appear
                if let exercise = viewModel.currentExercise {
                    viewModel.ensureSectionExpanded(for: exercise)
                }
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
        .alert("Delete Exercise?", isPresented: $showDeleteExerciseConfirmation) {
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let index = exerciseToDelete {
                    viewModel.removeExercise(at: index)
                }
                exerciseToDelete = nil
            }
        } message: {
            if let index = exerciseToDelete,
               let workout = viewModel.currentWorkout,
               index < workout.exercises.count {
                Text("Are you sure you want to delete '\(workout.exercises[index].name)'? This will remove all completed sets for this exercise.")
            } else {
                Text("Are you sure you want to delete this exercise? This will remove all completed sets.")
            }
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
    let elapsedTime: String
    let autoAdvanceEnabled: Bool
    let onPause: () -> Void
    let onFinish: () -> Void
    let onSettings: () -> Void
    let onToggleAutoAdvance: () -> Void
    
    private func formatVolume(_ volume: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: volume)) ?? "\(volume)"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTypography.largeTitleBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                HStack(spacing: 8) {
                    if totalVolume > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                            Text("\(formatVolume(totalVolume)) lbs")
                                .contentTransition(.numericText())
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColors.accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(elapsedTime)
                            .contentTransition(.numericText())
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.secondary.opacity(0.6))
                    .clipShape(Capsule())
                    
                    // If we want exercise count in the future, we can add it back here as a lightweight label
                }
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Auto-Advance Toggle
                if autoAdvanceEnabled {
                    Button(action: {
                        onToggleAutoAdvance()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                            Text("Auto")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppColors.primary)
                        .frame(width: 60, height: 44)
                        .background(AppColors.primary.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Auto-advance enabled")
                } else {
                    Button(action: {
                        onToggleAutoAdvance()
                    }) {
                        Image(systemName: "bolt.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.border.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Auto-advance disabled")
                }
                
                HelpButton(pageType: .workout)
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppColors.border.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Settings")
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onPause()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(AppColors.border.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Pause Workout")
                
                Button(action: {
                    HapticManager.success()
                    onFinish()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.alabasterGrey)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Finish Workout")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct WorkoutTimerBar: View {
    let time: String
    let isPaused: Bool
    let onAbort: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Large centered timer with Akira Expanded font
            Text(time)
                .font(.custom("Akira Expanded", size: 56))
                .foregroundStyle(isPaused ? AnyShapeStyle(AppColors.accent) : AnyShapeStyle(LinearGradient.primaryGradient))
                .contentTransition(.numericText())
                .animation(AppAnimations.quick, value: time)
                .frame(maxWidth: .infinity)
            
            if isPaused {
                Text("(Paused)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.accent)
            }
            
            // Reset button
            Button(action: {
                HapticManager.impact(style: .medium)
                onAbort()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15))
                    Text("Reset Timer")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.card)
                .clipShape(Capsule())
                .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Reset Timer")
            .accessibilityHint("Resets the workout timer to zero")
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
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
    @Binding var currentSetIsWarmup: Bool
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
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: exercise.name)
    }
    
    private var collapsedView: some View {
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
    }
    
    var body: some View {
        CategoryBorderedCard(muscleGroup: exercise.name, borderWidth: 3) {
            VStack(alignment: .leading, spacing: 0) {
                // Removed top gradient bar in favor of gradient border
                
                if isCollapsed {
                    collapsedView
                } else {
                    expandedView
                }
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var expandedView: some View {
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
                            
                            VStack(alignment: .leading, spacing: 12) {
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
                                
                                // Set Progress Dots
                                HStack(spacing: 8) {
                                    ForEach(1...exercise.targetSets, id: \.self) { setNumber in
                                        Circle()
                                            .fill(setNumber <= exercise.sets.count ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                            .frame(width: setNumber <= exercise.sets.count ? 10 : 8, height: setNumber <= exercise.sets.count ? 10 : 8)
                                            .overlay(
                                                Circle()
                                                    .stroke(setNumber == exercise.currentSet ? AppColors.primary : Color.clear, lineWidth: 2)
                                                    .padding(-2)
                                            )
                                            .animation(AppAnimations.snappy, value: exercise.sets.count)
                                    }
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
                    
                    // Core Inputs - Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .font(AppTypography.subheadlineMedium)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(spacing: 12) {
                            // Decrement button
                            Button(action: {
                                if let currentWeight = Double(weight) {
                                    weight = String(format: "%.0f", max(0, currentWeight - 5))
                                    HapticManager.impact(style: .light)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.primary)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Weight display/input
                            TextField("0", text: $weight)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .inputFieldStyle()
                            
                            Text("lbs")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 40, alignment: .leading)
                            
                            // Increment button
                            Button(action: {
                                if let currentWeight = Double(weight) {
                                    weight = String(format: "%.0f", currentWeight + 5)
                                    HapticManager.impact(style: .light)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.primary)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    
                    // Core Inputs - Reps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps")
                            .font(AppTypography.subheadlineMedium)
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(spacing: 12) {
                            // Decrement button
                            Button(action: {
                                if let currentReps = Int(reps), currentReps > 1 {
                                    reps = String(currentReps - 1)
                                    HapticManager.impact(style: .light)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Reps display/input
                            TextField("0", text: $reps)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .inputFieldStyle()
                            
                            Text("reps")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 40, alignment: .leading)
                            
                            // Increment button
                            Button(action: {
                                if let currentReps = Int(reps) {
                                    reps = String(currentReps + 1)
                                    HapticManager.impact(style: .light)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Quick preset buttons
                        HStack(spacing: 8) {
                            ForEach([5, 8, 10, 12, 15], id: \.self) { preset in
                                Button(action: {
                                    reps = String(preset)
                                    HapticManager.impact(style: .light)
                                }) {
                                    Text("\(preset)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(reps == String(preset) ? AppColors.alabasterGrey : AppColors.foreground)
                                        .frame(minWidth: 44, minHeight: 32)
                                        .background(reps == String(preset) ? AppColors.accent : AppColors.secondary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    // Advanced helpers: suggestions & plates (styled card)
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            // Smart Weight Suggestions
                            SmartWeightSuggestion(
                                exerciseName: exercise.name,
                                weight: $weight,
                                reps: $reps
                            )
                            
                            // Plate Calculator
                            if let weightValue = Double(weight), weightValue > 0 {
                                PlateCalculator(weight: weightValue, barWeight: barWeight)
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Suggestions & plates")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(AppColors.secondary.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
                    )
                    
                    // Warm-up Toggle (compact pill)
                    Button(action: {
                        currentSetIsWarmup.toggle()
                        HapticManager.impact(style: .light)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: currentSetIsWarmup ? "flame.fill" : "flame")
                                .font(.system(size: 13))
                            Text("Warm-up")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(currentSetIsWarmup ? .orange : AppColors.mutedForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(currentSetIsWarmup ? Color.orange.opacity(0.15) : AppColors.secondary.opacity(0.8))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Dropset Configuration (progressive disclosure, styled)
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $dropsetsEnabled) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(dropsetsEnabled ? AppColors.accent : AppColors.mutedForeground)
                                    Text("Enable dropsets")
                                        .font(.system(size: 15, weight: .semibold))
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
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Dropsets")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(AppColors.secondary.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
                    )
                
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
                
                // Complete Set Button - Enhanced
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onCompleteSet()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                        Text("Complete Set")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(AppColors.alabasterGrey)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        ZStack {
                            LinearGradient.accentGradient
                            
                            // Subtle shimmer effect
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large))
                    .applyElevation(.prominent)
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
        }
    }
} // Close ExerciseCard struct

// MARK: - Calisthenics Exercise Card (Reps + Additional Weight)
struct CalisthenicsExerciseCard: View {
    let exercise: Exercise
    @Binding var reps: String
    @Binding var additionalWeight: String
    let showPRBadge: Bool
    let prMessage: String
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
                
                // PR Badge
                if showPRBadge {
                    PRBadge(message: prMessage)
                        .transition(.scaleWithFade)
                        .zIndex(10)
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
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

// MARK: - Cardio Exercise Card (Time + Sets)
struct CardioExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
    let showPRBadge: Bool
    let prMessage: String
    let onCompleteSet: () -> Void
    
    var body: some View {
        CategoryBorderedCard(muscleGroup: exercise.name) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text("Cardio • Set \(exercise.currentSet) of \(exercise.targetSets)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                }
                
                // PR Badge
                if showPRBadge {
                    PRBadge(message: prMessage)
                        .transition(.scaleWithFade)
                        .zIndex(10)
                }
                
                // Time input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration (seconds)")
                        .font(AppTypography.subheadlineMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 12) {
                        TextField("0", text: $holdDuration)
                            .keyboardType(.numberPad)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .inputFieldStyle()
                        
                        Text("sec")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(width: 40, alignment: .leading)
                    }
                }
                
                // Quick duration presets
                HStack(spacing: 8) {
                    ForEach([60, 120, 180, 300], id: \.self) { preset in
                        Button(action: {
                            holdDuration = String(preset)
                            HapticManager.impact(style: .light)
                        }) {
                            Text("\(preset / 60)m")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(holdDuration == String(preset) ? AppColors.alabasterGrey : AppColors.foreground)
                                .frame(minWidth: 44, minHeight: 32)
                                .background(holdDuration == String(preset) ? AppColors.accent : AppColors.secondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                // Set progress dots
                HStack(spacing: 8) {
                    ForEach(1...exercise.targetSets, id: \.self) { setNumber in
                        Circle()
                            .fill(setNumber <= exercise.sets.count ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .frame(width: setNumber <= exercise.sets.count ? 10 : 8, height: setNumber <= exercise.sets.count ? 10 : 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Complete set
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onCompleteSet()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("Complete Cardio Set")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
// MARK: - Stretch Exercise Card (Sets Only)
struct StretchExerciseCard: View {
    let exercise: Exercise
    let onCompleteSet: () -> Void
    
    var body: some View {
        CategoryBorderedCard(muscleGroup: exercise.name) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "figure.cooldown")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text("Stretch • Set \(exercise.currentSet) of \(exercise.targetSets)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                }
                
                // Set progress dots (no weight/reps)
                HStack(spacing: 8) {
                    ForEach(1...exercise.targetSets, id: \.self) { setNumber in
                        Circle()
                            .fill(setNumber <= exercise.sets.count ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .frame(width: setNumber <= exercise.sets.count ? 10 : 8, height: setNumber <= exercise.sets.count ? 10 : 8)
                    }
                }
                
                // Guidance text
                Text("Focus on slow, controlled breathing and a gentle stretch. Move through each set at your own pace.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Complete Set button
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onCompleteSet()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("Complete Stretch Set")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(AppColors.accentForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

// MARK: - Calisthenics Hold Exercise Card (Hold Duration + Additional Weight)
struct CalisthenicsHoldExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
    @Binding var additionalWeight: String
    let showPRBadge: Bool
    let prMessage: String
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
                        Image(systemName: "timer")
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
                
                // PR Badge
                if showPRBadge {
                    PRBadge(message: prMessage)
                        .transition(.scaleWithFade)
                        .zIndex(10)
                }
                
                // Hold Duration Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hold Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 12) {
                        TextField("", text: $holdDuration)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Text("seconds")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
                
                // Additional Weight Input
                InputField(
                    label: "Additional Weight",
                    value: $additionalWeight,
                    unit: "lbs",
                    keyboardType: .decimalPad,
                    isWeight: true
                )
                
                // Quick Duration Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Select")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach([15, 30, 45, 60], id: \.self) { duration in
                            Button(action: {
                                holdDuration = String(duration)
                            }) {
                                Text("\(duration)s")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(holdDuration == String(duration) ? AppColors.alabasterGrey : AppColors.foreground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(holdDuration == String(duration) ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            // Reset additional weight to 0 if empty
            if additionalWeight.isEmpty {
                additionalWeight = "0"
            }
            // Set default hold duration if available
            if holdDuration.isEmpty, let targetDuration = exercise.targetHoldDuration {
                holdDuration = String(targetDuration)
            }
        }
    }
}

struct PRBadge: View {
    let message: String
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -15
    @State private var glowIntensity: Double = 0
    @State private var showConfetti = false
    @State private var shimmerPhase: CGFloat = -200
    
    private var confettiView: some View {
        Group {
            if showConfetti {
                ForEach(0..<12) { index in
                    confettiParticle(index: index)
                }
            }
        }
    }
    
    private func confettiParticle(index: Int) -> some View {
        let iconNames = ["star.fill", "sparkles", "star.circle.fill"]
        let colors: [Color] = [.yellow, .orange, .white]
        
        return Image(systemName: iconNames[index % 3])
            .font(.system(size: CGFloat.random(in: 10...16)))
            .foregroundColor(colors[index % 3])
            .offset(
                x: cos(Double(index) * .pi / 6) * Double.random(in: 40...80),
                y: sin(Double(index) * .pi / 6) * Double.random(in: 40...80)
            )
            .opacity(showConfetti ? 0 : 1)
            .scaleEffect(showConfetti ? 0.3 : 1.2)
            .animation(
                Animation.easeOut(duration: 0.8)
                    .delay(Double(index) * 0.05),
                value: showConfetti
            )
    }
    
    private var badgeContent: some View {
        HStack(spacing: 12) {
                // Gold trophy with gradient
                ZStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FFD700")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.yellow.opacity(0.6), radius: 8, x: 0, y: 0)
                        .rotationEffect(.degrees(rotation))
                    
                    // Shimmer overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 40)
                    .offset(x: shimmerPhase)
                    .mask(
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 32, weight: .bold))
                    )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW PR!")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "FFD700"))
                        .tracking(1)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.alabasterGrey)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .background(
                ZStack {
                    // Dark background with gold accent
                    LinearGradient(
                        colors: [
                            Color(hex: "1a1a1a"),
                            Color(hex: "2d2d2d")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Gold border glow
                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FFD700").opacity(0.8), Color(hex: "FFA500").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large))
            .scaleEffect(scale)
            .shadow(color: Color(hex: "FFD700").opacity(0.5 + glowIntensity), radius: 20 + (glowIntensity * 10), x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    var body: some View {
        ZStack {
            confettiView
            badgeContent
        }
        .onAppear {
            // Trigger strong haptic feedback
            HapticManager.success()
            HapticManager.impact(style: .heavy)
            
            // Explosive entrance animation
            withAnimation(AppAnimations.bouncy) {
                scale = 1.15
                rotation = 5
                showConfetti = true
            }
            
            // Shimmer animation
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerPhase = 200
            }
            
            // Pulsing glow
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                glowIntensity = 0.4
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
    let onDelete: ((Int) -> Void)?
    let onMoveUp: ((Int) -> Void)?
    let onMoveDown: ((Int) -> Void)?
    
    // Count only working sets (exclude warm-up sets)
    private func workingSetsCount(for exercise: Exercise) -> Int {
        return exercise.sets.filter { !$0.isWarmup }.count
    }
    
    // Check if exercise is completed
    private func isExerciseCompleted(_ exercise: Exercise) -> Bool {
        let workingSets = workingSetsCount(for: exercise)
        return workingSets >= exercise.targetSets
    }
    
    private func exerciseButtonContent(exercise: Exercise, index: Int) -> some View {
        let workingSets = workingSetsCount(for: exercise)
        let isCompleted = isExerciseCompleted(exercise)
        let isSelected = index == currentIndex
        
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.foreground)
                    .lineLimit(1)
                
                // Checkmark for completed exercises
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.accent)
                }
            }
            
            Text("\(workingSets)/\(exercise.targetSets)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? AppColors.alabasterGrey.opacity(0.8) : AppColors.mutedForeground)
                .contentTransition(.numericText())
                .animation(AppAnimations.quick, value: workingSets)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(buttonBackground(isSelected: isSelected, isCompleted: isCompleted))
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(AppAnimations.snappy, value: currentIndex)
        .animation(AppAnimations.snappy, value: isCompleted)
    }
    
    @ViewBuilder
    private func buttonBackground(isSelected: Bool, isCompleted: Bool) -> some View {
        if isSelected {
            Capsule()
                .fill(LinearGradient.primaryGradient)
                .shadow(color: AppColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
        } else if isCompleted {
            Capsule()
                .fill(AppColors.accent.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(AppColors.accent.opacity(0.4), lineWidth: 1.5)
                )
        } else {
            Capsule()
                .fill(AppColors.secondary)
                .overlay(
                    Capsule()
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    Button(action: {
                        HapticManager.impact(style: .light)
                        withAnimation(AppAnimations.snappy) {
                            onSelect(index)
                        }
                    }) {
                        exerciseButtonContent(exercise: exercise, index: index)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        if let onMoveUp = onMoveUp, index > 0 {
                            Button {
                                onMoveUp(index)
                            } label: {
                                Label("Move Earlier", systemImage: "arrow.left")
                            }
                        }
                        
                        if let onMoveDown = onMoveDown, index < exercises.count - 1 {
                            Button {
                                onMoveDown(index)
                            } label: {
                                Label("Move Later", systemImage: "arrow.right")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive, action: {
                                onDelete(index)
                            }) {
                                Label("Delete Exercise", systemImage: "trash")
                            }
                        }
                    }
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
    @State private var showMasterExerciseList = false
    @State private var showCSVImportAlert = false
    @State private var csvImportMessage = ""
    @State private var csvImportSuccess = false
    
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
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
                    
                    // Apple Health Section
                    AppleHealthSettingsSection()
                    
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
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
                    
                    // Exercise Database Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercise Database")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("Manage all exercises in the database")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                HapticManager.impact(style: .light)
                                showMasterExerciseList = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.system(size: 20))
                                    Text("View All Exercises (\(ExRxDirectoryManager.shared.getAllExercises().count))")
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
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
                    
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
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
                    
                    // Help & Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Help & Support")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Button(action: {
                            HapticManager.impact(style: .medium)
                            OnboardingManager.shared.resetTutorial()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Show Tutorial")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.mutedForeground)
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
                        
                        Text("Learn how to use Ascend's key features and navigate the app")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.top, -8)
                    }
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
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
            .sheet(isPresented: $showMasterExerciseList) {
                MasterExerciseListView()
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
            .alert(csvImportSuccess ? "Import Successful" : "Import Error", isPresented: $showCSVImportAlert) {
                Button("OK") {
                    showCSVImportAlert = false
                    csvImportMessage = ""
                }
            } message: {
                Text(csvImportMessage)
            }
        }
    }
    
    private func importCSVExercises() {
        // Try to find CSV file in app bundle
        var csvPath: String?
        
        let possibleNames = [
            "exercises",  // Primary name - matches the file in the project
            "Gym Exercise Dataset export 2025-12-16 07-12-04",
            "gym-exercises",
            "exercise-dataset"
        ]
        
        // First, try Bundle.main.path(forResource:ofType:) - works for files at bundle root
        for name in possibleNames {
            if let bundlePath = Bundle.main.path(forResource: name, ofType: "csv") {
                csvPath = bundlePath
                Logger.info("📚 Found CSV in app bundle: \(name).csv", category: .general)
                break
            }
        }
        
        // If not found, try searching in bundle directory structure
        if csvPath == nil {
            if let bundleURL = Bundle.main.resourceURL {
                let possiblePaths = [
                    bundleURL.appendingPathComponent("exercises.csv"),
                    bundleURL.appendingPathComponent("Ascend/exercises.csv"),
                    bundleURL.appendingPathComponent("Gym Exercise Dataset export 2025-12-16 07-12-04.csv")
                ]
                
                for url in possiblePaths {
                    if FileManager.default.fileExists(atPath: url.path) {
                        csvPath = url.path
                        Logger.info("📚 Found CSV in bundle directory: \(url.lastPathComponent)", category: .general)
                        break
                    }
                }
            }
        }
        
        // Fallback to Downloads folder (for development only)
        if csvPath == nil {
            let downloadsPath = "/Users/brennenmeregillano/Downloads/Gym Exercise Dataset export 2025-12-16 07-12-04.csv"
            if FileManager.default.fileExists(atPath: downloadsPath) {
                csvPath = downloadsPath
                Logger.info("📚 Found CSV in Downloads folder (development)", category: .general)
            }
        }
        
        guard let path = csvPath, FileManager.default.fileExists(atPath: path) else {
            // Provide more detailed error message with debugging info
            var errorDetails = "CSV file not found.\n\nSearched locations:\n"
            errorDetails += "• exercises.csv in bundle\n"
            if let bundleURL = Bundle.main.resourceURL {
                errorDetails += "• Bundle resource path: \(bundleURL.path)\n"
                // List files in bundle for debugging
                if let files = try? FileManager.default.contentsOfDirectory(atPath: bundleURL.path) {
                    let csvFiles = files.filter { $0.hasSuffix(".csv") }
                    if !csvFiles.isEmpty {
                        errorDetails += "\nFound CSV files in bundle:\n"
                        csvFiles.forEach { errorDetails += "• \($0)\n" }
                    } else {
                        errorDetails += "\nNo CSV files found in bundle directory.\n"
                    }
                }
            }
            csvImportMessage = errorDetails
            csvImportSuccess = false
            showCSVImportAlert = true
            Logger.error("❌ CSV file not found in bundle. Bundle path: \(Bundle.main.resourceURL?.path ?? "unknown")", category: .general)
            return
        }
        
        // Clear existing imported exercises if re-importing
        let existingCount = ExRxDirectoryManager.shared.getImportedExerciseCount()
        if existingCount > 0 {
            ExRxDirectoryManager.shared.clearImportedExercises()
        }
        
        // Import exercises
        do {
            let stats = try CSVExerciseImporter.shared.importExercisesFromFile(at: path)
            csvImportMessage = "Successfully imported \(stats.finalCount) exercises!\n\nTotal rows: \(stats.totalRows)\nParsed: \(stats.parsed)\nSkipped: \(stats.skipped)\nDuplicates removed: \(stats.duplicatesRemoved)"
            csvImportSuccess = true
            Logger.info("✅ CSV import successful: \(stats)", category: .general)
        } catch {
            csvImportMessage = "Failed to import CSV: \(error.localizedDescription)"
            csvImportSuccess = false
            Logger.error("❌ CSV import failed", error: error, category: .general)
        }
        
        showCSVImportAlert = true
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
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

// MARK: - Apple Health Settings Section
struct AppleHealthSettingsSection: View {
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequestingAuthorization = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("Apple Health")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.foreground)
            }
            
            Text("Sync your workouts with Apple Health to track your fitness progress across all your apps.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
            
            // Connection Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(healthKitManager.isAuthorized ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(healthKitManager.isAuthorized ? "Connected" : "Not Connected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                    }
                    
                    Text(statusDescription)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Connect/Reconnect Button
            Button(action: {
                requestAuthorization()
            }) {
                HStack {
                    Image(systemName: healthKitManager.isAuthorized ? "arrow.clockwise" : "link")
                        .font(.system(size: 16, weight: .semibold))
                    Text(healthKitManager.isAuthorized ? "Reconnect" : "Connect to Apple Health")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(isRequestingAuthorization ? 0.6 : 1.0)
            }
            .disabled(isRequestingAuthorization)
            
            if healthKitManager.isAuthorized {
                Text("Your workouts will automatically sync to Apple Health when you complete them.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(.top, -8)
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            healthKitManager.checkAuthorizationStatus()
        }
        .alert("HealthKit Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusDescription: String {
        if !HKHealthStore.isHealthDataAvailable() {
            return "HealthKit is not available on this device"
        }
        
        switch healthKitManager.authorizationStatus {
        case .notDetermined:
            return "Tap Connect to authorize access"
        case .sharingDenied:
            return "Access denied. Enable in Settings > Privacy & Security > Health"
        case .sharingAuthorized:
            return "Workouts will sync automatically"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private func requestAuthorization() {
        isRequestingAuthorization = true
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                await MainActor.run {
                    isRequestingAuthorization = false
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    isRequestingAuthorization = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Section Indicator
struct SectionIndicator: View {
    let sectionType: ExerciseSectionType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: sectionType.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(sectionColor)
            
            Text(sectionType.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(sectionColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(sectionColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(sectionColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var sectionColor: Color {
        switch sectionType {
        case .warmup:
            return .orange
        case .stretch:
            return .blue
        case .workingSets:
            return AppColors.primary
        case .cardio:
            return .red
        }
    }
}

// MARK: - Collapsible Section View
struct CollapsibleSectionView<Content: View>: View {
    let sectionType: ExerciseSectionType
    let exercises: [Exercise]
    let isExpanded: Bool
    let currentExerciseId: UUID?
    let onToggle: () -> Void
    let onExerciseSelect: (Exercise) -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: {
                HapticManager.impact(style: .light)
                onToggle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: sectionType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(sectionColor)
                        .frame(width: 24)
                    
                    Text(sectionType.displayName)
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(exercises.count)")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(sectionColor.opacity(0.1))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Exercises (shown when expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    content
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sectionColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private var sectionColor: Color {
        switch sectionType {
        case .warmup:
            return .orange
        case .stretch:
            return .blue
        case .workingSets:
            return AppColors.primary
        case .cardio:
            return .red
        }
    }
}

#Preview {
    WorkoutView(viewModel: WorkoutViewModel(settingsManager: SettingsManager()))
}
