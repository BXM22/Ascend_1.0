//
//  ExerciseNavigationBar.swift
//  Ascend
//
//  Kinetic workout session — matches SimplifiedWeightedExerciseCard / KineticWorkoutChrome.
//

import SwiftUI

struct ExerciseNavigationBar: View {
    let exercises: [Exercise]
    @Binding var currentIndex: Int
    let onExerciseSelect: (Int) -> Void
    @Environment(\.kineticPalette) private var kp

    private var displayIndex: Int {
        guard !exercises.isEmpty else { return 0 }
        return min(max(0, currentIndex), exercises.count - 1)
    }

    private var hasPrevious: Bool {
        displayIndex > 0
    }

    private var hasNext: Bool {
        displayIndex < exercises.count - 1
    }

    private func isExerciseCompleted(_ exercise: Exercise) -> Bool {
        let working = exercise.sets.filter { !$0.isDropset && !$0.isWarmup }
        return working.count >= exercise.targetSets
    }

    var body: some View {
        Group {
            if exercises.isEmpty {
                EmptyView()
            } else {
                kineticChrome
            }
        }
    }

    private var kineticChrome: some View {
        VStack(spacing: 0) {
            exerciseChipStrip

            Rectangle()
                .fill(kp.surfaceContainerHighest.opacity(0.35))
                .frame(height: 1)

            navigationRow
        }
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
        )
    }

    private var exerciseChipStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    let isActive = index == displayIndex
                    let completed = isExerciseCompleted(exercise)

                    Button {
                        withAnimation(.smooth) {
                            onExerciseSelect(index)
                        }
                        HapticManager.impact(style: .light)
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(index + 1)")
                                .font(KineticWorkoutTypography.bold(12))
                                .monospacedDigit()
                            Text(exerciseShortLabel(exercise.name))
                                .font(KineticWorkoutTypography.semiBold(12))
                                .lineLimit(1)
                        }
                        .foregroundStyle(chipForeground(isActive: isActive, completed: completed))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(chipBackground(isActive: isActive, completed: completed))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(chipStroke(isActive: isActive, completed: completed), lineWidth: isActive ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(exercise.name), \(completed ? "completed" : isActive ? "current" : "not started")")
                    .accessibilityAddTraits(isActive ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 12)
    }

    private func exerciseShortLabel(_ name: String) -> String {
        if name.count <= 18 { return name }
        return String(name.prefix(16)) + "…"
    }

    private func chipForeground(isActive: Bool, completed: Bool) -> Color {
        if isActive {
            return kp.onPrimaryContainer
        }
        if completed {
            return kp.primary
        }
        return kp.tertiary
    }

    private func chipBackground(isActive: Bool, completed: Bool) -> Color {
        if isActive {
            return kp.primaryContainer
        }
        if completed {
            return kp.primaryContainer.opacity(0.18)
        }
        return kp.surfaceContainerHighest.opacity(0.55)
    }

    private func chipStroke(isActive: Bool, completed: Bool) -> Color {
        if isActive {
            return kp.primary.opacity(0.45)
        }
        if completed {
            return kp.primary.opacity(0.25)
        }
        return kp.outlineVariant.opacity(0.25)
    }

    private var navigationRow: some View {
        HStack(spacing: 10) {
            navChevronButton(
                systemName: "chevron.left",
                enabled: hasPrevious,
                accessibilityLabel: "Previous exercise",
                hint: hasPrevious ? "Navigate to previous exercise" : "No previous exercise"
            ) {
                withAnimation(.smooth) {
                    onExerciseSelect(displayIndex - 1)
                }
                HapticManager.impact(style: .light)
            }

            VStack(spacing: 4) {
                Text(exercises[displayIndex].name)
                    .font(KineticWorkoutTypography.bold(17))
                    .foregroundStyle(kp.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text("Exercise \(displayIndex + 1) of \(exercises.count)")
                    .font(KineticWorkoutTypography.bold(10))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary)
            }
            .frame(maxWidth: .infinity)

            navChevronButton(
                systemName: "chevron.right",
                enabled: hasNext,
                accessibilityLabel: "Next exercise",
                hint: hasNext ? "Navigate to next exercise" : "No next exercise"
            ) {
                withAnimation(.smooth) {
                    onExerciseSelect(displayIndex + 1)
                }
                HapticManager.impact(style: .light)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }

    private func navChevronButton(
        systemName: String,
        enabled: Bool,
        accessibilityLabel: String,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? kp.primary : kp.tertiary.opacity(0.35))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(kp.surfaceContainerHighest.opacity(enabled ? 1 : 0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(kp.outlineVariant.opacity(enabled ? 0.25 : 0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(hint)
    }
}
