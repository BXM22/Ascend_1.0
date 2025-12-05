import SwiftUI

struct WorkoutGenerationSettingsView: View {
    @Binding var settings: WorkoutGenerationSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercises Per Muscle Group Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises Per Muscle Group")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        ForEach(Array(settings.exercisesPerMuscleGroup.keys.sorted()), id: \.self) { muscleGroup in
                            HStack {
                                Text(muscleGroup)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(width: 120, alignment: .leading)
                                
                                Spacer()
                                
                                Stepper(value: Binding(
                                    get: { settings.exercisesPerMuscleGroup[muscleGroup] ?? 0 },
                                    set: { settings.exercisesPerMuscleGroup[muscleGroup] = max(0, $0) }
                                ), in: 0...5) {
                                    Text("\(settings.exercisesPerMuscleGroup[muscleGroup] ?? 0)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 30)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Equipment Preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferred Equipment")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        let equipmentOptions = ["Bodyweight", "Dumbbells", "Barbell", "Cable", "Machine"]
                        
                        ForEach(equipmentOptions, id: \.self) { equipment in
                            Toggle(isOn: Binding(
                                get: { settings.preferredEquipment.contains(equipment) },
                                set: { isOn in
                                    if isOn {
                                        if !settings.preferredEquipment.contains(equipment) {
                                            settings.preferredEquipment.append(equipment)
                                        }
                                    } else {
                                        settings.preferredEquipment.removeAll { $0 == equipment }
                                    }
                                }
                            )) {
                                Text(equipment)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Exercise Count Range
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercise Count Range")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Minimum")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Stepper(value: $settings.minExercises, in: 4...20) {
                                    Text("\(settings.minExercises)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 40)
                                }
                            }
                            
                            HStack {
                                Text("Maximum")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Stepper(value: $settings.maxExercises, in: settings.minExercises...25) {
                                    Text("\(settings.maxExercises)")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 40)
                                }
                            }
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Additional Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Options")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Toggle(isOn: $settings.includeCalisthenics) {
                            Text("Include Calisthenics")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Toggle(isOn: $settings.includeCardio) {
                            Text("Include Cardio")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Generation Settings")
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


