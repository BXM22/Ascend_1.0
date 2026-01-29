//
//  HabitCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitCard: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    let onTap: (() -> Void)?
    
    private var currentStreak: Int {
        viewModel.getStreak(habitId: habit.id)
    }
    
    private var completionCount: Int {
        viewModel.getCompletionCount(habitId: habit.id)
    }
    
    private var progress: Double? {
        viewModel.getProgress(habitId: habit.id)
    }
    
    private var isCompletedToday: Bool {
        viewModel.isCompleted(habitId: habit.id)
    }
    
    private var habitGradient: LinearGradient {
        HabitGradientHelper.gradient(for: habit)
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and name
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(habitGradient.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(habitGradient)
                    }
                    
                    // Name and duration
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                            .lineLimit(1)
                        
                        Text("\(habit.completionDuration) min")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    // Completion checkmark
                    if isCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(habitGradient)
                    }
                }
                
                // Divider
                Divider()
                    .background(AppColors.border.opacity(0.3))
                
                // Stats row
                HStack(spacing: 20) {
                    // Streak
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HabitGradientHelper.streakGradient)
                            
                            Text("\(currentStreak)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                        }
                        
                        Text("day streak")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    // Completions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(completionCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("completed")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    Spacer()
                    
                    // Progress bar (if target exists)
                    if let progress = progress, let target = habit.targetStreakDays {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            ProgressBarView(
                                progress: progress,
                                gradient: habitGradient,
                                height: 6,
                                cornerRadius: 4
                            )
                            .frame(width: 80)
                            
                            Text("\(currentStreak)/\(target) days")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                    } else if habit.isForever {
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: "infinity")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Text("Forever")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(habitGradient.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HabitCard(
            habit: Habit(
                name: "Morning Meditation",
                completionDuration: 15,
                targetStreakDays: 30,
                colorHex: "9333ea",
                icon: "brain.head.profile"
            ),
            viewModel: HabitViewModel(),
            onTap: {}
        )
        
        HabitCard(
            habit: Habit(
                name: "Read Books",
                completionDuration: 30,
                targetStreakDays: nil,
                colorHex: "2563eb",
                icon: "book.fill"
            ),
            viewModel: HabitViewModel(),
            onTap: {}
        )
    }
    .padding()
    .background(AppColors.background)
}


