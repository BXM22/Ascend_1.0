//
//  HabitDetailView.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    
    // Get current habit from manager to reflect updates
    private var currentHabit: Habit? {
        viewModel.habitManager.getHabit(byId: habit.id)
    }
    
    // Check if habit still exists
    private var habitExists: Bool {
        currentHabit != nil
    }
    
    private func habitGradient(for habit: Habit) -> LinearGradient {
        HabitGradientHelper.gradient(for: habit)
    }
    
    var body: some View {
        Group {
            if habitExists, let habit = currentHabit {
                NavigationView {
                    ScrollView {
                        contentView(for: habit)
                            .padding(20)
                    }
                    .background(AppColors.background)
                    .navigationTitle("Habit Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Edit") {
                                showEditSheet = true
                            }
                            .foregroundColor(AppColors.primary)
                        }
                    }
                }
                .sheet(isPresented: $showEditSheet) {
                    editSheet(for: habit)
                }
            } else {
                // Habit was deleted, show empty state and dismiss
                Color.clear
                    .onAppear {
                        dismiss()
                    }
            }
        }
    }
    
    private func contentView(for habit: Habit) -> some View {
        VStack(spacing: 20) {
            headerCard(for: habit)
            statsGrid(for: habit)
            progressSection(for: habit)
            completionButton(for: habit)
        }
    }
    
    private func headerCard(for habit: Habit) -> some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(habitGradient(for: habit).opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(habitGradient(for: habit))
            }
            
            // Name
            Text(habit.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            // Duration
            Text("\(habit.completionDuration) minutes")
                .font(.system(size: 16))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(AppSpacing.lg)
        .background(headerCardBackground(for: habit))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private func headerCardBackground(for habit: Habit) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(habitGradient(for: habit).opacity(0.3), lineWidth: 2)
            )
    }
    
    private func statsGrid(for habit: Habit) -> some View {
        HStack(spacing: 12) {
            StatBox(
                title: "Current Streak",
                value: "\(viewModel.getStreak(habitId: habit.id))",
                subtitle: "days",
                gradient: HabitGradientHelper.streakGradient
            )
            
            StatBox(
                title: "Longest Streak",
                value: "\(viewModel.getLongestStreak(habitId: habit.id))",
                subtitle: "days",
                gradient: habitGradient(for: habit)
            )
            
            StatBox(
                title: "Completed",
                value: "\(viewModel.getCompletionCount(habitId: habit.id))",
                subtitle: "times",
                gradient: habitGradient(for: habit)
            )
        }
    }
    
    @ViewBuilder
    private func progressSection(for habit: Habit) -> some View {
        if let progress = viewModel.getProgress(habitId: habit.id), let target = habit.targetStreakDays {
            VStack(alignment: .leading, spacing: 12) {
                progressHeader(target: target, currentStreak: viewModel.getStreak(habitId: habit.id))
                progressBar(progress: progress, habit: habit)
                progressText(progress: progress)
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
            )
        }
    }
    
    private func progressHeader(target: Int, currentStreak: Int) -> some View {
        HStack {
            Text("Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            Spacer()
            
            Text("\(currentStreak)/\(target) days")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.foreground)
        }
    }
    
    private func progressBar(progress: Double, habit: Habit) -> some View {
        ProgressBarView(
            progress: progress,
            gradient: habitGradient(for: habit)
        )
    }
    
    private func progressText(progress: Double) -> some View {
        Text("\(Int(progress * 100))% complete")
            .font(.system(size: 14))
            .foregroundColor(AppColors.mutedForeground)
    }
    
    private func completionButton(for habit: Habit) -> some View {
        let isCompleted = viewModel.isCompleted(habitId: habit.id)
        return Button(action: {
            HapticManager.success()
            viewModel.toggleCompletion(habitId: habit.id)
        }) {
            HStack {
                completionIcon(isCompleted: isCompleted, habit: habit)
                Text(isCompleted ? "Completed Today" : "Mark as Complete")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                Spacer()
            }
            .padding(AppSpacing.lg)
            .background(completionButtonBackground(isCompleted: isCompleted, habit: habit))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func completionIcon(isCompleted: Bool, habit: Habit) -> some View {
        Group {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(habitGradient(for: habit))
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(HabitGradientHelper.mutedGradient)
            }
        }
    }
    
    
    private func completionButtonBackground(isCompleted: Bool, habit: Habit) -> some View {
        Group {
            if isCompleted {
                RoundedRectangle(cornerRadius: 16)
                    .fill(habitGradient(for: habit).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(habitGradient(for: habit).opacity(0.5), lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private func editSheet(for habit: Habit) -> some View {
        HabitEditView(
            habit: habit,
            onSave: { updatedHabit in
                viewModel.updateHabit(updatedHabit)
                showEditSheet = false
            },
            onCancel: {
                showEditSheet = false
            },
            onDelete: {
                viewModel.deleteHabit(habit)
                dismiss()
            }
        )
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(gradient)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
        )
    }
}

// MARK: - Preview
#Preview {
    HabitDetailView(
        habit: Habit(
            name: "Morning Meditation",
            completionDuration: 15,
            targetStreakDays: 30,
            colorHex: "9333ea",
            icon: "brain.head.profile"
        ),
        viewModel: HabitViewModel()
    )
}

