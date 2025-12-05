import SwiftUI

struct PreviousSetsView: View {
    let sets: [ExerciseSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Previous Sets")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                SetRow(set: set)
                    .animateOnAppear(delay: Double(index) * 0.1, animation: AppAnimations.listItem)
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct SetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Text("Set \(set.setNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                if let holdDuration = set.holdDuration {
                    Text("\(holdDuration) seconds")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                } else {
                    Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

#Preview {
    PreviousSetsView(sets: [
        ExerciseSet(setNumber: 1, weight: 185, reps: 8),
        ExerciseSet(setNumber: 2, weight: 185, reps: 8),
        ExerciseSet(setNumber: 3, weight: 185, reps: 7)
    ])
    .padding()
    .background(AppColors.background)
}

