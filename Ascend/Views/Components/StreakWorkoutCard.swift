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
        HStack(spacing: 20) {
            // Streak Section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Streak")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                }
                
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("days")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.foreground.opacity(0.7))
            }
            
            // Divider
            Rectangle()
                .fill(AppColors.border.opacity(0.3))
                .frame(width: 1)
                .frame(maxHeight: .infinity)
            
            // Workout Count Section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Workouts")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                }
                
                Text("\(workoutCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("total")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.foreground.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                )
        )
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


