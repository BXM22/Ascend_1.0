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
    @State private var showGenerateSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                TemplatesHeader(
                    onCreate: {
                        viewModel.createTemplate()
                    },
                    onGenerate: {
                        showGenerateSheet = true
                    },
                    onSettings: {
                        viewModel.showGenerationSettings = true
                    }
                )
                
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
                    CalisthenicsSkillsSection(workoutViewModel: workoutViewModel, onStart: onStartTemplate)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Regular Templates Section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Workout Templates")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        ForEach(viewModel.templates.filter { !$0.name.contains("Progression") }) { template in
                            TemplateCard(
                                template: template,
                                onStart: {
                                    viewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                                    onStartTemplate()
                                },
                                onEdit: {
                                    viewModel.editTemplate(template)
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
    }
}

struct TemplatesHeader: View {
    let onCreate: () -> Void
    let onGenerate: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Templates")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onGenerate) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onCreate) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Template Header
            HStack {
                Text(template.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
            }
            
            // Template Info
            Text("\(template.exercises.count) exercises • ~\(template.estimatedDuration) min")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onStart) {
                    Text("Start")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.alabasterGrey)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: onEdit) {
                    Text("Edit")
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
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Add Exercise View
struct AddExerciseView: View {
    @State private var exerciseName: String = ""
    @State private var targetSets: Int = 4
    @State private var exerciseType: ExerciseType = .weightReps
    @State private var holdDuration: Int = 30
    let onAdd: (String, Int, ExerciseType, Int) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercise Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("e.g., Bench Press", text: $exerciseName)
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
            .background(AppColors.background)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Template Edit View
struct TemplateEditView: View {
    @State private var templateName: String
    @State private var exercises: [String]
    @State private var estimatedDuration: Int
    @State private var newExerciseName: String = ""
    
    private let originalTemplate: WorkoutTemplate?
    let onSave: (WorkoutTemplate) -> Void
    let onCancel: () -> Void
    let onDelete: (() -> Void)?
    
    init(template: WorkoutTemplate?, onSave: @escaping (WorkoutTemplate) -> Void, onCancel: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.originalTemplate = template
        if let template = template {
            _templateName = State(initialValue: template.name)
            _exercises = State(initialValue: template.exercises)
            _estimatedDuration = State(initialValue: template.estimatedDuration)
        } else {
            _templateName = State(initialValue: "")
            _exercises = State(initialValue: [])
            _estimatedDuration = State(initialValue: 60)
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
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                            HStack {
                                Text("\(index + 1). \(exercise)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
                                Button(action: {
                                    exercises.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppColors.destructive)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Add Exercise Input
                        HStack(spacing: 12) {
                            TextField("Exercise name", text: $newExerciseName)
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
                                if !newExerciseName.isEmpty {
                                    exercises.append(newExerciseName)
                                    newExerciseName = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.primary)
                            }
                            .disabled(newExerciseName.isEmpty)
                        }
                    }
                    
                    // Estimated Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Estimated Duration (minutes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Stepper(value: $estimatedDuration, in: 15...180, step: 5) {
                            Text("\(estimatedDuration) min")
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
                    
                    // Delete Button (only for editing)
                    if onDelete != nil {
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
                }
                .padding(24)
            }
            .background(AppColors.background)
            .navigationTitle(templateName.isEmpty ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
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
                            // Preserve ID when editing
                            template = WorkoutTemplate(
                                id: original.id,
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: estimatedDuration
                            )
                        } else {
                            // New template gets new ID
                            template = WorkoutTemplate(
                                name: templateName,
                                exercises: exercises,
                                estimatedDuration: estimatedDuration
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
        workoutViewModel: WorkoutViewModel(),
        programViewModel: WorkoutProgramViewModel(),
        onStartTemplate: {}
    )
}
