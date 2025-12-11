import SwiftUI

struct WorkoutGenerationView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedWorkoutType: WorkoutType = .custom
    
    enum WorkoutType {
        case custom
        case push
        case pull
        case legs
        case fullBody
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Training Goals Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Training Goals")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        // Training Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Training Type")
                                .font(AppTypography.heading4)
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 12) {
                                ForEach(TrainingType.allCases, id: \.self) { type in
                                    Button(action: {
                                        viewModel.generationSettings.trainingType = type
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: type == .strength ? "bolt.fill" : "flame.fill")
                                                .font(.system(size: 24))
                                            Text(type.rawValue)
                                                .font(AppTypography.bodyMedium)
                                            Text(type.description)
                                                .font(AppTypography.caption)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .foregroundColor(viewModel.generationSettings.trainingType == type ? AppColors.alabasterGrey : AppColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(AppSpacing.md)
                                        .background(viewModel.generationSettings.trainingType == type ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Training Goal Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal")
                                .font(AppTypography.heading4)
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 12) {
                                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                                    Button(action: {
                                        viewModel.generationSettings.trainingGoal = goal
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: goal == .bulk ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                                .font(.system(size: 24))
                                            Text(goal.rawValue)
                                                .font(AppTypography.bodyMedium)
                                            Text(goal.description)
                                                .font(AppTypography.caption)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .foregroundColor(viewModel.generationSettings.trainingGoal == goal ? AppColors.alabasterGrey : AppColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(AppSpacing.md)
                                        .background(viewModel.generationSettings.trainingGoal == goal ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Hint for Cut goal
                        if viewModel.generationSettings.trainingGoal == .cut {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppColors.accent)
                                Text("Tip: Enable cardio in settings for better fat loss results")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.secondary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Workout Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workout Type")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: 12) {
                            WorkoutTypeButton(
                                title: "Custom",
                                icon: "sparkles",
                                isSelected: selectedWorkoutType == .custom,
                                action: { selectedWorkoutType = .custom }
                            )
                            
                            WorkoutTypeButton(
                                title: "Push Day",
                                icon: "arrow.up",
                                isSelected: selectedWorkoutType == .push,
                                action: { selectedWorkoutType = .push }
                            )
                            
                            WorkoutTypeButton(
                                title: "Pull Day",
                                icon: "arrow.down",
                                isSelected: selectedWorkoutType == .pull,
                                action: { selectedWorkoutType = .pull }
                            )
                            
                            WorkoutTypeButton(
                                title: "Leg Day",
                                icon: "figure.walk",
                                isSelected: selectedWorkoutType == .legs,
                                action: { selectedWorkoutType = .legs }
                            )
                            
                            WorkoutTypeButton(
                                title: "Full Body",
                                icon: "figure.strengthtraining.traditional",
                                isSelected: selectedWorkoutType == .fullBody,
                                action: { selectedWorkoutType = .fullBody }
                            )
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Generate Button
                    Button(action: {
                        generateAndSaveWorkout()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Workout")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.alabasterGrey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Generate Multiple Variations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generate Multiple Variations")
                            .font(AppTypography.heading4)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 12) {
                            ForEach([1, 3, 5], id: \.self) { count in
                                Button(action: {
                                    generateMultipleWorkouts(count: count)
                                }) {
                                    Text("\(count)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppColors.secondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.border, lineWidth: 2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Generate Workout")
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
        case .fullBody:
            workout = viewModel.generateFullBodyWorkout()
        }
        
        viewModel.saveTemplate(workout)
        dismiss()
    }
    
    private func generateMultipleWorkouts(count: Int) {
        let workouts = viewModel.generateWorkoutVariations(count: count)
        for workout in workouts {
            viewModel.saveTemplate(workout)
        }
        dismiss()
    }
}

struct WorkoutTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(AppTypography.bodyMedium)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .foregroundColor(isSelected ? AppColors.alabasterGrey : AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(isSelected ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}


