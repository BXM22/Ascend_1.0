//
//  SimplifiedExerciseCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

// MARK: - Simplified Exercise Card (Weighted)
struct SimplifiedWeightedExerciseCard: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let exercise: Exercise
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var showHistory = false
    @State private var showAlternatives = false
    @State private var showDropsetSettings = false
    @State private var showDeleteConfirmation = false
    
    var suggestion: (weight: Double, reps: Int)? {
        viewModel.getWeightSuggestion(for: exercise)
    }
    
    var canCompleteSet: Bool {
        !weight.isEmpty && !reps.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    Button(action: { showHistory = true }) {
                        Label("View History", systemImage: "chart.bar")
                    }
                    
                    Button(action: { showAlternatives = true }) {
                        Label("Alternatives", systemImage: "arrow.triangle.swap")
                    }
                    
                    Button(action: { showDropsetSettings = true }) {
                        Label("Dropset Settings", systemImage: "arrow.down.circle")
                    }
                    
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Exercise options")
            }
            
            // Input section
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("lbs", text: $weight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("reps", text: $reps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
            }
            
            // Smart suggestions row
            if let suggestion = suggestion {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Suggested: \(Int(suggestion.weight)) lbs × \(suggestion.reps) reps")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Button("Use") {
                        weight = "\(Int(suggestion.weight))"
                        reps = "\(suggestion.reps)"
                        HapticManager.impact(style: .light)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                }
                .padding(12)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Complete Set button
            Button(action: completeSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canCompleteSet ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: canCompleteSet ? AppColors.accent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            .accessibilityLabel("Complete set")
            .accessibilityHint(canCompleteSet ? "Logs this set and starts rest timer" : "Enter weight and reps first")
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showHistory) {
            if let progressVM = viewModel.progressViewModel {
                ExerciseHistoryView(exerciseName: exercise.name, progressViewModel: progressVM)
            }
        }
        .sheet(isPresented: $showAlternatives) {
            AlternativeExercisesSheet(currentExercise: exercise.name, onSelect: { alt in
                viewModel.switchToAlternative(alternativeName: alt)
                showAlternatives = false
            })
        }
        .sheet(isPresented: $showDropsetSettings) {
            DropsetSettingsSheet(
                dropsetsEnabled: $viewModel.dropsetsEnabled,
                numberOfDropsets: $viewModel.numberOfDropsets,
                weightReduction: $viewModel.weightReductionPerDropset
            )
        }
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = viewModel.currentWorkout?.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.removeExercise(at: index)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This will remove all completed sets for this exercise.")
        }
        .onAppear {
            // Pre-fill with last weight
            if let lastWeight = viewModel.getLastWeight(for: exercise.name), lastWeight > 0 {
                weight = String(format: "%.0f", lastWeight)
            }
        }
    }
    
    private func completeSet() {
        guard let weightValue = Double(weight), let repsValue = Int(reps) else { return }
        viewModel.completeSet(weight: weightValue, reps: repsValue, isWarmup: false)
        HapticManager.impact(style: .medium)
    }
}

// MARK: - Previous Set Row
struct PreviousSetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            if set.isWarmup {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }
            
            Text("Set \(set.setNumber)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Spacer()
            
            if set.weight > 0 && set.reps > 0 {
                Text("\(Int(set.weight)) lbs × \(set.reps)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            } else if let duration = set.holdDuration {
                Text("\(duration)s")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if set.isDropset, let dropsetNum = set.dropsetNumber {
                Text("D\(dropsetNum)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Alternative Exercises Sheet
struct AlternativeExercisesSheet: View {
    let currentExercise: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var alternatives: [String] {
        ExerciseDataManager.shared.getAlternatives(for: currentExercise)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(alternatives, id: \.self) { alt in
                    Button(action: {
                        onSelect(alt)
                    }) {
                        HStack {
                            Text(alt)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(LinearGradient.primaryGradient)
                        }
                    }
                }
            }
            .navigationTitle("Alternative Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Dropset Settings Sheet
struct DropsetSettingsSheet: View {
    @Binding var dropsetsEnabled: Bool
    @Binding var numberOfDropsets: Int
    @Binding var weightReduction: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Dropsets", isOn: $dropsetsEnabled)
                }
                
                if dropsetsEnabled {
                    Section {
                        Stepper("Number of Dropsets: \(numberOfDropsets)", value: $numberOfDropsets, in: 1...5)
                        
                        Stepper("Weight Reduction: \(Int(weightReduction)) lbs", value: $weightReduction, in: 5...50, step: 5)
                    } header: {
                        Text("Dropset Configuration")
                    }
                }
            }
            .navigationTitle("Dropset Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
