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
    let onAddTime: (() -> Void)?
    let onSubtractTime: (() -> Void)?
    @State private var progressValue: Double = 0
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    @State private var breathingScale: CGFloat = 1.0
    
    init(
        timeRemaining: Int,
        totalDuration: Int,
        onSkip: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onAddTime: (() -> Void)? = nil,
        onSubtractTime: (() -> Void)? = nil
    ) {
        self.timeRemaining = timeRemaining
        self.totalDuration = totalDuration
        self.onSkip = onSkip
        self.onComplete = onComplete
        self.onAddTime = onAddTime
        self.onSubtractTime = onSubtractTime
    }
    
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
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.foreground)
            
            // Enhanced Circular Timer with Breathing Animation
            ZStack {
                // Breathing circle background (pulsing)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                timerColor.opacity(0.15),
                                timerColor.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathingScale)
                    .blur(radius: 8)
                
                // Background ring
                Circle()
                    .stroke(AppColors.secondary.opacity(0.3), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        AngularGradient(
                            colors: [
                                timerColor,
                                timerColor.opacity(0.8),
                                timerColor
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: timerColor.opacity(0.6), radius: 12, x: 0, y: 0)
                    .animation(AppAnimations.smooth, value: progressValue)
                    .animation(AppAnimations.smooth, value: timerColor)
                
                // Inner breathing guidance circle
                Circle()
                    .fill(timerColor.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(breathingScale)
                    .blur(radius: 2)
                
                // Time text
                VStack(spacing: 4) {
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                        .contentTransition(.numericText())
                    
                    Text("remaining")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .frame(height: 200)
            
            // Quick time adjustment buttons (if available)
            if onAddTime != nil || onSubtractTime != nil {
                HStack(spacing: 12) {
                    if let onSubtract = onSubtractTime {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onSubtract()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                Text("-30s")
                                    .font(AppTypography.bodyMedium)
                            }
                            .foregroundColor(AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.secondary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    if let onAdd = onAddTime {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onAdd()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("+30s")
                                    .font(AppTypography.bodyMedium)
                            }
                            .foregroundColor(AppColors.foreground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.secondary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            
            // Enhanced Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSkip()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                        Text("Skip")
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundColor(AppColors.foreground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Done")
                            .font(AppTypography.bodyBold)
                    }
                    .foregroundColor(AppColors.alabasterGrey)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                    .applyElevation(.medium)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(AppSpacing.lg)
        .glassmorphic()
        .scaleEffect(scale)
        .opacity(opacity)
        .applyElevation(.floating)
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
            // Start breathing animation (4-second cycle: 2s in, 2s out)
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathingScale = 1.2
            }
        }
        .onChange(of: timeRemaining) { oldValue, newValue in
            // Smooth progress updates
            withAnimation(AppAnimations.smooth) {
                progressValue = progress
            }
            
            // Haptic feedback for timer milestones (already handled in WorkoutViewModel, but keep for UI feedback)
            if newValue == 30 {
                HapticManager.warning()
            } else if newValue == 15 {
                HapticManager.impact(style: .light)
            } else if newValue == 10 {
                HapticManager.warning()
            } else if newValue == 5 {
                HapticManager.impact(style: .medium)
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
        onComplete: {},
        onAddTime: {},
        onSubtractTime: {}
    )
    .padding()
    .background(AppColors.background)
}

