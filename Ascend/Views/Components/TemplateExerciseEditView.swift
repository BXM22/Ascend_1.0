import SwiftUI

struct TemplateExerciseEditView: View {
    @Binding var exercise: TemplateExercise
    @State private var showDeleteConfirmation = false
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.destructive)
                        .font(.system(size: 14))
                }
            }
            
            // Sets
            HStack {
                Text("Sets:")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
                Stepper(value: $exercise.sets, in: 1...10) {
                    Text("\(exercise.sets)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                }
            }
            
            // Reps
            VStack(alignment: .leading, spacing: 8) {
                Text("Reps:")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
                TextField("e.g., 8-10, AMRAP, 5", text: Binding(
                    get: { exercise.reps },
                    set: { exercise.reps = $0 }
                ))
                .font(.system(size: 14))
                .foregroundColor(AppColors.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.input)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Dropsets Toggle
            Toggle(isOn: Binding(
                get: { exercise.dropsets },
                set: { exercise.dropsets = $0 }
            )) {
                Text("Dropsets")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.foreground)
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
        }
        .padding(16)
        .background(AppColors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete Exercise?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove this exercise from the template?")
        }
    }
}

