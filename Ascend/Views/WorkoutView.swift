//
//  WorkoutView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI
import HealthKit

// MARK: - Redesigned Workout View
struct WorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.kineticPalette) private var kp
    @State private var showFinishConfirmation = false
    @State private var showHelpSheet = false
    @State private var showCancelConfirmation = false
    @State private var autoAdvanceToggle: Bool = false
    @State private var calisthenicsReps: String = "8"
    @State private var calisthenicsWeight: String = "0"
    @State private var holdDuration: String = "30"
    @State private var isVerticalLayout: Bool = false
    @State private var selectedSegment: WorkoutTimerSegment = .workout

    enum WorkoutTimerSegment: String, CaseIterable {
        case workout = "Workout"
        case timer = "Timer"

        var icon: String {
            switch self {
            case .workout: return "dumbbell.fill"
            case .timer: return "timer"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            WorkoutTimerSegmentBar(
                selectedSegment: $selectedSegment,
                useKineticChrome: selectedSegment == .workout
            )
            if selectedSegment == .workout {
                exercisesScrollContent
            } else {
                SportsTimerView(isEmbedded: true)
            }
        }
        .background(kp.background)
        .kineticDynamicTypeClamp()
        .id(AppColors.themeID)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: autoAdvanceToggle) { _, _ in
            viewModel.toggleAutoAdvance()
        }
        .onAppear {
            autoAdvanceToggle = viewModel.autoAdvanceEnabled
        }
        .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Finish", role: .destructive) { viewModel.finishWorkout() }
        } message: {
            Text("Are you sure you want to finish this workout? This action cannot be undone.")
        }
        .alert("Cancel Workout?", isPresented: $showCancelConfirmation) {
            Button("Keep Going", role: .cancel) { }
            Button("Cancel Workout", role: .destructive) { viewModel.cancelWorkout() }
        } message: {
            Text("Are you sure you want to cancel this workout? All progress will be lost.")
        }
        .sheet(isPresented: $viewModel.showAddExerciseSheet) {
            AddExerciseView(
                onAdd: { name, sets, type, holdDuration in
                    let duration: Int? = (type == .hold) ? holdDuration : nil
                    viewModel.addExercise(name: name, targetSets: sets, type: type, holdDuration: duration)
                    viewModel.showAddExerciseSheet = false
                },
                onCancel: { viewModel.showAddExerciseSheet = false }
            )
        }
        .sheet(isPresented: $viewModel.showExerciseHistory) {
            if let exerciseName = viewModel.currentExercise?.name,
               let progressViewModel = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exerciseName, progressViewModel: progressViewModel)
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
        .sheet(isPresented: $showHelpSheet) {
            PageFeaturesView(pageType: .workout)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedSegment == .workout {
                KineticWorkoutBottomBar(
                    onCancel: { showCancelConfirmation = true },
                    onFinish: { showFinishConfirmation = true }
                )
            }
        }
    }

    private var kineticUpNextExerciseName: String {
        viewModel.currentExercise?.name ?? "Next exercise"
    }

    // Scrollable exercises area — the header has been extracted above.
    private var exercisesScrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    HStack {
                        Spacer(minLength: 0)
                        Menu {
                            Button {
                                viewModel.pauseWorkout()
                            } label: {
                                Label(
                                    viewModel.isTimerPausedDuringRest ? "Resume workout" : "Pause workout",
                                    systemImage: viewModel.isTimerPausedDuringRest ? "play.fill" : "pause.fill"
                                )
                            }
                            Button("Settings", systemImage: "gearshape.fill") {
                                viewModel.showSettingsSheet = true
                            }
                            Toggle("Auto-advance sets", isOn: $autoAdvanceToggle)
                            Button {
                                isVerticalLayout.toggle()
                            } label: {
                                Label(
                                    isVerticalLayout ? "Use horizontal layout" : "Use vertical layout",
                                    systemImage: "rectangle.split.2x1"
                                )
                            }
                            Button("Help", systemImage: "questionmark.circle") {
                                showHelpSheet = true
                            }
                            Divider()
                            Button("Cancel workout", systemImage: "xmark.circle", role: .destructive) {
                                showCancelConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(kp.tertiary)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Workout options")
                    }

                    KineticWorkoutSessionHeader(
                        workoutName: viewModel.currentWorkout?.name ?? "Workout",
                        sessionStart: viewModel.sessionStartTime
                    )

                    if viewModel.restTimerActive {
                        KineticRestTimerBento(
                            timeRemaining: max(0, viewModel.restTimeRemaining),
                            totalDuration: max(1, viewModel.restTimerTotalDuration),
                            upNextExerciseName: kineticUpNextExerciseName,
                            onAdd15: {
                                viewModel.addTimeToRest(15)
                            },
                            onSkip: {
                                viewModel.quickSkipRest()
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id("rest-timer-\(viewModel.restTimeRemaining)")
                    }
                    
                    // PR Celebration Banner (when PR achieved)
                    if viewModel.showPRBadge && !viewModel.prMessage.isEmpty {
                        PRCelebrationBanner(
                            exercise: viewModel.currentExercise?.name ?? "",
                            prMessage: viewModel.prMessage,
                            onDismiss: {
                                viewModel.showPRBadge = false
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id("pr-banner-\(viewModel.prMessage)")
                    }
                    
                    // Exercise Navigation / Vertical List (only if workout has exercises)
                    if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
                        if isVerticalLayout {
                            // Vertically stacked exercises with simple reordering controls
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Text("Exercises (tap to focus, use arrows to reorder)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                .padding(.horizontal, 0)
                                .padding(.top, 4)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Exercise name label above each card
                                            HStack {
                                                Text(exercise.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppColors.textPrimary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 0)
                                            
                                            ZStack(alignment: .topTrailing) {
                                                exerciseCardView(for: exercise)
                                                    .id("exercise-\(exercise.id)")
                                                    .onTapGesture {
                                                        // Focus this exercise as the current one
                                                        if viewModel.currentExerciseIndex != index {
                                                            viewModel.currentExerciseIndex = index
                                                        }
                                                    }
                                                
                                                // Simple up/down controls for reordering
                                                VStack(spacing: 4) {
                                                    if index > 0 {
                                                        Button(action: {
                                                            viewModel.moveExercise(from: index, to: index - 1)
                                                        }) {
                                                            Image(systemName: "chevron.up.circle.fill")
                                                                .font(.system(size: 18, weight: .semibold))
                                                                .foregroundColor(AppColors.primary)
                                                                .shadow(color: AppColors.foreground.opacity(0.4), radius: 2, x: 0, y: 1)
                                                        }
                                                        .accessibilityLabel("Move \(exercise.name) up")
                                                        .accessibilityHint("Moves this exercise earlier in the workout")
                                                    }
                                                    if index < workout.exercises.count - 1 {
                                                        Button(action: {
                                                            viewModel.moveExercise(from: index, to: index + 1)
                                                        }) {
                                                            Image(systemName: "chevron.down.circle.fill")
                                                                .font(.system(size: 18, weight: .semibold))
                                                                .foregroundColor(AppColors.primary)
                                                                .shadow(color: AppColors.foreground.opacity(0.4), radius: 2, x: 0, y: 1)
                                                        }
                                                        .accessibilityLabel("Move \(exercise.name) down")
                                                        .accessibilityHint("Moves this exercise later in the workout")
                                                    }
                                                }
                                                .padding(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Add Exercise Button
                            AddExerciseButton {
                                viewModel.showAddExerciseSheet = true
                            }
                            .padding(.horizontal, 0)
                            .padding(.top, 16)
                        } else {
                            // Original horizontal navigation with a single focused card
                            ExerciseNavigationBar(
                                exercises: workout.exercises,
                                currentIndex: $viewModel.currentExerciseIndex,
                                onExerciseSelect: { index in
                                    viewModel.currentExerciseIndex = index
                                    if let exercise = viewModel.currentExercise {
                                        viewModel.ensureSectionExpanded(for: exercise)
                                        viewModel.syncDropsetStateFromCurrentExercise()
                                        
                                        let exerciseId = "exercise-\(exercise.id)"
                                        withAnimation(.smooth) {
                                            proxy.scrollTo(exerciseId, anchor: .top)
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal, 0)
                            .padding(.top, 8)
                            
                            // Current Exercise Card
                            if let exercise = viewModel.currentExercise {
                                exerciseCardView(for: exercise)
                                    .id("exercise-\(exercise.id)")
                                    .padding(.top, 8)
                            }
                            
                            // Add Exercise Button
                            AddExerciseButton {
                                viewModel.showAddExerciseSheet = true
                            }
                            .padding(.horizontal, 0)
                            .padding(.top, 16)
                        }
                    } else {
                        // Empty state - no exercises yet
                        VStack(spacing: 16) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(LinearGradient.primaryGradient)
                            
                            Text("No Exercises Yet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Add your first exercise to start your workout")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                viewModel.showAddExerciseSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(LinearGradient.primaryGradient)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                }
                .frame(maxWidth: 448)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .onChange(of: viewModel.readyForNextSet) { _, _ in
                if let exercise = viewModel.currentExercise {
                    viewModel.ensureSectionExpanded(for: exercise)
                    let exerciseId = "exercise-\(exercise.id)"
                    withAnimation(.smooth) {
                        proxy.scrollTo(exerciseId, anchor: .top)
                    }
                }
            }
            .onAppear {
                if let exercise = viewModel.currentExercise {
                    viewModel.ensureSectionExpanded(for: exercise)
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseCardView(for exercise: Exercise) -> some View {
        let sectionType = viewModel.getSectionType(for: exercise)
        let isCurrent = viewModel.currentExercise?.id == exercise.id
        
        if sectionType == .stretch {
            // Stretch exercise card - unified design
            StretchExerciseCard(
                exercise: exercise,
                holdDuration: $holdDuration,
                onCompleteSet: {
                    if isCurrent {
                        viewModel.completeStretchSet()
                    }
                },
                viewModel: viewModel
            )
            .id("exercise-\(exercise.id)-stretch-\(exercise.sets.count)")
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
            )
            .onAppear {
                if isCurrent {
                    if let targetHoldDuration = exercise.targetHoldDuration {
                        holdDuration = String(targetHoldDuration)
                    } else {
                        holdDuration = "30"
                    }
                }
            }
            .padding(.horizontal, 0)
        } else if viewModel.isCardioExercise(exercise) {
            // Cardio exercise card - unified design
            CardioExerciseCard(
                exercise: exercise,
                holdDuration: $holdDuration,
                showPRBadge: isCurrent ? viewModel.showPRBadge : false,
                prMessage: isCurrent ? viewModel.prMessage : "",
                onCompleteSet: {
                    if isCurrent, let duration = Int(holdDuration) {
                        viewModel.completeCalisthenicsHoldSet(duration: duration, additionalWeight: 0)
                    }
                },
                viewModel: viewModel
            )
            .id("exercise-\(exercise.id)-cardio-\(exercise.sets.count)")
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? AppColors.primary : Color.clear, lineWidth: isCurrent ? 2 : 0)
            )
            .onAppear {
                if isCurrent {
                    if let target = exercise.targetHoldDuration {
                        holdDuration = String(target)
                    } else {
                        holdDuration = "300"
                    }
                }
            }
            .padding(.horizontal, 0)
        } else if viewModel.isCalisthenicsExercise(exercise) {
            // Calisthenics exercise - use appropriate card based on type
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
                    },
                    viewModel: viewModel
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
                        if let targetHoldDuration = exercise.targetHoldDuration {
                            holdDuration = String(targetHoldDuration)
                        } else {
                            holdDuration = "30"
                        }
                    }
                }
                .padding(.horizontal, 0)
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
                    },
                    viewModel: viewModel
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
                        // Initialize reps if needed
                        if calisthenicsReps.isEmpty {
                            calisthenicsReps = "8"
                        }
                    }
                }
                .padding(.horizontal, 0)
            }
        } else {
            let tags = KineticExerciseTags.tags(for: exercise.name)
            VStack(alignment: .leading, spacing: 16) {
                KineticExerciseTitleRow(
                    exerciseName: exercise.name,
                    tag1: tags.0,
                    tag2: tags.1,
                    onInfo: { viewModel.showExerciseHistory = true }
                )
                SimplifiedWeightedExerciseCard(
                    viewModel: viewModel,
                    exercise: exercise
                )
                kineticCoachingNote(for: exercise.name)
            }
            .padding(.horizontal, 0)
        }
    }

    private func kineticCoachingNote(for exerciseName: String) -> some View {
        let tip: String = {
            if let ex = ExRxDirectoryManager.shared.findExercise(name: exerciseName) {
                return "Focus on \(ex.muscleGroup.lowercased()) engagement. Control the eccentric and breathe steadily through each rep."
            }
            return "Focus on consistent form and controlled tempo. Maintain control through the full range of motion."
        }()
        return HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(kp.primaryContainer.opacity(0.4))
                .frame(width: 2)
            Text(tip)
                .font(Font.custom("Manrope-Medium", size: 12))
                .foregroundStyle(kp.tertiary)
                .lineSpacing(4)
                .padding(.leading, 12)
                .padding(.vertical, 4)
        }
        .padding(16)
        .background(kp.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Workout / Timer Segment Bar

private struct WorkoutTimerSegmentBar: View {
    @Binding var selectedSegment: WorkoutView.WorkoutTimerSegment
    var useKineticChrome: Bool = false
    @Environment(\.kineticPalette) private var kp

    private var selectedTint: Color {
        useKineticChrome ? kp.primary : AppColors.primary
    }

    private var mutedTint: Color {
        useKineticChrome ? kp.tertiary.opacity(0.75) : AppColors.mutedForeground
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WorkoutView.WorkoutTimerSegment.allCases, id: \.self) { segment in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = segment
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: segment.icon)
                            .font(.system(size: 16, weight: selectedSegment == segment ? .semibold : .regular))
                            .foregroundColor(selectedSegment == segment ? selectedTint : mutedTint)
                        Text(segment.rawValue)
                            .font(.system(size: 11, weight: selectedSegment == segment ? .semibold : .regular))
                            .foregroundColor(selectedSegment == segment ? selectedTint : mutedTint)
                        Rectangle()
                            .fill(selectedSegment == segment ? selectedTint : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .background(useKineticChrome ? kp.background : AppColors.background)
        .overlay(alignment: .bottom) {
            if useKineticChrome {
                Rectangle()
                    .fill(kp.surfaceContainerHighest.opacity(0.2))
                    .frame(height: 1)
            } else {
                Divider()
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
            
            // Compact two-row layout on the right to give the title more room
            VStack(alignment: .trailing, spacing: 10) {
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
                }
                
                HStack(spacing: 10) {
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
        VStack(alignment: .leading, spacing: 0) {
            if isCollapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
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
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Set progress: \(exercise.sets.count) of \(exercise.targetSets) sets completed")
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
                            .accessibilityLabel("Decrease weight by 5 pounds")
                            
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
                                .accessibilityLabel("Weight in pounds")
                                .accessibilityValue(weight.isEmpty ? "Not set" : "\(weight) pounds")
                            
                            Text("lbs")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 40, alignment: .leading)
                                .accessibilityHidden(true)
                            
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
                            .accessibilityLabel("Increase weight by 5 pounds")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    
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
                            .accessibilityLabel("Decrease reps by 1")
                            
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
                                .accessibilityLabel("Number of reps")
                                .accessibilityValue(reps.isEmpty ? "Not set" : "\(reps) reps")
                            
                            Text("reps")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 40, alignment: .leading)
                                .accessibilityHidden(true)
                            
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
                            .accessibilityLabel("Increase reps by 1")
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
                                .accessibilityLabel("Set \(preset) reps")
                                .accessibilityAddTraits(reps == String(preset) ? .isSelected : [])
                            }
                        }
                        .accessibilityLabel("Quick rep presets")
                    }
                    .accessibilityElement(children: .contain)
                    
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
                            .font(AppTypography.buttonLarge)
                    }
                    .foregroundColor(AppColors.alabasterGrey)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        ZStack {
                            LinearGradient.primaryGradient
                            
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
                .accessibilityLabel("Complete set")
                .accessibilityHint("Logs your current set with weight and reps")
                
                // Undo Last Set Button
                if showUndoButton {
                    Button(action: onUndoSet) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                                .font(AppTypography.buttonBold)
                            Text("Undo Last Set")
                                .font(AppTypography.subheadlineMedium)
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

// MARK: - Calisthenics Exercise Card (Reps + Additional Weight) - Unified Design
struct CalisthenicsExerciseCard: View {
    let exercise: Exercise
    @Binding var reps: String
    @Binding var additionalWeight: String
    let showPRBadge: Bool
    let prMessage: String
    let onCompleteSet: () -> Void
    
    @State private var showHistory = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: WorkoutViewModel
    
    var canCompleteSet: Bool {
        !reps.isEmpty && Int(reps) != nil && Int(reps)! > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(AppTypography.bodySmallBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    if viewModel.progressViewModel != nil {
                        Button(action: { showHistory = true }) {
                            Label("View History", systemImage: "chart.bar")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Exercise options")
            }
            
            // PR Badge
            if showPRBadge {
                PRBadge(message: prMessage)
                    .transition(.scaleWithFade)
            }
            
            // Input section
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reps")
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("reps", text: $reps)
                        .keyboardType(.numberPad)
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Number of reps")
                        .accessibilityValue(reps.isEmpty ? "Not set" : "\(reps) reps")
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Additional Weight")
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("lbs", text: $additionalWeight)
                        .keyboardType(.decimalPad)
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Additional weight in pounds")
                        .accessibilityValue(additionalWeight.isEmpty || additionalWeight == "0" ? "No additional weight" : "\(additionalWeight) pounds")
                }
                .frame(maxWidth: .infinity)
            }
            
            // Quick rep presets
            HStack(spacing: 8) {
                ForEach([5, 8, 10, 12, 15], id: \.self) { preset in
                    Button(action: {
                        reps = "\(preset)"
                        HapticManager.impact(style: .light)
                    }) {
                        Text("\(preset)")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(reps == "\(preset)" ? .white : AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(reps == "\(preset)" ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Set \(preset) reps")
                    .accessibilityAddTraits(reps == "\(preset)" ? .isSelected : [])
                }
            }
            .accessibilityLabel("Quick rep presets")
            
            // Complete Set button
            Button(action: onCompleteSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(AppTypography.buttonBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canCompleteSet ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canCompleteSet ? AppColors.accent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            .accessibilityLabel("Complete set")
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            if additionalWeight.isEmpty {
                additionalWeight = "0"
            }
        }
        .sheet(isPresented: $showHistory) {
            if let progressVM = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exercise.name, progressViewModel: progressVM)
            }
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = viewModel.currentWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.removeExercise(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This will remove all completed sets for this exercise.")
        }
    }
}

// MARK: - Cardio Exercise Card (Time + Sets) - Unified Design
struct CardioExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
    let showPRBadge: Bool
    let prMessage: String
    let onCompleteSet: () -> Void
    
    @State private var showHistory = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: WorkoutViewModel
    
    var canCompleteSet: Bool {
        !holdDuration.isEmpty && Int(holdDuration) != nil && Int(holdDuration)! > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(AppTypography.bodySmallBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    if viewModel.progressViewModel != nil {
                        Button(action: { showHistory = true }) {
                            Label("View History", systemImage: "chart.bar")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Exercise options")
            }
            
            // PR Badge
            if showPRBadge {
                PRBadge(message: prMessage)
                    .transition(.scaleWithFade)
            }
            
            // Input section
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration")
                    .font(AppTypography.footnoteMedium)
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("seconds", text: $holdDuration)
                    .keyboardType(.numberPad)
                    .font(AppTypography.numberInput)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Duration in seconds")
                    .accessibilityValue(holdDuration.isEmpty ? "Not set" : "\(holdDuration) seconds")
            }
            
            // Quick duration presets
            HStack(spacing: 8) {
                ForEach([60, 120, 180, 300], id: \.self) { preset in
                    Button(action: {
                        holdDuration = "\(preset)"
                        HapticManager.impact(style: .light)
                    }) {
                        Text("\(preset / 60)m")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(holdDuration == "\(preset)" ? .white : AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(holdDuration == "\(preset)" ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Set \(preset / 60) minute\(preset / 60 > 1 ? "s" : "")")
                    .accessibilityAddTraits(holdDuration == "\(preset)" ? .isSelected : [])
                }
            }
            .accessibilityLabel("Quick duration presets")
            
            // Complete Set button
            Button(action: {
                HapticManager.impact(style: .medium)
                onCompleteSet()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(AppTypography.buttonBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canCompleteSet ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canCompleteSet ? AppColors.accent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            .accessibilityLabel("Complete set")
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showHistory) {
            if let progressVM = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exercise.name, progressViewModel: progressVM)
            }
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = viewModel.currentWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.removeExercise(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This will remove all completed sets for this exercise.")
        }
    }
}
// MARK: - Stretch Exercise Card (Time + Sets) - Unified Design
struct StretchExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
    let onCompleteSet: () -> Void
    
    @State private var showHistory = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: WorkoutViewModel
    
    var canCompleteSet: Bool {
        !holdDuration.isEmpty && Int(holdDuration) != nil && Int(holdDuration)! > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(AppTypography.bodySmallBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    if viewModel.progressViewModel != nil {
                        Button(action: { showHistory = true }) {
                            Label("View History", systemImage: "chart.bar")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Exercise options")
            }
            
            // Input section
            VStack(alignment: .leading, spacing: 6) {
                Text("Hold Duration")
                    .font(AppTypography.footnoteMedium)
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("seconds", text: $holdDuration)
                    .keyboardType(.numberPad)
                    .font(AppTypography.numberInput)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Hold duration in seconds")
                    .accessibilityValue(holdDuration.isEmpty ? "Not set" : "\(holdDuration) seconds")
            }
            
            // Quick duration presets
            HStack(spacing: 8) {
                ForEach([15, 30, 45, 60], id: \.self) { preset in
                    Button(action: {
                        holdDuration = "\(preset)"
                        HapticManager.impact(style: .light)
                    }) {
                        Text("\(preset)s")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(holdDuration == "\(preset)" ? .white : AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(holdDuration == "\(preset)" ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Set \(preset) seconds")
                    .accessibilityAddTraits(holdDuration == "\(preset)" ? .isSelected : [])
                }
            }
            .accessibilityLabel("Quick duration presets")
            
            // Guidance text
            Text("Focus on slow, controlled breathing and a gentle stretch.")
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
            
            // Complete Set button
            Button(action: {
                HapticManager.impact(style: .medium)
                onCompleteSet()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(AppTypography.buttonBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canCompleteSet ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canCompleteSet ? AppColors.accent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            .accessibilityLabel("Complete set")
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(AppTypography.captionBold)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showHistory) {
            if let progressVM = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exercise.name, progressViewModel: progressVM)
            }
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = viewModel.currentWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.removeExercise(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This will remove all completed sets for this exercise.")
        }
    }
}

// MARK: - Calisthenics Hold Exercise Card (Hold Duration + Additional Weight) - Unified Design
struct CalisthenicsHoldExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
    @Binding var additionalWeight: String
    let showPRBadge: Bool
    let prMessage: String
    let onCompleteSet: () -> Void
    
    @State private var showHistory = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: WorkoutViewModel
    
    var canCompleteSet: Bool {
        !holdDuration.isEmpty && Int(holdDuration) != nil && Int(holdDuration)! > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(AppTypography.bodySmallBold)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    if viewModel.progressViewModel != nil {
                        Button(action: { showHistory = true }) {
                            Label("View History", systemImage: "chart.bar")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Exercise options")
            }
            
            // PR Badge
            if showPRBadge {
                PRBadge(message: prMessage)
                    .transition(.scaleWithFade)
            }
            
            // Input section
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hold Duration")
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("seconds", text: $holdDuration)
                        .keyboardType(.numberPad)
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Hold duration in seconds")
                        .accessibilityValue(holdDuration.isEmpty ? "Not set" : "\(holdDuration) seconds")
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Additional Weight")
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("lbs", text: $additionalWeight)
                        .keyboardType(.decimalPad)
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Additional weight in pounds")
                        .accessibilityValue(additionalWeight.isEmpty || additionalWeight == "0" ? "No additional weight" : "\(additionalWeight) pounds")
                }
                .frame(maxWidth: .infinity)
            }
            
            // Quick duration presets
            HStack(spacing: 8) {
                ForEach([15, 30, 45, 60], id: \.self) { preset in
                    Button(action: {
                        holdDuration = "\(preset)"
                        HapticManager.impact(style: .light)
                    }) {
                        Text("\(preset)s")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(holdDuration == "\(preset)" ? .white : AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(holdDuration == "\(preset)" ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Set \(preset) seconds")
                    .accessibilityAddTraits(holdDuration == "\(preset)" ? .isSelected : [])
                }
            }
            .accessibilityLabel("Quick duration presets")
            
            // Complete Set button
            Button(action: onCompleteSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(AppTypography.buttonBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canCompleteSet ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canCompleteSet ? AppColors.accent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            .accessibilityLabel("Complete set")
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(AppTypography.captionBold)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
        .onAppear {
            if additionalWeight.isEmpty {
                additionalWeight = "0"
            }
            if holdDuration.isEmpty, let targetDuration = exercise.targetHoldDuration {
                holdDuration = String(targetDuration)
            }
        }
        .sheet(isPresented: $showHistory) {
            if let progressVM = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exercise.name, progressViewModel: progressVM)
            }
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = viewModel.currentWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.removeExercise(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This will remove all completed sets for this exercise.")
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

// MARK: - Settings View (kinetic HTML parity — Manrope + palette from KineticWorkoutChrome)
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.kineticPalette) private var kp
    @State private var showResetWarning = false
    @State private var showAddCustomExercise = false
    @State private var showCustomExercisesList = false
    @State private var showMasterExerciseList = false
    @State private var showCSVImportAlert = false
    @State private var csvImportMessage = ""
    @State private var csvImportSuccess = false
    
    /// Preset grid — wireframe 30…300s (3×2).
    private let restTimerPresetGrid: [Int] = [30, 60, 90, 120, 180, 300]
    
    var body: some View {
        NavigationStack {
            ZStack {
                kp.background.ignoresSafeArea()
                
                // Ambient glow (HTML parity)
                GeometryReader { geo in
                    Circle()
                        .fill(kp.primary.opacity(0.05))
                        .frame(width: geo.size.width * 0.4, height: geo.size.width * 0.4)
                        .blur(radius: 60)
                        .offset(x: -geo.size.width * 0.05, y: -geo.size.height * 0.05)
                    Circle()
                        .fill(kp.secondary.opacity(0.05))
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .blur(radius: 75)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .offset(x: geo.size.width * 0.05, y: geo.size.height * 0.05)
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        restTimerSection

                        settingsSectionHeader(title: "Goals")
                        weeklyWorkoutGoalSection
                        
                        settingsSectionHeader(title: "Ecosystem")
                        AppleHealthSettingsSection()
                        
                        settingsSectionHeader(title: "Interface")
                        interfaceSection
                        
                        settingsSectionHeader(title: "Exercise Library")
                        exerciseLibrarySection
                        
                        settingsSectionHeader(title: "Support")
                        supportSection
                        
                        resetSection
                        brandFooter
                    }
                    .frame(maxWidth: 672)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 96)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(KineticWorkoutTypography.semiBold(18))
                        .foregroundColor(kp.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(KineticWorkoutTypography.semiBold(17))
                    .foregroundColor(kp.primary)
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
                MasterExerciseListView(progressViewModel: progressViewModel)
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
    
    @ViewBuilder
    private func settingsSectionHeader(title: String) -> some View {
        Text(title.uppercased())
            .font(KineticWorkoutTypography.bold(13))
            .tracking(1.6)
            .foregroundColor(kp.tertiary.opacity(0.85))
            .padding(.horizontal, 8)
    }
    
    private var restTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("Rest Timer")
                    .font(KineticWorkoutTypography.bold(13))
                    .tracking(1.6)
                    .foregroundColor(kp.tertiary.opacity(0.85))
                Spacer(minLength: 8)
                Text(formatRestClock(settingsManager.restTimerDuration))
                    .font(KineticWorkoutTypography.extraBold(36))
                    .foregroundColor(kp.primary)
                    .tracking(-1)
            }
            .padding(.horizontal, 8)
            
            VStack(spacing: 24) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(restTimerPresetGrid, id: \.self) { duration in
                        let isSelected = settingsManager.restTimerDuration == duration
                        Button {
                            HapticManager.impact(style: .light)
                            settingsManager.restTimerDuration = duration
                        } label: {
                            Text("\(duration)s")
                                .font(KineticWorkoutTypography.semiBold(15))
                                .foregroundColor(isSelected ? kp.onPrimaryContainer : kp.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isSelected ? kp.primaryContainer : kp.surfaceContainerLow)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(
                                            isSelected ? kp.primary.opacity(0.2) : Color.white.opacity(0.05),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: isSelected ? kp.primary.opacity(0.1) : .clear, radius: 8, x: 0, y: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Min (30s)")
                            .font(KineticWorkoutTypography.medium(11))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(kp.tertiary)
                        Spacer()
                        Text("Max (600s)")
                            .font(KineticWorkoutTypography.medium(11))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(kp.tertiary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settingsManager.restTimerDuration) },
                            set: { settingsManager.restTimerDuration = Int($0) }
                        ),
                        in: 30...600,
                        step: 15
                    )
                    .tint(kp.primary)
                }
            }
            .padding(24)
            .background(kp.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private var weeklyWorkoutGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly workout goal")
                        .font(KineticWorkoutTypography.bold(16))
                        .foregroundColor(kp.onSurface)
                    Text("Targets the Studio dashboard “X of Y workouts” ring.")
                        .font(KineticWorkoutTypography.medium(12))
                        .foregroundColor(kp.tertiary)
                }
                Spacer(minLength: 12)
                Stepper(value: $settingsManager.weeklyWorkoutGoal, in: 1...14) {
                    Text("\(settingsManager.weeklyWorkoutGoal)")
                        .font(KineticWorkoutTypography.bold(16))
                        .monospacedDigit()
                        .foregroundColor(kp.onSurface)
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .labelsHidden()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var interfaceSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: UIColorCustomizationView(settingsManager: settingsManager)) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(kp.primary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20))
                            .foregroundColor(kp.primary)
                    }
                    Text("Customize UI Colors")
                        .font(KineticWorkoutTypography.bold(16))
                        .foregroundColor(kp.onSurface)
                    Spacer()
                    if UIColorCustomizationManager.shared.hasCustomizations {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(kp.primary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(kp.outlineVariant)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var exerciseLibrarySection: some View {
        VStack(spacing: 16) {
            libraryExploreCard
            customListCard
        }
    }
    
    private var libraryExploreCard: some View {
        let count = ExRxDirectoryManager.shared.getAllExercises().count
        return ZStack(alignment: .topLeading) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 96))
                .foregroundColor(.white.opacity(0.05))
                .rotationEffect(.degrees(12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 24, y: 20)
                .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Library")
                        .font(KineticWorkoutTypography.bold(16))
                        .foregroundColor(kp.onSurface)
                    Text("\(count)+ Exercises")
                        .font(KineticWorkoutTypography.medium(12))
                        .foregroundColor(kp.tertiary)
                }
                Button {
                    HapticManager.impact(style: .light)
                    showMasterExerciseList = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Explore")
                            .font(KineticWorkoutTypography.bold(14))
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(kp.primary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(minHeight: 128, alignment: .topLeading)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var customListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom List")
                .font(KineticWorkoutTypography.bold(16))
                .foregroundColor(kp.onSurface)
            HStack(spacing: 8) {
                Button {
                    showAddCustomExercise = true
                } label: {
                    Text("Add New")
                        .font(KineticWorkoutTypography.bold(12))
                        .foregroundColor(kp.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(kp.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    if !exerciseDataManager.customExercises.isEmpty {
                        HapticManager.impact(style: .light)
                        showCustomExercisesList = true
                    }
                } label: {
                    Text("View All")
                        .font(KineticWorkoutTypography.bold(12))
                        .foregroundColor(kp.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(kp.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .opacity(exerciseDataManager.customExercises.isEmpty ? 0.45 : 1)
                .disabled(exerciseDataManager.customExercises.isEmpty)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var supportSection: some View {
        VStack(spacing: 0) {
            Button {
                HapticManager.impact(style: .medium)
                OnboardingManager.shared.resetTutorial()
                dismiss()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(kp.secondary)
                    Text("Show Tutorial")
                        .font(KineticWorkoutTypography.bold(16))
                        .foregroundColor(kp.onSurface)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(kp.outlineVariant)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Color.white.opacity(0.05))
            
            Button {
                HapticManager.impact(style: .light)
                if let url = URL(string: "mailto:support@ascend.app?subject=Ascend%20Support") {
                    openURL(url)
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 22))
                        .foregroundColor(kp.secondary)
                    Text("Contact Support")
                        .font(KineticWorkoutTypography.bold(16))
                        .foregroundColor(kp.onSurface)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(kp.outlineVariant)
                }
                .padding(20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var resetSection: some View {
        Button {
            showResetWarning = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "ffb4ab"))
                Text("Reset All Data")
                    .font(KineticWorkoutTypography.bold(16))
                    .foregroundColor(Color(hex: "ffb4ab"))
                Text("This action cannot be undone")
                    .font(KineticWorkoutTypography.medium(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "ffb4ab").opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(hex: "93000a").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "ffb4ab").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
    
    private var brandFooter: some View {
        VStack(spacing: 8) {
            Text("ASCEND")
                .font(KineticWorkoutTypography.extraBold(24))
                .tracking(-0.5)
                .foregroundColor(kp.onSurface)
            Text(appVersionString)
                .font(KineticWorkoutTypography.bold(10))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(kp.onSurface.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .opacity(0.9)
    }
    
    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(v) (Build \(b))"
    }
    
    private func formatRestClock(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
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

// MARK: - Apple Health Settings Section (compact kinetic row — HTML parity)
struct AppleHealthSettingsSection: View {
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @State private var isRequestingAuthorization = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.kineticPalette) private var kp

    private var healthAccent: Color { Color(hex: "FF2D55") }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(healthAccent.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(healthAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health")
                    .font(KineticWorkoutTypography.bold(16))
                    .foregroundColor(kp.onSurface)
                Text(connectionSubtitle)
                    .font(KineticWorkoutTypography.medium(12))
                    .foregroundColor(kp.tertiary)
            }
            Spacer(minLength: 8)
            Button {
                requestAuthorization()
            } label: {
                Text(healthKitManager.isAuthorized ? "Reconnect" : "Connect")
                    .font(KineticWorkoutTypography.bold(14))
                    .foregroundColor(kp.onSecondaryContainer)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(kp.secondaryContainer)
                    .clipShape(Capsule())
            }
            .disabled(isRequestingAuthorization)
            .opacity(isRequestingAuthorization ? 0.6 : 1)
        }
        .padding(20)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            healthKitManager.checkAuthorizationStatus()
        }
        .alert("HealthKit Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var connectionSubtitle: String {
        if healthKitManager.isAuthorized {
            return "Connected"
        }
        return "Disconnected"
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
