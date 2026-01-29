//
//  CollapsibleProgressSection.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Collapsible progress section for habit detail view
struct CollapsibleProgressSection: View {
    let habit: Habit
    let progress: Double
    let currentStreak: Int
    let target: Int
    @Binding var isExpanded: Bool
    
    private var habitGradient: LinearGradient {
        HabitGradientHelper.gradient(for: habit)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                HapticManager.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Text("\(currentStreak)/\(target) days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(AppSpacing.md)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isExpanded ? "Collapse progress" : "Expand progress")
            
            // Collapsible Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ProgressBarView(
                        progress: progress,
                        gradient: habitGradient
                    )
                    
                    Text("\(Int(progress * 100))% complete")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack {
        CollapsibleProgressSection(
            habit: Habit(
                name: "Test",
                completionDuration: 15,
                targetStreakDays: 30,
                colorHex: "9333ea"
            ),
            progress: 0.65,
            currentStreak: 20,
            target: 30,
            isExpanded: .constant(true)
        )
        
        CollapsibleProgressSection(
            habit: Habit(
                name: "Test",
                completionDuration: 15,
                targetStreakDays: 30,
                colorHex: "9333ea"
            ),
            progress: 0.65,
            currentStreak: 20,
            target: 30,
            isExpanded: .constant(false)
        )
    }
    .padding()
    .background(AppColors.background)
}

