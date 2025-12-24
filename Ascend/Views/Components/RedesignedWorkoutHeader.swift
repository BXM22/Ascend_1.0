//
//  RedesignedWorkoutHeader.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct RedesignedWorkoutHeader: View {
    let workoutName: String
    let totalVolume: Int
    let elapsedTime: TimeInterval
    let timerPaused: Bool
    let autoAdvanceEnabled: Bool
    let completedExercises: Int
    let totalExercises: Int
    let onTogglePause: () -> Void
    let onFinish: () -> Void
    let onSettings: () -> Void
    let onHelp: () -> Void
    let onCancel: () -> Void
    let isVerticalLayout: Bool
    let onToggleLayout: () -> Void
    @Binding var autoAdvanceToggle: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row: Name + overflow menu
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 12) {
                        // Volume badge
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 11))
                            Text(formatVolume(totalVolume))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppColors.mutedForeground)
                        
                        // Progress badge
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 11))
                            Text("\(completedExercises)/\(totalExercises)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppColors.mutedForeground)
                    }
                }
                
                Spacer()
                
                // Layout toggle
                Button(action: {
                    onToggleLayout()
                    HapticManager.selection()
                }) {
                    Image(systemName: isVerticalLayout ? "rectangle.grid.1x2" : "list.bullet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(isVerticalLayout ? "Show horizontal exercise view" : "Show vertical exercise list")
                .accessibilityHint("Switches how your workout exercises are displayed")
                
                // Consolidated menu
                Menu {
                    Section {
                        Button(action: { 
                            autoAdvanceToggle.toggle()
                        }) {
                            Label(
                                "Auto-advance",
                                systemImage: autoAdvanceEnabled ? "checkmark.circle.fill" : "circle"
                            )
                        }
                        
                        Button(action: onSettings) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button(action: onHelp) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: onCancel) {
                            Label("Cancel Workout", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AppColors.foreground.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Workout options")
                .accessibilityHint("Opens menu with workout settings and actions")
            }
            
            // Bottom row: Timer + action buttons
            HStack(spacing: 12) {
                // Elapsed time
                HStack(spacing: 6) {
                    Image(systemName: timerPaused ? "pause.circle.fill" : "clock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(timerPaused ? AnyShapeStyle(Color.orange) : AnyShapeStyle(LinearGradient.primaryGradient))
                    
                    Text(formatElapsedTime(elapsedTime))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(timerPaused ? AnyShapeStyle(Color.orange) : AnyShapeStyle(LinearGradient.primaryGradient))
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                // Pause/Resume button
                Button(action: {
                    onTogglePause()
                    HapticManager.impact(style: .medium)
                }) {
                    Image(systemName: timerPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                .accessibilityLabel(timerPaused ? "Resume workout" : "Pause workout")
                
                // Finish button
                Button(action: {
                    onFinish()
                    HapticManager.impact(style: .medium)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Finish")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LinearGradient.primaryGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: AppColors.foreground.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .accessibilityLabel("Finish workout")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", Double(volume) / 1000.0)
        }
        return "\(volume) lbs"
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
