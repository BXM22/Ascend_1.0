//
//  StreakWorkoutCard.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Combined card showing streak and total workout count
struct StreakWorkoutCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private var currentStreak: Int {
        progressViewModel.currentStreak
    }
    
    private var workoutCount: Int {
        progressViewModel.workoutCount
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Streak Section
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(currentStreak)")
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.foreground)
                    Text("day streak")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(AppColors.border.opacity(0.3))
                .frame(width: 1, height: 36)
            
            // Workout Count Section
            HStack(spacing: 10) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(workoutCount)")
                        .font(AppTypography.numberInput)
                        .foregroundColor(AppColors.foreground)
                    Text("workouts")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
        )
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentStreak) day streak, \(workoutCount) total workouts")
    }
}

// MARK: - Preview
#Preview {
    VStack {
        StreakWorkoutCard(progressViewModel: ProgressViewModel())
    }
    .padding()
    .background(AppColors.background)
}


