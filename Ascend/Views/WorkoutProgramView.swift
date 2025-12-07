import SwiftUI

struct WorkoutProgramView: View {
    let program: WorkoutProgram
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var selectedDayIndex: Int = 0
    @Environment(\.dismiss) var dismiss
    
    var selectedDay: WorkoutDay {
        program.days[selectedDayIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Program Header
                ProgramHeader(program: program)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                
                // Day Selector
                DaySelector(
                    days: program.days,
                    selectedIndex: $selectedDayIndex
                )
                .padding(.horizontal, AppSpacing.lg)
                
                // Selected Day Details
                DayDetailsView(
                    day: selectedDay,
                    onStartWorkout: {
                        startWorkoutForDay(selectedDay)
                    }
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 100)
            }
        }
        .background(AppColors.background)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startWorkoutForDay(_ day: WorkoutDay) {
        // Convert program exercises to workout exercises
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
        
        workoutViewModel.currentWorkout = Workout(name: "\(program.name) - \(day.name)", exercises: exercises)
        workoutViewModel.currentExerciseIndex = 0
        workoutViewModel.startTimer()
        
        dismiss()
    }
    
    private func parseReps(_ repsString: String) -> Int {
        // Handle formats like "6-8", "10", "3-5", etc.
        let components = repsString.components(separatedBy: "-")
        if let firstNumber = Int(components[0].trimmingCharacters(in: .whitespaces)) {
            return firstNumber
        }
        return 8 // Default
    }
}

struct ProgramHeader: View {
    let program: WorkoutProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(program.name)
                        .font(AppTypography.heading1)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(program.category.rawValue)
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.secondary)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            Text(program.description)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.accent)
                Text(program.frequency)
                    .font(AppTypography.captionMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct DaySelector: View {
    let days: [WorkoutDay]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.md) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    Button(action: {
                        selectedIndex = index
                    }) {
                        VStack(spacing: AppSpacing.xs) {
                            Text("Day \(day.dayNumber)")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(selectedIndex == index ? AppColors.accentForeground : AppColors.textPrimary)
                            
                            Text(day.name)
                                .font(AppTypography.caption)
                                .foregroundColor(selectedIndex == index ? AppColors.accentForeground.opacity(0.8) : AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(minWidth: 120)
                        .background(selectedIndex == index ? AppColors.primary : AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

struct DayDetailsView: View {
    let day: WorkoutDay
    let onStartWorkout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Day Header
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Day \(day.dayNumber): \(day.name)")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(day.description)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                
            }
            
            // Exercises List
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(day.exercises) { exercise in
                    ProgramExerciseRow(exercise: exercise)
                }
            }
            
            // Start Workout Button
            Button(action: onStartWorkout) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(AppTypography.bodyBold)
                    Text("Start \(day.name)")
                        .font(AppTypography.bodyBold)
                }
                .foregroundColor(AppColors.accentForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

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



