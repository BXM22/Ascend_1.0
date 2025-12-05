import SwiftUI

struct AddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName: String
    @State private var selectedPrimaryMuscles: Set<MuscleGroup>
    @State private var selectedSecondaryMuscles: Set<MuscleGroup>
    @State private var alternatives: [String]
    @State private var newAlternative: String
    @State private var videoURL: String
    @State private var selectedCategory: ExerciseCategory
    @State private var equipment: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSave: (CustomExercise) -> Void
    let isEditing: Bool
    
    init(exercise: CustomExercise? = nil, onSave: @escaping (CustomExercise) -> Void) {
        if let exercise = exercise {
            _exerciseName = State(initialValue: exercise.name)
            _selectedPrimaryMuscles = State(initialValue: Set(exercise.primaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }))
            _selectedSecondaryMuscles = State(initialValue: Set(exercise.secondaryMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }))
            _alternatives = State(initialValue: exercise.alternatives)
            _newAlternative = State(initialValue: "")
            _videoURL = State(initialValue: exercise.videoURL ?? "")
            _selectedCategory = State(initialValue: ExerciseCategory(rawValue: exercise.category) ?? .other)
            _equipment = State(initialValue: exercise.equipment ?? "")
            self.isEditing = true
        } else {
            _exerciseName = State(initialValue: "")
            _selectedPrimaryMuscles = State(initialValue: [])
            _selectedSecondaryMuscles = State(initialValue: [])
            _alternatives = State(initialValue: [])
            _newAlternative = State(initialValue: "")
            _videoURL = State(initialValue: "")
            _selectedCategory = State(initialValue: .other)
            _equipment = State(initialValue: "")
            self.isEditing = false
        }
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercise Name *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., Custom Exercise", text: $exerciseName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(ExerciseCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Primary Muscle Groups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Primary Muscle Groups *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(MuscleGroup.allCases) { muscle in
                                Button(action: {
                                    if selectedPrimaryMuscles.contains(muscle) {
                                        selectedPrimaryMuscles.remove(muscle)
                                    } else {
                                        selectedPrimaryMuscles.insert(muscle)
                                        // Remove from secondary if it's there
                                        selectedSecondaryMuscles.remove(muscle)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: muscle.icon)
                                            .font(.system(size: 14))
                                        Text(muscle.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(selectedPrimaryMuscles.contains(muscle) ? AppColors.alabasterGrey : AppColors.foreground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedPrimaryMuscles.contains(muscle) ?
                                        LinearGradient.primaryGradient :
                                        LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedPrimaryMuscles.contains(muscle) ? Color.clear : AppColors.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Secondary Muscle Groups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Secondary Muscle Groups")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(MuscleGroup.allCases) { muscle in
                                // Don't show muscles already selected as primary
                                if !selectedPrimaryMuscles.contains(muscle) {
                                    Button(action: {
                                        if selectedSecondaryMuscles.contains(muscle) {
                                            selectedSecondaryMuscles.remove(muscle)
                                        } else {
                                            selectedSecondaryMuscles.insert(muscle)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: muscle.icon)
                                                .font(.system(size: 14))
                                            Text(muscle.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(selectedSecondaryMuscles.contains(muscle) ? AppColors.alabasterGrey : AppColors.foreground)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedSecondaryMuscles.contains(muscle) ?
                                            LinearGradient.primaryGradient :
                                            LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedSecondaryMuscles.contains(muscle) ? Color.clear : AppColors.border, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    // Equipment (Optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Equipment")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., Barbell, Dumbbells, Bodyweight", text: $equipment)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Alternatives
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alternative Exercises")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(spacing: 12) {
                            TextField("Add alternative", text: $newAlternative)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppColors.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: {
                                if !newAlternative.isEmpty {
                                    alternatives.append(newAlternative)
                                    newAlternative = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.primary)
                            }
                            .disabled(newAlternative.isEmpty)
                        }
                        
                        if !alternatives.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(alternatives, id: \.self) { alt in
                                    HStack {
                                        Text(alt)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.foreground)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            alternatives.removeAll { $0 == alt }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(AppColors.mutedForeground)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(AppColors.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    // Video URL (Optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Video URL (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("https://...", text: $videoURL)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(AppColors.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Save Button
                    Button(action: {
                        saveExercise()
                    }) {
                        Text("Save Exercise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.6)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Custom Exercise" : "Add Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.foreground)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !exerciseName.isEmpty && !selectedPrimaryMuscles.isEmpty
    }
    
    private func saveExercise() {
        guard !exerciseName.isEmpty else {
            errorMessage = "Exercise name is required"
            showError = true
            return
        }
        
        guard !selectedPrimaryMuscles.isEmpty else {
            errorMessage = "At least one primary muscle group is required"
            showError = true
            return
        }
        
        // Check if exercise already exists (only when creating new, not editing)
        if !isEditing {
            if ExerciseDataManager.shared.getCustomExercise(name: exerciseName) != nil {
                errorMessage = "An exercise with this name already exists"
                showError = true
                return
            }
        }
        
        let exercise: CustomExercise
        if isEditing, let existing = ExerciseDataManager.shared.getCustomExercise(name: exerciseName) {
            // Update existing exercise
            exercise = CustomExercise(
                id: existing.id,
                name: exerciseName,
                primaryMuscleGroups: selectedPrimaryMuscles.map { $0.rawValue },
                secondaryMuscleGroups: selectedSecondaryMuscles.map { $0.rawValue },
                alternatives: alternatives,
                videoURL: videoURL.isEmpty ? nil : videoURL,
                category: selectedCategory.rawValue,
                equipment: equipment.isEmpty ? nil : equipment,
                dateCreated: existing.dateCreated
            )
        } else {
            // Create new exercise
            exercise = CustomExercise(
                name: exerciseName,
                primaryMuscleGroups: selectedPrimaryMuscles.map { $0.rawValue },
                secondaryMuscleGroups: selectedSecondaryMuscles.map { $0.rawValue },
                alternatives: alternatives,
                videoURL: videoURL.isEmpty ? nil : videoURL,
                category: selectedCategory.rawValue,
                equipment: equipment.isEmpty ? nil : equipment
            )
        }
        
        onSave(exercise)
        dismiss()
    }
}

