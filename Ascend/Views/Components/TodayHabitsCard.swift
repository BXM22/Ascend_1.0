//
//  TodayHabitsCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct TodayHabitsCard: View {
    @ObservedObject var viewModel: HabitViewModel
    let onTapHabit: ((Habit) -> Void)?
    
    private var habitsDueToday: [Habit] {
        viewModel.habitsDueToday
    }
    
    var body: some View {
        if !habitsDueToday.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Due Today")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Text("\(habitsDueToday.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                // Habit list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(habitsDueToday) { habit in
                            TodayHabitItem(
                                habit: habit,
                                viewModel: viewModel,
                                onTap: {
                                    onTapHabit?(habit)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
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
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - Today Habit Item
struct TodayHabitItem: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    
    let onTap: () -> Void
    
    private var habitGradient: LinearGradient {
        if let hex = habit.colorHex {
            let color = Color(hex: hex)
            return LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient.primaryGradient
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(habitGradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(habitGradient)
                }
                
                // Name
                Text(habit.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                
                // Quick complete button
                Button(action: {
                    HapticManager.success()
                    viewModel.toggleCompletion(habitId: habit.id)
                }) {
                    Image(systemName: viewModel.isCompleted(habitId: habit.id) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(viewModel.isCompleted(habitId: habit.id) ? habitGradient : LinearGradient(colors: [AppColors.mutedForeground], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .frame(width: 100)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    TodayHabitsCard(
        viewModel: HabitViewModel(),
        onTapHabit: { _ in }
    )
    .padding()
    .background(AppColors.background)
}

