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
    let isExpanded: Bool
    let onTap: (() -> Void)?
    let onToggleExpand: () -> Void
    let onEdit: ((Habit) -> Void)?
    let onDelete: ((Habit) -> Void)?
    
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
    
    private var shouldShowProgress: Bool {
        guard let target = habit.targetStreakDays,
              currentStreak > 0 else {
            return false
        }
        return true
    }
    
    private var shouldShowCompletionCount: Bool {
        return isExpanded || completionCount >= 3
    }
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: isExpanded ? 12 : 8) {
                // Compact Header
                compactHeader
                
                // Expanded Content
                if isExpanded {
                    Divider()
                        .background(AppColors.border.opacity(0.3))
                    
                    expandedContent
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Swipe right to complete/incomplete
            Button {
                HapticManager.success()
                viewModel.toggleCompletion(habitId: habit.id)
            } label: {
                Label(
                    isCompletedToday ? "Undo" : "Complete",
                    systemImage: isCompletedToday ? "xmark.circle" : "checkmark.circle.fill"
                )
            }
            .tint(isCompletedToday ? AnyShapeStyle(AppColors.mutedForeground) : AnyShapeStyle(HabitGradientHelper.streakGradient))
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            // Swipe left for options
            if let onEdit = onEdit {
                Button {
                    onEdit(habit)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(AppColors.accent)
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete(habit)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            Button {
                onTap?()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }
            
            if let onEdit = onEdit {
                Button {
                    onEdit(habit)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            Button {
                viewModel.toggleCompletion(habitId: habit.id)
            } label: {
                Label(
                    isCompletedToday ? "Mark Incomplete" : "Mark Complete",
                    systemImage: isCompletedToday ? "xmark.circle" : "checkmark.circle.fill"
                )
            }
            
            if let onDelete = onDelete {
                Divider()
                
                Button(role: .destructive) {
                    onDelete(habit)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onLongPressGesture {
            HapticManager.impact(style: .medium)
        }
    }
    
    // MARK: - Compact Header
    private var compactHeader: some View {
        HStack(spacing: 12) {
            // Icon (smaller in compact mode)
            ZStack {
                Circle()
                    .fill(habitGradient.opacity(0.2))
                    .frame(width: isExpanded ? 48 : 40, height: isExpanded ? 48 : 40)
                
                Image(systemName: habit.icon)
                    .font(.system(size: isExpanded ? 20 : 18, weight: .semibold))
                    .foregroundStyle(habitGradient)
            }
            
            // Name and duration (single line in compact mode)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: isExpanded ? 18 : 16, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                
                if isExpanded {
                    Text("\(habit.completionDuration) min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                } else {
                    Text("\(habit.completionDuration) min")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            // Streak badge (compact mode)
            if !isExpanded {
                CompactStreakBadge(
                    streak: currentStreak,
                    gradient: HabitGradientHelper.streakGradient
                )
            }
            
            // Quick completion button
            Button(action: {
                HapticManager.success()
                viewModel.toggleCompletion(habitId: habit.id)
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isCompletedToday
                            ? habitGradient
                            : HabitGradientHelper.mutedGradient
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedToday ? "Mark habit as incomplete" : "Mark habit as complete")
            
            // Expand/collapse indicator
            Button(action: {
                HapticManager.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onToggleExpand()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isExpanded ? "Collapse habit details" : "Expand habit details")
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Duration (if not shown in header)
            HStack {
                Text("Duration: \(habit.completionDuration) minutes")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
            }
            
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
                
                // Completions (if should show)
                if shouldShowCompletionCount {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(completionCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        Text("completed")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
                
                Spacer()
                
                // Progress bar or Forever indicator
                if shouldShowProgress, let progress = progress, let target = habit.targetStreakDays {
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
                    // Forever badge (subtle)
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("Forever")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(AppColors.secondary)
                    )
                }
            }
        }
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
            isExpanded: false,
            onTap: {},
            onToggleExpand: {},
            onEdit: nil,
            onDelete: nil
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
            isExpanded: true,
            onTap: {},
            onToggleExpand: {},
            onEdit: nil,
            onDelete: nil
        )
    }
    .padding()
    .background(AppColors.background)
}


