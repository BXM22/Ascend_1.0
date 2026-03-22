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
    @Environment(\.kineticPalette) private var kp

    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var showHistory = false
    @State private var showAlternatives = false
    @State private var showDropsetSettings = false
    @State private var showDeleteConfirmation = false
    /// Snapshot of last-session line for the "Previous" column (does not change mid-set as history updates).
    @State private var previousSessionLine: String = "—"
    @State private var previousSessionExerciseId: UUID?

    private var mainWorkingSets: [ExerciseSet] {
        exercise.sets.filter { !$0.isDropset && !$0.isWarmup }.sorted { $0.setNumber < $1.setNumber }
    }

    private var nextSetNumber: Int {
        (mainWorkingSets.last?.setNumber ?? 0) + 1
    }

    private var suggestion: (weight: Double, reps: Int)? {
        viewModel.getWeightSuggestion(for: exercise)
    }

    private var canCompleteSet: Bool {
        !weight.isEmpty && !reps.isEmpty
    }

    private var setRowRange: ClosedRange<Int> {
        let n = max(1, exercise.targetSets)
        return 1...n
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Set \(min(nextSetNumber, max(1, exercise.targetSets))) of \(exercise.targetSets)")
                    .font(KineticWorkoutTypography.bold(11))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.primary)
                Spacer(minLength: 0)
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(kp.tertiary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Exercise options")
            }

            if let suggestion, nextSetNumber <= exercise.targetSets {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(kp.primary)
                    Text("Suggested \(Int(suggestion.weight)) lbs × \(suggestion.reps)")
                        .font(KineticWorkoutTypography.medium(12))
                        .foregroundStyle(kp.tertiary)
                    Spacer(minLength: 0)
                    Button("Use") {
                        weight = "\(Int(suggestion.weight))"
                        reps = "\(suggestion.reps)"
                        HapticManager.impact(style: .light)
                    }
                    .font(KineticWorkoutTypography.bold(12))
                    .foregroundStyle(kp.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(kp.primaryContainer.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(spacing: 0) {
                kineticTableHeader
                ForEach(Array(setRowRange), id: \.self) { setNum in
                    kineticSetRow(setNumber: setNum)
                }
                Button(action: {
                    viewModel.addWorkingSetSlot(exerciseId: exercise.id)
                }) {
                    Text("+ Add Set")
                        .font(KineticWorkoutTypography.bold(10))
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .disabled(exercise.targetSets >= AppConstants.Validation.maxSets)
                .opacity(exercise.targetSets >= AppConstants.Validation.maxSets ? 0.35 : 1)
                .accessibilityLabel("Add set")
                .accessibilityHint("Increases planned sets for this exercise up to \(AppConstants.Validation.maxSets)")
            }
        }
        .padding(16)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.15), lineWidth: 1)
        )
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
            refreshPreviousSessionSnapshotIfNeeded()
            applyInitialPrefill()
        }
        .onChange(of: exercise.id) { _, _ in
            refreshPreviousSessionSnapshotIfNeeded()
            applyInitialPrefill()
        }
        .onChange(of: exercise.sets.count) { oldCount, newCount in
            if newCount > oldCount {
                prefillAfterLoggingWorkingSet()
            }
        }
    }

    private var kineticTableHeader: some View {
        HStack(spacing: 0) {
            Text("Set")
                .frame(width: 28, alignment: .leading)
            Text("Previous")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Weight")
                .frame(width: 72, alignment: .center)
            Text("Reps")
                .frame(width: 96, alignment: .center)
        }
        .font(KineticWorkoutTypography.bold(10))
        .tracking(2.4)
        .textCase(.uppercase)
        .foregroundStyle(kp.tertiary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(kp.surfaceContainerHighest.opacity(0.5))
    }

    @ViewBuilder
    private func kineticSetRow(setNumber: Int) -> some View {
        let completed = mainWorkingSets.first { $0.setNumber == setNumber }
        let isCurrent = completed == nil && setNumber == nextSetNumber
        let isFuture = completed == nil && setNumber > nextSetNumber

        HStack(spacing: 0) {
            Text("\(setNumber)")
                .font(KineticWorkoutTypography.bold(14))
                .foregroundStyle(kp.onSurface)
                .frame(width: 28, alignment: .leading)

            Text(previousSessionLine)
                .font(KineticWorkoutTypography.medium(12))
                .foregroundStyle(kp.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 4)

            if let done = completed {
                Text("\(Int(done.weight))")
                    .font(KineticWorkoutTypography.bold(14))
                    .foregroundStyle(kp.primary)
                    .frame(width: 72)
                HStack(spacing: 6) {
                    Text("\(done.reps)")
                        .font(KineticWorkoutTypography.bold(14))
                        .foregroundStyle(kp.primary)
                        .frame(minWidth: 28)
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(kp.primaryContainer)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 96, alignment: .trailing)
            } else if isCurrent {
                TextField("", text: $weight)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(KineticWorkoutTypography.bold(14))
                    .foregroundStyle(kp.primary)
                    .padding(.vertical, 6)
                    .background(kp.surfaceContainerHighest)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(width: 72)

                HStack(spacing: 6) {
                    TextField("", text: $reps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(KineticWorkoutTypography.bold(14))
                        .foregroundStyle(kp.primary)
                        .padding(.vertical, 6)
                        .background(kp.surfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(width: 52)
                    Button(action: completeSet) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(canCompleteSet ? kp.primaryContainer : kp.surfaceContainerHighest)
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(canCompleteSet ? Color.white : kp.onSurface.opacity(0.2))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCompleteSet)
                    .accessibilityLabel("Complete set")
                }
                .frame(width: 96, alignment: .trailing)
            } else {
                Text(ghostWeight(for: setNumber))
                    .font(KineticWorkoutTypography.bold(14))
                    .foregroundStyle(kp.onSurface.opacity(0.35))
                    .frame(width: 72)
                    .padding(.vertical, 6)
                    .background(kp.surfaceContainerHighest.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack(spacing: 6) {
                    Text(ghostReps(for: setNumber))
                        .font(KineticWorkoutTypography.bold(14))
                        .foregroundStyle(kp.onSurface.opacity(0.35))
                        .frame(width: 52)
                        .padding(.vertical, 6)
                        .background(kp.surfaceContainerHighest.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(kp.surfaceContainerHighest)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(kp.onSurface.opacity(0.2))
                    }
                }
                .frame(width: 96, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(completed != nil ? kp.primaryContainer.opacity(0.05) : Color.clear)
        .opacity(isFuture ? 0.4 : 1)
    }

    private func ghostWeight(for setNumber: Int) -> String {
        if let last = mainWorkingSets.last {
            return String(format: "%.0f", last.weight)
        }
        if let s = suggestion {
            return "\(Int(s.weight))"
        }
        if let w = viewModel.getLastWeight(for: exercise.name) {
            return String(format: "%.0f", w)
        }
        return "—"
    }

    private func ghostReps(for _: Int) -> String {
        if let last = mainWorkingSets.last {
            return "\(last.reps)"
        }
        if let s = suggestion {
            return "\(s.reps)"
        }
        return "8"
    }

    private func refreshPreviousSessionSnapshotIfNeeded() {
        if previousSessionExerciseId != exercise.id {
            previousSessionExerciseId = exercise.id
            if let h = ExerciseHistoryManager.shared.getLastWeightReps(for: exercise.name) {
                previousSessionLine = "\(Int(h.weight)) lbs × \(h.reps)"
            } else {
                previousSessionLine = "—"
            }
        }
    }

    /// First paint or switching exercises — fill the active row from history / suggestion / last weight.
    private func applyInitialPrefill() {
        guard nextSetNumber <= exercise.targetSets else { return }
        if let last = mainWorkingSets.last {
            weight = String(format: "%.0f", last.weight)
            reps = "\(last.reps)"
            return
        }
        if let s = suggestion {
            weight = "\(Int(s.weight))"
            reps = "\(s.reps)"
            return
        }
        if let w = viewModel.getLastWeight(for: exercise.name), w > 0 {
            weight = String(format: "%.0f", w)
            if reps.isEmpty { reps = "8" }
        }
    }

    /// After logging a set, default the next row to match the last working set (dropsets excluded).
    private func prefillAfterLoggingWorkingSet() {
        guard nextSetNumber <= exercise.targetSets else { return }
        guard let last = mainWorkingSets.last else { return }
        weight = String(format: "%.0f", last.weight)
        reps = "\(last.reps)"
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
