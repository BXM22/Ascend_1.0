//
//  RestTimerView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct RestTimerView: View {
    let timeRemaining: Int
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    private var minutes: Int {
        timeRemaining / 60
    }
    
    private var seconds: Int {
        timeRemaining % 60
    }
    
    private var progress: Double {
        let total = 90.0
        return 1.0 - (Double(timeRemaining) / total)
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
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(light: AppColors.prussianBlue, dark: Color(hex: "2c2c2e")),
                                Color(light: AppColors.duskBlue, dark: Color(hex: "3a3a3c"))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(light: AppColors.prussianBlue, dark: Color(hex: "000000")).opacity(0.5), radius: 8)
                
                // Time text
                Text(String(format: "%02d:%02d", minutes, seconds))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onSkip) {
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
                
                Button(action: onComplete) {
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
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    RestTimerView(
        timeRemaining: 45,
        onSkip: {},
        onComplete: {}
    )
    .padding()
    .background(AppColors.background)
}

