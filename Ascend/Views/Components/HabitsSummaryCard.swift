//
//  HabitsSummaryCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitsSummaryCard: View {
    @ObservedObject var viewModel: HabitViewModel
    let onTap: (() -> Void)?
    
    init(viewModel: HabitViewModel, onTap: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onTap = onTap
    }
    
    private var totalStreak: Int {
        viewModel.activeHabits.reduce(0) { total, habit in
            total + viewModel.getStreak(habitId: habit.id)
        }
    }
    
    private var averageStreak: Double {
        guard viewModel.totalHabits > 0 else { return 0 }
        return Double(totalStreak) / Double(viewModel.totalHabits)
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: {
                    HapticManager.selection()
                    onTap()
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
            HStack(spacing: 12) {
                // Icon (smaller)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(LinearGradient.primaryGradient.opacity(0.15))
                    )
                
                // Compact stats
                VStack(alignment: .leading, spacing: 2) {
                    Text("Habits")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    HStack(spacing: 8) {
                        Text("\(viewModel.totalHabits) active")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        if viewModel.totalHabits > 0 {
                            Text("•")
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Text("\(viewModel.todayCompletions)/\(viewModel.totalHabits) today")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                    }
                }
                
                Spacer()
                
                // Stats (compact)
                if viewModel.totalHabits > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Completion rate
                        HStack(spacing: 4) {
                            Text("\(Int(viewModel.todayCompletionRate * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(LinearGradient.primaryGradient)
                        }
                        
                        // Average streak
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HabitGradientHelper.streakGradient)
                            
                            Text("\(Int(averageStreak))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    HabitsSummaryCard(
        viewModel: HabitViewModel(),
        onTap: {}
    )
    .padding()
    .background(AppColors.background)
}


