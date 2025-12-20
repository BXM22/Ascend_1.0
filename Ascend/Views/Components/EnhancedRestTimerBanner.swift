//
//  EnhancedRestTimerBanner.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct EnhancedRestTimerBanner: View {
    let timeRemaining: Int
    let totalDuration: Int
    let onSkip: () -> Void
    let onAddTime: () -> Void
    let onSubtractTime: () -> Void
    
    @State private var breatheScale: CGFloat = 1.0
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (Double(timeRemaining) / Double(totalDuration))
    }
    
    private var motivationalMessage: String {
        if timeRemaining > totalDuration * 2 / 3 {
            return "Breathe and recover"
        } else if timeRemaining > totalDuration / 3 {
            return "Almost ready"
        } else {
            return "Get ready for next set"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Breathing animation circle
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 60, height: 60)
                    .scaleEffect(breatheScale)
                    .opacity(0.3)
                
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 50, height: 50)
                
                Text("\(timeRemaining)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    breatheScale = 1.3
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Rest Timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(motivationalMessage)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.muted)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.linear(duration: 1), value: progress)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            
            // Time controls
            HStack(spacing: 8) {
                Button(action: {
                    onSubtractTime()
                    HapticManager.impact(style: .light)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                .accessibilityLabel("Remove 30 seconds")
                
                Button(action: {
                    onAddTime()
                    HapticManager.impact(style: .light)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                .accessibilityLabel("Add 30 seconds")
            }
            
            Button(action: {
                onSkip()
                HapticManager.impact(style: .medium)
            }) {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Skip rest timer")
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
