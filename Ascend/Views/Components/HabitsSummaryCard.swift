//
//  HabitsSummaryCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitsSummaryCard: View {
    @ObservedObject var viewModel: HabitViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap()
        }) {
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
                
                // Completion rate (compact)
                if viewModel.totalHabits > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(viewModel.todayCompletionRate * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("complete")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.mutedForeground)
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
        .buttonStyle(PlainButtonStyle())
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


