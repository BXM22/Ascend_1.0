//
//  InsightsGrid.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// 2×2 grid of key workout insights
struct InsightsGrid: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private var weeklyVolume: Double {
        progressViewModel.weeklyVolume
    }
    
    private var weeklyWorkoutCount: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        
        return progressViewModel.workoutDates.filter { $0 >= weekStart }.count
    }
    
    private var averageWorkoutDuration: Int {
        let manager = WorkoutHistoryManager.shared
        let recentWorkouts = Array(manager.completedWorkouts.prefix(10))
        guard !recentWorkouts.isEmpty else { return 0 }
        
        // Estimate duration based on exercise and set count
        // Estimate: ~5 minutes per exercise + 2 minutes per set
        let totalEstimatedMinutes = recentWorkouts.reduce(0.0) { sum, workout in
            let exerciseMinutes = Double(workout.exercises.count) * 5.0
            let setMinutes = Double(workout.exercises.reduce(0) { $0 + $1.sets.count }) * 2.0
            let estimatedMinutes = exerciseMinutes + setMinutes
            return sum + estimatedMinutes
        }
        return Int(totalEstimatedMinutes / Double(recentWorkouts.count))
    }
    
    private var weeklyFrequency: Double {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last 4 weeks of workout dates
        guard let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now) else { return 0.0 }
        let recentWorkouts = progressViewModel.workoutDates.filter { $0 >= fourWeeksAgo }
        
        // Calculate average workouts per week
        return Double(recentWorkouts.count) / 4.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 2×2 Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Total Volume
                CompactInsightCard(
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    value: String(format: "%.0f", weeklyVolume),
                    unit: "lbs",
                    label: "Volume"
                )
                
                // Workouts Completed
                CompactInsightCard(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    value: "\(weeklyWorkoutCount)",
                    unit: "workouts",
                    label: "Completed"
                )
                
                // Average Duration
                CompactInsightCard(
                    icon: "clock.fill",
                    iconColor: .orange,
                    value: "\(averageWorkoutDuration)",
                    unit: "min",
                    label: "Avg Duration"
                )
                
                // Weekly Frequency
                CompactInsightCard(
                    icon: "calendar.badge.clock",
                    iconColor: .purple,
                    value: String(format: "%.1f", weeklyFrequency),
                    unit: "x/week",
                    label: "Frequency"
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

/// Compact card for individual insights in the 2×2 grid
struct CompactInsightCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Spacer()
            
            // Value + Unit
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        InsightsGrid(progressViewModel: ProgressViewModel())
    }
    .background(AppColors.background)
}
