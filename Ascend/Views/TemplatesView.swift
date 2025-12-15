//
//  TemplatesView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct TemplatesView: View {
    @ObservedObject var viewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartTemplate: () -> Void
    let onSettings: () -> Void
    @State private var showGenerateSheet = false
    @State private var showCalisthenicProgression = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var debounceTask: Task<Void, Never>?
    
    // Cache filtered templates to avoid recalculating on every render
    private var filteredTemplates: [WorkoutTemplate] {
        viewModel.templates.filter { template in
            if template.name.contains("Progression") { return false }
            if debouncedSearchText.isEmpty { return true }
            return template.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
                   template.exercises.contains { $0.name.localizedCaseInsensitiveContains(debouncedSearchText) }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                TemplatesHeader(
                    onCreate: {
                        // Removed direct create button from header
                    },
                    onGenerate: {
                        showGenerateSheet = true
                    },
                    onSettings: {
                        viewModel.showGenerationSettings = true
                    },
                    onMainSettings: onSettings
                )
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.mutedForeground)
                    TextField("Search templates...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.foreground)
                        .onChange(of: searchText) { _, newValue in
                            // Cancel previous debounce task
                            debounceTask?.cancel()
                            
                            // Debounce the search
                            debounceTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                if !Task.isCancelled {
                                    debouncedSearchText = newValue
                                }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                
                VStack(spacing: AppSpacing.lg) {
                    // Workout Programs Section
                    WorkoutSplitsSection(
                        programViewModel: programViewModel,
                        templatesViewModel: viewModel,
                        workoutViewModel: workoutViewModel,
                        onStartWorkout: onStartTemplate
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                    
                    // Calisthenics Skills Section
                    CalisthenicsSkillsSection(
                        workoutViewModel: workoutViewModel,
                        templatesViewModel: viewModel,
                        onStart: onStartTemplate
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Regular Templates Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Workout Templates")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        // Stacked action buttons under header
                        VStack(spacing: 10) {
                            Button(action: {
                                viewModel.createTemplate()
                            }) {
                                Text("Add Template")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.alabasterGrey)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(LinearGradient.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button(action: {
                                showCalisthenicProgression = true
                            }) {
                                Text("Add Calisthenic Skill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.alabasterGrey)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(LinearGradient(colors: [AppColors.backGradientStart, AppColors.backGradientEnd], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        ForEach(filteredTemplates, id: \.id) { template in
                            TemplateCard(
                                template: template,
                                onStart: {
                                    viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                    onStartTemplate()
                                },
                                onEdit: {
                                    viewModel.editTemplate(template)
                                },
                                onDelete: template.isDefault ? nil : {
                                    viewModel.deleteTemplate(template)
                                }
                            )
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $viewModel.showEditTemplate) {
            if let template = viewModel.editingTemplate {
                TemplateEditView(
                    template: template,
                    onSave: { template in
                        viewModel.saveTemplate(template)
                    },
                    onCancel: {
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    },
                    onDelete: {
                        viewModel.deleteTemplate(template)
                        viewModel.showEditTemplate = false
                        viewModel.editingTemplate = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showCreateTemplate) {
            TemplateEditView(
                template: nil,
                onSave: { template in
                    viewModel.saveTemplate(template)
                },
                onCancel: {
                    viewModel.showCreateTemplate = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showGenerationSettings) {
            WorkoutGenerationSettingsView(settings: $viewModel.generationSettings)
        }
        .sheet(isPresented: $showGenerateSheet) {
            WorkoutGenerationView(viewModel: viewModel, onStart: onStartTemplate)
        }
        .sheet(isPresented: $showCalisthenicProgression) {
            CreateCustomSkillView(skillManager: CalisthenicsSkillManager.shared)
        }
    }
}

struct TemplatesHeader: View {
    let onCreate: () -> Void
    let onGenerate: () -> Void
    let onSettings: () -> Void // Generation settings
    let onMainSettings: () -> Void // Main app settings
    
    var body: some View {
        HStack {
            Text("Templates")
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            HStack(spacing: 12) {
                HelpButton(pageType: .templates)
                
                // Main Settings Button
                Button(action: {
                    HapticManager.impact(style: .light)
                    onMainSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Settings")
                
                // Generation Settings Button
                Button(action: onSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Generation Settings")
                
                Button(action: onGenerate) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: (() -> Void)?
    @State private var isHovered = false
    @State private var showDeleteConfirmation = false
    
    // Determine muscle group from first exercise
    private var muscleGroup: String {
        template.exercises.first?.name ?? "General"
    }
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: muscleGroup)
    }
    
    var body: some View {
        GradientBorderedCard(gradient: gradient) {
            VStack(alignment: .leading, spacing: 16) {
                // Template Header with icon
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(gradient.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(gradient)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.foreground)
                        
                        Text("\(template.exercises.count) exercises")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        // Delete button for custom templates
                        if !template.isDefault {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.destructive)
                                    .frame(width: 32, height: 32)
                                    .background(AppColors.destructive.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Intensity badge
                        if let intensity = template.intensity {
                            Text(intensity.rawValue)
                                .font(AppTypography.captionMedium)
                                .foregroundStyle(gradient)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(gradient.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onStart) {
                        Text("Start")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: AppColors.foreground.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(AppSpacing.md)
        }
        .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
        }
    }
}

// MARK: - Calisthenic Progression Sheet
struct CalisthenicProgressionSheet: View {
    let skills: [CalisthenicsSkill]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(skills) { skill in
                    Section {
                        Text("Goal: \(skill.description)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.bottom, 4)
                        
                        Text("Levels: \(skill.progressionLevels.count)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 6)
                        
                        ForEach(skill.progressionLevels) { level in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Level \(level.level): \(level.name)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(level.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                if let hold = level.targetHoldDuration {
                                    Text("Target: \(hold) sec hold")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                } else if let reps = level.targetReps {
                                    Text("Target: \(reps) reps")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                } else {
                                    Text("Target: reps or hold time")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.foreground)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    } header: {
                        Text(skill.name)
                            .font(.headline)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Skill Progressions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Add Exercise View
struct AddExerciseView: View {
    @State private var exerciseName: String = ""
    @State private var targetSets: Int = 4
    @State private var exerciseType: ExerciseType = .weightReps
    @State private var holdDuration: Int = 30
    @State private var showAddCustomExercise = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    let onAdd: (String, Int, ExerciseType, Int) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercise Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddCustomExercise = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Create Custom")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(AppColors.primary)
                            }
                        }
                        
                        ExerciseAutocompleteField(
                            text: $exerciseName,
                            placeholder: "e.g., Bench Press"
                        )
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    HStack(spacing: 12) {
                        Button(action: { exerciseType = .weightReps }) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                Text("Weight/Reps")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(exerciseType == .weightReps ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(exerciseType == .weightReps ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { exerciseType = .hold }) {
                            HStack {
                                Image(systemName: "timer")
                                Text("Hold")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(exerciseType == .hold ? AppColors.alabasterGrey : AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(exerciseType == .hold ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
                if exerciseType == .hold {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Hold Duration (seconds)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Stepper(value: $holdDuration, in: 5...300, step: 5) {
                            Text("\(holdDuration) seconds")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(AppColors.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Stepper(value: $targetSets, in: 1...10) {
                        Text("\(targetSets) sets")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
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
                    
                    Button(action: {
                        if !exerciseName.isEmpty {
                            onAdd(exerciseName, targetSets, exerciseType, holdDuration)
                        }
                    }) {
                        Text("Add Exercise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.alabasterGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                    }
                    .disabled(exerciseName.isEmpty)
                    .opacity(exerciseName.isEmpty ? 0.6 : 1.0)
                }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if exerciseName.isEmpty {
                        exerciseName = exercise.name
                    }
                }
            }
        }
    }
}

// MARK: - Template Edit View
struct TemplateEditView: View {
    @State private var templateName: String
    @State private var exercises: [TemplateExercise]
    @State private var intensity: WorkoutIntensity?
    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: String = "8-10"
    @State private var newExerciseDropsets: Bool = false
    @State private var newExerciseType: ExerciseType = .weightReps
    @State private var newExerciseHoldDuration: Int = 30
    @State private var showAddCustomExercise = false
    @State private var showClearTemplateConfirmation = false
    @ObservedObject private var exerciseDataManager = ExerciseDataManager.shared
    
    private let originalTemplate: WorkoutTemplate?
    let onSave: (WorkoutTemplate) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    init(template: WorkoutTemplate?, onSave: @escaping (WorkoutTemplate) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.originalTemplate = template
        if let template = template {
            _templateName = State(initialValue: template.name)
            _exercises = State(initialValue: template.exercises)
            _intensity = State(initialValue: template.intensity)
        } else {
            _templateName = State(initialValue: "")
            _exercises = State(initialValue: [])
            _intensity = State(initialValue: nil)
        }
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Template Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Template Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("e.g., Push Day", text: $templateName)
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
                    
                    // Intensity Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Intensity (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Picker("Intensity", selection: $intensity) {
                            Text("None").tag(WorkoutIntensity?.none)
                            ForEach(WorkoutIntensity.allCases, id: \.self) { intensityOption in
                                Text(intensityOption.rawValue).tag(WorkoutIntensity?.some(intensityOption))
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Exercises")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                            
                            // Clear Template Button (only show if there are exercises)
                            if !exercises.isEmpty {
                                Button(action: {
                                    showClearTemplateConfirmation = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                        Text("Clear All")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.destructive)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.destructive.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        ForEach(exercises) { exercise in
                            TemplateExerciseEditView(
                                exercise: Binding(
                                    get: { 
                                        exercises.first(where: { $0.id == exercise.id }) ?? exercise
                                    },
                                    set: { newValue in
                                        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                            exercises[index] = newValue
                                        }
                                    }
                                ),
                                onDelete: {
                                    if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                        exercises.remove(at: index)
                                    }
                                }
                            )
                        }
                        
                        // Add Exercise Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add Exercise")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                Spacer()
                                
                                Button(action: {
                                    showAddCustomExercise = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 12))
                                        Text("Create Custom")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.primary)
                                }
                            }
                            
                            ExerciseAutocompleteField(
                                text: $newExerciseName,
                                placeholder: "Exercise name",
                                fontSize: 16
                            )
                            
                            HStack(spacing: 12) {
                                // Sets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Stepper(value: $newExerciseSets, in: 1...10) {
                                        Text("\(newExerciseSets)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.foreground)
                                    }
                                }
                                
                                // Reps
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reps")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    TextField("8-10", text: $newExerciseReps)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.foreground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(AppColors.input)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                
                                // Dropsets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dropsets")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                    Toggle("", isOn: $newExerciseDropsets)
                                        .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                                }
                            }
                            
                            Button(action: {
                                if !newExerciseName.isEmpty {
                                    let newExercise = TemplateExercise(
                                        name: newExerciseName,
                                        sets: newExerciseSets,
                                        reps: newExerciseReps,
                                        dropsets: newExerciseDropsets,
                                        exerciseType: newExerciseType,
                                        targetHoldDuration: newExerciseType == .hold ? newExerciseHoldDuration : nil
                                    )
                                    exercises.append(newExercise)
                                    newExerciseName = ""
                                    newExerciseSets = 3
                                    newExerciseReps = "8-10"
                                    newExerciseDropsets = false
                                    newExerciseType = .weightReps
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.alabasterGrey)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(newExerciseName.isEmpty)
                            .opacity(newExerciseName.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(16)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Delete Button (only for editing non-default templates)
                    if onDelete != nil && !(originalTemplate?.isDefault ?? false) {
                        Button(action: {
                            onDelete?()
                        }) {
                            Text("Delete Template")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.secondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppColors.destructive, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    // Show message for default templates
                    if originalTemplate?.isDefault ?? false {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text("This is a default template and cannot be deleted")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle(templateName.isEmpty ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showAddCustomExercise) {
                AddCustomExerciseView { exercise in
                    exerciseDataManager.addCustomExercise(exercise)
                    // Pre-fill the exercise name if it was already typed
                    if newExerciseName.isEmpty {
                        newExerciseName = exercise.name
                    }
                }
            }
            .alert("Clear All Exercises?", isPresented: $showClearTemplateConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    exercises.removeAll()
                }
            } message: {
                Text("This will remove all exercises from the template. This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let template: WorkoutTemplate
                        if let original = originalTemplate {
                            // Preserve ID when editing, keep existing estimatedDuration
                            template = WorkoutTemplate(
                                id: original.id,
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: original.estimatedDuration,
                                intensity: intensity
                            )
                        } else {
                            // New template gets new ID, use default estimatedDuration
                            template = WorkoutTemplate(
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: 60,
                                intensity: intensity
                            )
                        }
                        onSave(template)
                    }
                    .disabled(templateName.isEmpty || exercises.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TemplatesView(
        viewModel: TemplatesViewModel(),
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        programViewModel: WorkoutProgramViewModel(),
        onStartTemplate: {},
        onSettings: {}
    )
}
