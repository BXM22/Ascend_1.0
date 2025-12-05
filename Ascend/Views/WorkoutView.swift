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
    @State private var showFinishConfirmation = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                WorkoutHeader(
                    title: viewModel.currentWorkout?.name ?? "Workout",
                    onPause: { viewModel.pauseWorkout() },
                    onFinish: { showFinishConfirmation = true },
                    onSettings: { viewModel.showSettingsSheet = true }
                )
                
                // Workout Timer
                WorkoutTimerBar(
                    time: viewModel.formatTime(viewModel.elapsedTime),
                    onAbort: { viewModel.abortWorkoutTimer() }
                )
                
                // Exercise Navigation
                if let workout = viewModel.currentWorkout, workout.exercises.count > 1 {
                    ExerciseNavigationView(
                        exercises: workout.exercises,
                        currentIndex: viewModel.currentExerciseIndex,
                        onSelect: { index in
                            viewModel.currentExerciseIndex = index
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Exercise Card
                if let exercise = viewModel.currentExercise {
                    if exercise.type == .hold {
                        HoldExerciseCard(
                            exercise: exercise,
                            holdDuration: $holdDuration,
                            onCompleteSet: {
                                if let duration = Int(holdDuration) {
                                    viewModel.completeHoldSet(duration: duration)
                                }
                            }
                        )
                    } else {
                        ExerciseCard(
                            exercise: exercise,
                            weight: $weight,
                            reps: $reps,
                            showPRBadge: viewModel.showPRBadge,
                            prMessage: viewModel.prMessage,
                            onCompleteSet: {
                                if let weightValue = Double(weight),
                                   let repsValue = Int(reps) {
                                    viewModel.completeSet(weight: weightValue, reps: repsValue)
                                }
                            },
                            onSelectAlternative: { alternativeName in
                                viewModel.switchToAlternative(alternativeName: alternativeName)
                            }
                        )
                    }
                }
                
                // Rest Timer (appears above alternative exercises)
                if viewModel.restTimerActive {
                    RestTimerView(
                        timeRemaining: viewModel.restTimeRemaining,
                        onSkip: { viewModel.skipRest() },
                        onComplete: { viewModel.completeRest() }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Alternative Exercises Section (appears after rest timer)
                if let exercise = viewModel.currentExercise, exercise.type != .hold {
                    let alternatives = ExerciseDataManager.shared.getAlternatives(for: exercise.name)
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
                    PreviousSetsView(sets: exercise.sets)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                // Add Exercise Button
                AddExerciseButton {
                    viewModel.showAddExerciseSheet = true
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
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
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            if let settingsManager = viewModel.settingsManager,
               let progressViewModel = viewModel.progressViewModel,
               let templatesViewModel = viewModel.templatesViewModel,
               let programViewModel = viewModel.programViewModel,
               let themeManager = viewModel.themeManager {
                SettingsView(
                    settingsManager: settingsManager,
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
    let onPause: () -> Void
    let onFinish: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Spacer()
            
            HStack(spacing: AppSpacing.md) {
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onFinish) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
    let onAbort: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 16))
                .foregroundColor(AppColors.mutedForeground)
            
            Text(time)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
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
    let onCompleteSet: () -> Void
    let onSelectAlternative: ((String) -> Void)?
    
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
            
            VStack(alignment: .leading, spacing: 20) {
                // Exercise Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
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
                        .transition(.smoothSlide)
                }
                
                // Weight Input
                InputField(
                    label: "Weight",
                    value: $weight,
                    unit: "lbs",
                    keyboardType: .decimalPad
                )
                
                // Reps Input
                InputField(
                    label: "Reps",
                    value: $reps,
                    unit: "reps",
                    keyboardType: .numberPad
                )
                
                // Video Tutorial Button
                if videoURL != nil {
                    VideoTutorialButton(videoURL: videoURL, exerciseName: exercise.name)
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
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

// MARK: - Hold Exercise Card
struct HoldExerciseCard: View {
    let exercise: Exercise
    @Binding var holdDuration: String
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
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct PRBadge: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16))
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
        .shadow(color: Color(light: AppColors.prussianBlue, dark: Color(hex: "000000")).opacity(0.4), radius: 20, x: 0, y: 8)
        .shadow(color: Color(light: AppColors.prussianBlue, dark: Color(hex: "000000")).opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct InputField: View {
    let label: String
    @Binding var value: String
    let unit: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            HStack(spacing: 12) {
                TextField("", text: $value)
                    .keyboardType(keyboardType)
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
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
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
                            Text(exercise.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(index == currentIndex ? AppColors.alabasterGrey : AppColors.foreground)
                                .lineLimit(1)
                            
                            Text("\(exercise.sets.count)/\(exercise.targetSets)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(index == currentIndex ? AppColors.alabasterGrey.opacity(0.8) : AppColors.mutedForeground)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            index == currentIndex ?
                            LinearGradient.primaryGradient :
                            LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(index == currentIndex ? Color.clear : AppColors.border, lineWidth: 1)
                        )
                        .animation(AppAnimations.selection, value: currentIndex)
                    }
                    .buttonStyle(PlainButtonStyle())
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
    @Environment(\.dismiss) var dismiss
    @State private var showResetWarning = false
    
    private let restTimerOptions: [Int] = [30, 45, 60, 90, 120, 180, 240, 300]
    
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

#Preview {
    WorkoutView(viewModel: WorkoutViewModel())
}
