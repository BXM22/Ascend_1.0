//
//  PRCelebrationBanner.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct PRCelebrationBanner: View {
    let exercise: String
    let prMessage: String
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    
    private var prType: String {
        if prMessage.contains("New PR") {
            return "New PR!"
        } else if prMessage.contains("Matched") {
            return "Matched PR!"
        } else if prMessage.contains("Volume") {
            return "Volume PR!"
        } else {
            return "Personal Record!"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Animated trophy
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prType)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text(exercise)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("Keep crushing it! 💪")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Button(action: {
                    onDismiss()
                    HapticManager.impact(style: .light)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .accessibilityLabel("Dismiss celebration")
            }
        }
        .padding(16)
        .background(
            LinearGradient.primaryGradient
                .opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(LinearGradient.primaryGradient, lineWidth: 2)
        )
        .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .onAppear {
            HapticManager.success()
            // Trigger confetti animation if available
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showConfetti = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prType) on \(exercise). Keep crushing it!")
    }
}
