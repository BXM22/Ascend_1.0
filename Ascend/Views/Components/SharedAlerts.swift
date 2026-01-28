import SwiftUI

// MARK: - Delete Exercise Alert Modifier
/// A reusable alert for confirming exercise deletion
struct DeleteExerciseAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let exerciseName: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Delete Exercise?", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    HapticManager.impact(style: .medium)
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete '\(exerciseName)'? This will remove all completed sets for this exercise.")
            }
    }
}

extension View {
    /// Presents a standardized delete exercise confirmation alert
    func deleteExerciseAlert(
        isPresented: Binding<Bool>,
        exerciseName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteExerciseAlertModifier(
            isPresented: isPresented,
            exerciseName: exerciseName,
            onDelete: onDelete
        ))
    }
}

// MARK: - Delete Set Alert Modifier
struct DeleteSetAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let setDescription: String
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Delete Set?", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    HapticManager.impact(style: .light)
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this set? \(setDescription)")
            }
    }
}

extension View {
    /// Presents a standardized delete set confirmation alert
    func deleteSetAlert(
        isPresented: Binding<Bool>,
        setDescription: String = "",
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteSetAlertModifier(
            isPresented: isPresented,
            setDescription: setDescription,
            onDelete: onDelete
        ))
    }
}

// MARK: - Discard Changes Alert Modifier
struct DiscardChangesAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onDiscard: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Discard Changes?", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    onDiscard()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
    }
}

extension View {
    /// Presents a standardized discard changes confirmation alert
    func discardChangesAlert(
        isPresented: Binding<Bool>,
        onDiscard: @escaping () -> Void
    ) -> some View {
        modifier(DiscardChangesAlertModifier(
            isPresented: isPresented,
            onDiscard: onDiscard
        ))
    }
}

// MARK: - Finish Workout Alert Modifier
struct FinishWorkoutAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let exerciseCount: Int
    let totalSets: Int
    let onFinish: () -> Void
    let onCancel: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Finish Workout?", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                Button("Finish", role: .none) {
                    HapticManager.success()
                    onFinish()
                }
            } message: {
                if exerciseCount > 0 {
                    Text("You've completed \(totalSets) sets across \(exerciseCount) exercise\(exerciseCount > 1 ? "s" : ""). Ready to finish?")
                } else {
                    Text("You haven't logged any exercises yet. Are you sure you want to finish?")
                }
            }
    }
}

extension View {
    /// Presents a standardized finish workout confirmation alert
    func finishWorkoutAlert(
        isPresented: Binding<Bool>,
        exerciseCount: Int,
        totalSets: Int,
        onFinish: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> some View {
        modifier(FinishWorkoutAlertModifier(
            isPresented: isPresented,
            exerciseCount: exerciseCount,
            totalSets: totalSets,
            onFinish: onFinish,
            onCancel: onCancel
        ))
    }
}
