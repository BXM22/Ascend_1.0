//
//  WorkoutCompletionModal.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct WorkoutCompletionStats {
    let duration: Int // seconds
    let exerciseCount: Int
    let totalSets: Int
    let totalVolume: Int // lbs
    let prsAchieved: [String] // Exercise names with PRs
}

struct WorkoutCompletionModal: View {
    let stats: WorkoutCompletionStats
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showStats: Bool = false
    @State private var confettiScale: CGFloat = 0
    @State private var confettiRotation: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private var formattedDuration: String {
        let hours = stats.duration / 3600
        let minutes = (stats.duration % 3600) / 60
        let seconds = stats.duration % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private var formattedVolume: String {
        if stats.totalVolume >= 1000 {
            return String(format: "%.1fk", Double(stats.totalVolume) / 1000.0)
        } else {
            return "\(stats.totalVolume)"
        }
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap - require explicit button
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Celebration header
                VStack(spacing: 16) {
                    // Confetti/celebration icon
                    ZStack {
                        // Pulsing background circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.accent.opacity(0.3),
                                        AppColors.accent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseScale)
                        
                        // Sparkle effects
                        ForEach(0..<8) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accent)
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 50,
                                    y: sin(Double(index) * .pi / 4) * 50
                                )
                                .opacity(sparkleOpacity)
                        }
                        
                        // Main checkmark icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.accent)
                            .scaleEffect(confettiScale)
                            .rotationEffect(.degrees(confettiRotation))
                    }
                    
                    Text("Workout Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Great job today! 💪")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Stats section
                if showStats {
                    VStack(spacing: 20) {
                        // Duration
                        StatRow(
                            icon: "clock.fill",
                            title: "Duration",
                            value: formattedDuration,
                            color: AppColors.accent
                        )
                        
                        // Exercises
                        StatRow(
                            icon: "figure.strengthtraining.traditional",
                            title: "Exercises",
                            value: "\(stats.exerciseCount)",
                            color: AppColors.accent
                        )
                        
                        // Sets
                        StatRow(
                            icon: "list.bullet",
                            title: "Total Sets",
                            value: "\(stats.totalSets)",
                            color: AppColors.accent
                        )
                        
                        // Volume
                        StatRow(
                            icon: "chart.bar.fill",
                            title: "Total Volume",
                            value: "\(formattedVolume) lbs",
                            color: AppColors.accent
                        )
                        
                        // PRs
                        if !stats.prsAchieved.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.warning)
                                    
                                    Text("Personal Records")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.foreground)
                                }
                                
                                ForEach(stats.prsAchieved, id: \.self) { exercise in
                                    HStack {
                                        Text("•")
                                            .foregroundColor(AppColors.warning)
                                        Text(exercise)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.smallCornerRadius))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                // Done button
                Button(action: {
                    HapticManager.success()
                    onDismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.buttonCornerRadius))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: 340)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 10)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Entrance animation
            withAnimation(AppAnimations.smooth) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Confetti/checkmark animation with rotation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                confettiScale = 1.0
                confettiRotation = 360
            }
            
            // Sparkle animation
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                sparkleOpacity = 1.0
            }
            
            // Pulse animation
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatCount(3, autoreverses: true)
                    .delay(0.2)
            ) {
                pulseScale = 1.15
            }
            
            // Show stats with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(AppAnimations.smooth) {
                    showStats = true
                }
            }
            
            // Celebration haptic feedback sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                HapticManager.success()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                HapticManager.impact(style: .light)
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.smallCornerRadius))
    }
}

#Preview {
    WorkoutCompletionModal(
        stats: WorkoutCompletionStats(
            duration: 3600,
            exerciseCount: 5,
            totalSets: 15,
            totalVolume: 12500,
            prsAchieved: ["Bench Press", "Squat"]
        ),
        onDismiss: {}
    )
}

