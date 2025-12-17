import SwiftUI

struct MasterExerciseListView: View {
    @ObservedObject private var exRxManager = ExRxDirectoryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCategory: ExRxCategory? = nil
    @State private var selectedMuscleGroup: ExRxMuscleGroup? = nil
    @State private var exerciseToEdit: ExRxExercise?
    @State private var showEditSheet = false
    @State private var exerciseToDelete: ExRxExercise?
    @State private var showDeleteConfirmation = false
    
    private var filteredExercises: [ExRxExercise] {
        var exercises = exRxManager.getAllExercises()
        
        // Filter by search text
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.category.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroup.localizedCaseInsensitiveContains(searchText) ||
                (exercise.equipment?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category.rawValue }
        }
        
        // Filter by muscle group
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup.rawValue }
        }
        
        return exercises.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Category Filter
                            Menu {
                                Button(action: {
                                    selectedCategory = nil
                                }) {
                                    HStack {
                                        Text("All Categories")
                                        if selectedCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(ExRxCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        HStack {
                                            Text(category.rawValue)
                                            if selectedCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text(selectedCategory?.rawValue ?? "Category")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedCategory != nil ? AppColors.alabasterGrey : AppColors.foreground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedCategory != nil ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                .clipShape(Capsule())
                            }
                            
                            // Muscle Group Filter
                            Menu {
                                Button(action: {
                                    selectedMuscleGroup = nil
                                }) {
                                    HStack {
                                        Text("All Muscle Groups")
                                        if selectedMuscleGroup == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(ExRxMuscleGroup.allCases, id: \.self) { muscleGroup in
                                    Button(action: {
                                        selectedMuscleGroup = muscleGroup
                                    }) {
                                        HStack {
                                            Text(muscleGroup.rawValue)
                                            if selectedMuscleGroup == muscleGroup {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(selectedMuscleGroup?.rawValue ?? "Muscle Group")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedMuscleGroup != nil ? AppColors.alabasterGrey : AppColors.foreground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedMuscleGroup != nil ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                .clipShape(Capsule())
                            }
                            
                            // Clear Filters
                            if selectedCategory != nil || selectedMuscleGroup != nil {
                                Button(action: {
                                    selectedCategory = nil
                                    selectedMuscleGroup = nil
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Clear")
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppColors.secondary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(AppColors.card)
                
                // Exercise List
                if filteredExercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.mutedForeground)
                        Text("No Exercises Found")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        Text("Try adjusting your search or filters")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                MasterExerciseCard(
                                    exercise: exercise,
                                    isImported: exRxManager.isImportedExercise(exercise),
                                    onEdit: {
                                        exerciseToEdit = exercise
                                        showEditSheet = true
                                    },
                                    onDelete: {
                                        exerciseToDelete = exercise
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Exercise Database")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let exercise = exerciseToEdit {
                    EditExerciseSheet(
                        exercise: exercise,
                        onSave: { updatedExercise in
                            exRxManager.updateImportedExercise(updatedExercise)
                            showEditSheet = false
                        },
                        onCancel: {
                            showEditSheet = false
                        }
                    )
                }
            }
            .alert("Delete Exercise", isPresented: $showDeleteConfirmation, presenting: exerciseToDelete) { exercise in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    exRxManager.deleteImportedExercise(exercise)
                    HapticManager.success()
                }
            } message: { exercise in
                Text("Are you sure you want to delete '\(exercise.name)'? This action cannot be undone.")
            }
        }
    }
}

struct MasterExerciseCard: View {
    let exercise: ExRxExercise
    let isImported: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    if !isImported {
                        Text("(Built-in)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.secondary)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 11))
                        Text(exercise.category)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 11))
                        Text(exercise.muscleGroup)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(AppColors.mutedForeground)
                    
                    if let equipment = exercise.equipment {
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 11))
                            Text(equipment)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(AppColors.mutedForeground)
                    }
                }
            }
            
            Spacer()
            
            if isImported {
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.impact(style: .light)
                        onEdit()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        HapticManager.impact(style: .light)
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.destructive)
                            .frame(width: 36, height: 36)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EditExerciseSheet: View {
    let exercise: ExRxExercise
    let onSave: (ExRxExercise) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var category: String
    @State private var muscleGroup: String
    @State private var equipment: String
    @State private var alternatives: String
    
    init(exercise: ExRxExercise, onSave: @escaping (ExRxExercise) -> Void, onCancel: @escaping () -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: exercise.name)
        _category = State(initialValue: exercise.category)
        _muscleGroup = State(initialValue: exercise.muscleGroup)
        _equipment = State(initialValue: exercise.equipment ?? "")
        _alternatives = State(initialValue: (exercise.alternatives ?? []).joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ExRxCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat.rawValue)
                        }
                    }
                    
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(ExRxMuscleGroup.allCases, id: \.self) { mg in
                            Text(mg.rawValue).tag(mg.rawValue)
                        }
                    }
                    
                    TextField("Equipment (optional)", text: $equipment)
                    
                    TextField("Alternatives (comma-separated)", text: $alternatives)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let alternativesArray = alternatives
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        
                        let updatedExercise = ExRxExercise(
                            id: exercise.id,
                            name: name,
                            category: category,
                            muscleGroup: muscleGroup,
                            equipment: equipment.isEmpty ? nil : equipment,
                            url: exercise.url,
                            alternatives: alternativesArray.isEmpty ? nil : alternativesArray
                        )
                        
                        onSave(updatedExercise)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    MasterExerciseListView()
        .padding()
        .background(AppColors.background)
}

