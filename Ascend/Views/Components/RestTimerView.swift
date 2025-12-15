//
//  RestTimerView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct RestTimerView: View {
    let timeRemaining: Int
    let totalDuration: Int
    let onSkip: () -> Void
    let onComplete: () -> Void
    @State private var progressValue: Double = 0
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    private var minutes: Int {
        max(0, timeRemaining) / 60
    }
    
    private var seconds: Int {
        max(0, timeRemaining) % 60
    }
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        // Ensure timeRemaining is never negative and doesn't exceed totalDuration
        let remaining = max(0, min(Double(timeRemaining), Double(totalDuration)))
        let total = Double(totalDuration)
        return max(0, min(1.0, 1.0 - (remaining / total)))
    }
    
    private var timerColor: Color {
        if timeRemaining > 30 {
            return Color(light: AppColors.prussianBlue, dark: Color(hex: "2c2c2e"))
        } else if timeRemaining > 10 {
            return Color(light: AppColors.warning, dark: Color(hex: "d97706"))
        } else {
            return Color(light: AppColors.destructive, dark: Color(hex: "dc2626"))
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Timer")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            // Circular Timer
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppColors.secondary, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [
                                timerColor,
                                timerColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: timerColor.opacity(0.5), radius: 8)
                    .animation(AppAnimations.smooth, value: progressValue)
                    .animation(AppAnimations.smooth, value: timerColor)
                
                // Time text
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                    .contentTransition(.numericText())
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSkip()
                }) {
                    Text("Skip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onComplete()
                }) {
                    Text("Complete Rest")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.border, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Entrance animation
            withAnimation(AppAnimations.smooth) {
                scale = 1.0
                opacity = 1.0
            }
            // Animate progress
            withAnimation(AppAnimations.smooth) {
                progressValue = progress
            }
        }
        .onChange(of: timeRemaining) { oldValue, newValue in
            // Smooth progress updates
            withAnimation(AppAnimations.smooth) {
                progressValue = progress
            }
            
            // Warning haptic when time is running out
            if newValue == 10 {
                HapticManager.warning()
            } else if newValue == 0 {
                HapticManager.success()
            }
        }
    }
}

#Preview {
    RestTimerView(
        timeRemaining: 45,
        totalDuration: 90,
        onSkip: {},
        onComplete: {}
    )
    .padding()
    .background(AppColors.background)
}

