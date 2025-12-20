//
//  RedesignedWorkoutCompletionModal.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct RedesignedWorkoutCompletionModal: View {
    let workoutName: String
    let duration: TimeInterval
    let exerciseCount: Int
    let totalVolume: Int
    let prCount: Int
    let onDismiss: () -> Void
    let onSaveAndExit: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero section
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                Text("Workout Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(workoutName)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                CompletionStatCard(
                    icon: "clock.fill",
                    label: "Duration",
                    value: formatDuration(duration)
                )
                
                CompletionStatCard(
                    icon: "flame.fill",
                    label: "Exercises",
                    value: "\(exerciseCount)"
                )
                
                CompletionStatCard(
                    icon: "scalemass.fill",
                    label: "Total Volume",
                    value: formatVolume(totalVolume)
                )
                
                CompletionStatCard(
                    icon: "star.fill",
                    label: "PRs Set",
                    value: "\(prCount)"
                )
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    onSaveAndExit()
                    HapticManager.success()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Save & Exit")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Save workout and exit")
                
                Button(action: {
                    onDismiss()
                    HapticManager.impact(style: .light)
                }) {
                    Text("Continue Tracking")
                        .font(.system(size: 15))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                .accessibilityLabel("Continue tracking workout")
            }
        }
        .padding(24)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            HapticManager.success()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        }
        return "\(volume)"
    }
}

struct CompletionStatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
