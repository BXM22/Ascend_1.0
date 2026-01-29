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
    @State private var isProgressExpanded = true
    
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
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                HapticManager.success()
                                viewModel.toggleCompletion(habitId: habit.id)
                            }) {
                                Image(systemName: viewModel.isCompleted(habitId: habit.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(
                                        viewModel.isCompleted(habitId: habit.id)
                                            ? habitGradient(for: habit)
                                            : HabitGradientHelper.mutedGradient
                                    )
                            }
                            .accessibilityLabel(viewModel.isCompleted(habitId: habit.id) ? "Mark habit as incomplete" : "Mark habit as complete")
                        }
                        
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
            statsScrollView(for: habit)
            progressSection(for: habit)
        }
    }
    
    private func headerCard(for habit: Habit) -> some View {
        VStack(spacing: 12) {
            // Icon (smaller)
            ZStack {
                Circle()
                    .fill(habitGradient(for: habit).opacity(0.2))
                    .frame(width: 64, height: 64)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(habitGradient(for: habit))
            }
            
            // Name (smaller)
            Text(habit.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            // Duration (smaller)
            Text("\(habit.completionDuration) minutes")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(AppSpacing.md)
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
    
    private func statsScrollView(for habit: Habit) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CompactStatCard(
                    title: "Current Streak",
                    value: "\(viewModel.getStreak(habitId: habit.id))",
                    subtitle: "days",
                    gradient: HabitGradientHelper.streakGradient,
                    icon: "flame.fill"
                )
                
                CompactStatCard(
                    title: "Longest Streak",
                    value: "\(viewModel.getLongestStreak(habitId: habit.id))",
                    subtitle: "days",
                    gradient: habitGradient(for: habit),
                    icon: "star.fill"
                )
                
                CompactStatCard(
                    title: "Completed",
                    value: "\(viewModel.getCompletionCount(habitId: habit.id))",
                    subtitle: "times",
                    gradient: habitGradient(for: habit),
                    icon: "checkmark.circle.fill"
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func progressSection(for habit: Habit) -> some View {
        if let progress = viewModel.getProgress(habitId: habit.id), let target = habit.targetStreakDays {
            CollapsibleProgressSection(
                habit: habit,
                progress: progress,
                currentStreak: viewModel.getStreak(habitId: habit.id),
                target: target,
                isExpanded: $isProgressExpanded
            )
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

