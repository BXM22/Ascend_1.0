//
//  TemplateDetailView.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
    private var gradient: LinearGradient {
        AppColors.templateGradient(for: template)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: AppSpacing.lg) {
                    // Template Header
                    VStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(gradient.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(gradient)
                        }
                        
                        Text(template.name)
                            .font(AppTypography.heading1)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Metadata badges
                        HStack(spacing: 12) {
                            MetadataBadge(
                                icon: "figure.mixed.cardio",
                                text: "\(template.exercises.count) exercises",
                                gradient: gradient
                            )
                            
                            if template.estimatedDuration > 0 {
                                MetadataBadge(
                                    icon: "clock.fill",
                                    text: "\(template.estimatedDuration) min",
                                    gradient: gradient
                                )
                            }
                            
                            if let intensity = template.intensity {
                                MetadataBadge(
                                    icon: "flame.fill",
                                    text: intensity.rawValue,
                                    gradient: gradient
                                )
                            }
                            
                            // Color indicator badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(AppColors.templateColor(for: template))
                                    .frame(width: 12, height: 12)
                                Text(template.colorHex == nil ? "Auto" : "Custom")
                                    .font(AppTypography.caption)
                            }
                            .foregroundStyle(gradient)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(gradient.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.top, AppSpacing.md)
                    
                    // Exercise List - Use LazyVStack for better performance
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Exercises")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(Array(template.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseDetailRow(
                                    exercise: exercise,
                                    index: index,
                                    gradient: gradient
                                )
                                .padding(.horizontal, AppSpacing.lg)
                                .id("exercise-\(exercise.id)")
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: AppSpacing.md) {
                        // Primary Action: Start Workout
                        Button(action: {
                            HapticManager.impact(style: .medium)
                            onStart()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                Text("Start Workout")
                                    .font(AppTypography.bodyBold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityLabel("Start workout with \(template.name)")
                        
                        // Secondary Action: Edit
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onEdit()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                Text("Edit Template")
                                    .font(AppTypography.bodyBold)
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .accessibilityLabel("Edit \(template.name)")
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .accessibilityLabel("Close")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onDuplicate()
                            dismiss()
                        }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        
                        if onDelete != nil {
                            Divider()
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .accessibilityLabel("More actions")
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
            }
            .onAppear {
                // Cache template for faster subsequent loads
                CardDetailCacheManager.shared.cacheTemplate(template)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

struct MetadataBadge: View {
    let icon: String
    let text: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(AppTypography.caption)
        }
        .foregroundStyle(gradient)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(gradient.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ExerciseDetailRow: View {
    let exercise: TemplateExercise
    let index: Int
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Exercise number badge
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(gradient)
            }
            
            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text("\(exercise.sets) sets")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("•")
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("\(exercise.reps) reps")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    if exercise.dropsets {
                        Text("•")
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 10))
                            Text("Dropsets")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accent)
                    }
                    
                    if let holdDuration = exercise.targetHoldDuration {
                        Text("•")
                            .foregroundColor(AppColors.mutedForeground)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text("\(holdDuration)s hold")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    TemplateDetailView(
        template: WorkoutTemplate(
            name: "Push Day",
            exercises: [
                TemplateExercise(name: "Bench Press", sets: 4, reps: "8-10", dropsets: false, exerciseType: .weightReps),
                TemplateExercise(name: "Overhead Press", sets: 3, reps: "10-12", dropsets: false, exerciseType: .weightReps),
                TemplateExercise(name: "Tricep Dips", sets: 3, reps: "12-15", dropsets: true, exerciseType: .weightReps)
            ],
            estimatedDuration: 60,
            intensity: .moderate
        ),
        onStart: {},
        onEdit: {},
        onDuplicate: {},
        onDelete: {}
    )
}
