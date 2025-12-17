import SwiftUI

struct WorkoutGenerationView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedWorkoutType: WorkoutType = .fullBody
    @State private var showSuccessAlert = false
    @State private var generatedWorkoutName = ""
    
    enum WorkoutType: String, CaseIterable {
        case custom = "Custom"
        case push = "Push Day"
        case pull = "Pull Day"
        case legs = "Leg Day"
        case upper = "Upper Day"
        case lower = "Lower Day"
        case fullBody = "Full Body"
        
        var icon: String {
            switch self {
            case .custom: return "sparkles"
            case .push: return "arrow.up"
            case .pull: return "arrow.down"
            case .legs: return "figure.walk"
            case .upper: return "arrow.up.circle"
            case .lower: return "arrow.down.circle"
            case .fullBody: return "figure.strengthtraining.traditional"
            }
        }
    }
    
    private var currentPhase: TrainingPhase {
        switch (viewModel.generationSettings.trainingType, viewModel.generationSettings.trainingGoal) {
        case (.endurance, _):
            return .endurance
        case (_, .bulk):
            return .bulking
        case (_, .cut):
            return .cutting
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Generate Workout")
                            .font(AppTypography.largeTitleBold)
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("Create a personalized workout based on your goals")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    
                    // Core Rules
                    CoreRulesSection()
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Goal Selection
                    GoalSelectionSection(
                        trainingType: $viewModel.generationSettings.trainingType,
                        trainingGoal: $viewModel.generationSettings.trainingGoal,
                        onTypeChange: {
                            viewModel.generationSettings.applyPhasePreset()
                        },
                        onGoalChange: {
                            viewModel.generationSettings.applyPhasePreset()
                        }
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Phase Preview
                    PhasePreviewCard(phase: currentPhase, settings: viewModel.generationSettings)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Workout Type Selection
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Workout Type")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.sm) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                WorkoutTypeCard(
                                    type: type,
                                    isSelected: selectedWorkoutType == type,
                                    action: {
                                        HapticManager.impact(style: .light)
                                        selectedWorkoutType = type
                                    }
                                )
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Generate Button
                    Button(action: {
                        HapticManager.impact(style: .medium)
                        generateAndSaveWorkout()
                    }) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Generate Workout")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundColor(AppColors.alabasterGrey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Quick Generate Options
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Quick Generate")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Generate multiple variations")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack(spacing: AppSpacing.sm) {
                            ForEach([1, 3, 5], id: \.self) { count in
                                Button(action: {
                                    HapticManager.impact(style: .light)
                                    generateMultipleWorkouts(count: count)
                                }) {
                                    Text("\(count)")
                                        .font(AppTypography.bodyBold)
                                        .foregroundColor(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.md)
                                        .background(AppColors.secondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.border, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .alert("Workout Generated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    showSuccessAlert = false
                }
            } message: {
                Text("Successfully generated: \(generatedWorkoutName)")
            }
        }
    }
    
    private func generateAndSaveWorkout() {
        let workout: WorkoutTemplate
        
        switch selectedWorkoutType {
        case .custom:
            workout = viewModel.generateWorkout()
        case .push:
            workout = viewModel.generatePushWorkout()
        case .pull:
            workout = viewModel.generatePullWorkout()
        case .legs:
            workout = viewModel.generateLegWorkout()
        case .upper:
            workout = viewModel.generateUpperWorkout()
        case .lower:
            workout = viewModel.generateLowerWorkout()
        case .fullBody:
            workout = viewModel.generateFullBodyWorkout()
        }
        
        viewModel.saveTemplate(workout)
        generatedWorkoutName = workout.name
        showSuccessAlert = true
        
        // Auto-dismiss after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func generateMultipleWorkouts(count: Int) {
        let workouts = viewModel.generateWorkoutVariations(count: count)
        for workout in workouts {
            viewModel.saveTemplate(workout)
        }
        generatedWorkoutName = "\(count) workout\(count > 1 ? "s" : "")"
        showSuccessAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Goal Selection Section

struct GoalSelectionSection: View {
    @Binding var trainingType: TrainingType
    @Binding var trainingGoal: TrainingGoal
    
    let onTypeChange: () -> Void
    let onGoalChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Select Your Goal")
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.textPrimary)
            
            // Training Type
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Training Type")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.sm) {
                    ForEach(TrainingType.allCases, id: \.self) { type in
                        Button(action: {
                            HapticManager.impact(style: .light)
                            trainingType = type
                            onTypeChange()
                        }) {
                            VStack(spacing: AppSpacing.xs) {
                                Image(systemName: type == .strength ? "bolt.fill" : "flame.fill")
                                    .font(.system(size: 20))
                                Text(type.rawValue)
                                    .font(AppTypography.bodyMedium)
                            }
                            .foregroundColor(trainingType == type ? AppColors.alabasterGrey : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background(
                                trainingType == type 
                                    ? LinearGradient.primaryGradient 
                                    : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        trainingType == type ? Color.clear : AppColors.border,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Training Goal
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Goal")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: AppSpacing.sm) {
                    ForEach(TrainingGoal.allCases, id: \.self) { goal in
                        Button(action: {
                            HapticManager.impact(style: .light)
                            trainingGoal = goal
                            onGoalChange()
                        }) {
                            VStack(spacing: AppSpacing.xs) {
                                Image(systemName: goal == .bulk ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                Text(goal.rawValue)
                                    .font(AppTypography.bodyMedium)
                            }
                            .foregroundColor(trainingGoal == goal ? AppColors.alabasterGrey : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.md)
                            .background(
                                trainingGoal == goal 
                                    ? LinearGradient.primaryGradient 
                                    : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        trainingGoal == goal ? Color.clear : AppColors.border,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Workout Type Card

struct WorkoutTypeCard: View {
    let type: WorkoutGenerationView.WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            action()
        }) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                
                Text(type.rawValue)
                    .font(AppTypography.bodyMedium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(
                isSelected 
                    ? LinearGradient.primaryGradient 
                    : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : AppColors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Phase Preview Card

struct PhasePreviewCard: View {
    let phase: TrainingPhase
    let settings: WorkoutGenerationSettings
    
    private var phaseColor: LinearGradient {
        switch phase {
        case .bulking:
            return LinearGradient(
                colors: [Color(hex: "16a34a"), Color(hex: "10b981")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cutting:
            return LinearGradient(
                colors: [Color(hex: "ea580c"), Color(hex: "f59e0b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .endurance:
            return LinearGradient(
                colors: [Color(hex: "0891b2"), Color(hex: "0ea5e9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var totalExerciseCount: String {
        switch phase {
        case .bulking:
            return "5–7"
        case .cutting:
            return "4–6"
        case .endurance:
            return "4–6"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(phase.rawValue.uppercased())
                    .font(AppTypography.heading3)
                    .foregroundStyle(phaseColor)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                PhaseInfoRow(label: "Goal", value: phaseGoal)
                PhaseInfoRow(label: "Weekly sets/muscle", value: weeklySetsRange)
                PhaseInfoRow(label: "Exercises per workout", value: totalExerciseCount)
                PhaseInfoRow(label: "Sets/Reps", value: setsRepsGuideline)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 4, x: 0, y: 2)
    }
    
    private var phaseGoal: String {
        switch phase {
        case .bulking: return "Grow muscle"
        case .cutting: return "Maintain muscle"
        case .endurance: return "Fatigue resistance"
        }
    }
    
    private var weeklySetsRange: String {
        switch phase {
        case .bulking: return "12–18"
        case .cutting: return "8–12"
        case .endurance: return "8–15"
        }
    }
    
    private var setsRepsGuideline: String {
        switch phase {
        case .bulking: return "3–4 sets × 6–12 reps"
        case .cutting: return "2–3 sets × 5–10 reps"
        case .endurance: return "2–3 sets × 12–20 reps"
        }
    }
}

struct PhaseInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

