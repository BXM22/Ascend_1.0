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
    
    private var currentStreak: Int {
        viewModel.getStreak(habitId: habit.id)
    }
    
    private var longestStreak: Int {
        viewModel.getLongestStreak(habitId: habit.id)
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
        NavigationView {
            ScrollView {
                contentView
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
            editSheet
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            headerCard
            statsGrid
            progressSection
            completionButton
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(habitGradient.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(habitGradient)
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
        .background(headerCardBackground)
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var headerCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(AppColors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(habitGradient.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatBox(
                title: "Current Streak",
                value: "\(currentStreak)",
                subtitle: "days",
                gradient: streakGradient
            )
            
            StatBox(
                title: "Longest Streak",
                value: "\(longestStreak)",
                subtitle: "days",
                gradient: habitGradient
            )
            
            StatBox(
                title: "Completed",
                value: "\(completionCount)",
                subtitle: "times",
                gradient: habitGradient
            )
        }
    }
    
    private var streakGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @ViewBuilder
    private var progressSection: some View {
        if let progress = progress, let target = habit.targetStreakDays {
            VStack(alignment: .leading, spacing: 12) {
                progressHeader(target: target)
                progressBar(progress: progress)
                progressText(progress: progress)
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
            )
        }
    }
    
    private func progressHeader(target: Int) -> some View {
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
    
    private func progressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.border.opacity(0.2))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(habitGradient)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 12)
            }
        }
        .frame(height: 12)
    }
    
    private func progressText(progress: Double) -> some View {
        Text("\(Int(progress * 100))% complete")
            .font(.system(size: 14))
            .foregroundColor(AppColors.mutedForeground)
    }
    
    private var completionButton: some View {
        Button(action: {
            HapticManager.success()
            viewModel.toggleCompletion(habitId: habit.id)
        }) {
            HStack {
                completionIcon
                Text(isCompletedToday ? "Completed Today" : "Mark as Complete")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                Spacer()
            }
            .padding(AppSpacing.lg)
            .background(completionButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var completionIcon: some View {
        Group {
            if isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(habitGradient)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(mutedGradient)
            }
        }
    }
    
    private var mutedGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.mutedForeground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var completionButtonBackground: some View {
        Group {
            if isCompletedToday {
                RoundedRectangle(cornerRadius: 16)
                    .fill(habitGradient.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(habitGradient.opacity(0.5), lineWidth: 2)
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
    
    private var editSheet: some View {
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

