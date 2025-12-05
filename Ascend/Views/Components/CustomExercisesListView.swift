import SwiftUI

struct CustomExercisesListView: View {
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseToEdit: CustomExercise?
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if exerciseDataManager.customExercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.mutedForeground)
                        Text("No Custom Exercises")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        Text("Add custom exercises to track your own workouts")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(exerciseDataManager.customExercises) { exercise in
                            CustomExerciseCard(exercise: exercise) {
                                exerciseToEdit = exercise
                                showEditSheet = true
                            } onDelete: {
                                exerciseDataManager.deleteCustomExercise(exercise)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Custom Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(item: $exerciseToEdit) { exercise in
                AddCustomExerciseView(exercise: exercise) { updatedExercise in
                    exerciseDataManager.updateCustomExercise(updatedExercise)
                    exerciseToEdit = nil
                }
            }
        }
    }
}

struct CustomExerciseCard: View {
    let exercise: CustomExercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text(exercise.category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                }
            }
            
            if !exercise.primaryMuscleGroups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary: \(exercise.primaryMuscleGroups.joined(separator: ", "))")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.foreground)
                    
                    if !exercise.secondaryMuscleGroups.isEmpty {
                        Text("Secondary: \(exercise.secondaryMuscleGroups.joined(separator: ", "))")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
            }
            
            if let equipment = exercise.equipment {
                Text("Equipment: \(equipment)")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}


