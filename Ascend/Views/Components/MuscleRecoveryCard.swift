//
//  MuscleRecoveryCard.swift
//  Ascend
//
//  Individual muscle group recovery card component
//

import SwiftUI

struct MuscleRecoveryCard: View {
    let recovery: MuscleRecoveryInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with muscle name and status
            HStack(spacing: 8) {
                // Muscle icon
                muscleIcon
                    .frame(width: 24, height: 24)
                
                Text(recovery.muscleGroup)
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.foreground)
                    .lineLimit(1)
                
                Spacer()
                
                // Status indicator
                Image(systemName: recovery.state.icon)
                    .font(.system(size: 12))
                    .foregroundColor(recovery.state.color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.muted)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [recovery.state.color.opacity(0.7), recovery.state.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(recovery.recoveryPercentage), height: 6)
                }
            }
            .frame(height: 6)
            
            // Time info
            HStack {
                Text(recovery.formattedTimeRemaining)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(recovery.state.color)
                
                Spacer()
                
                Text("\(Int(recovery.recoveryPercentage * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Intensity badge (if applicable)
            if let intensity = recovery.lastWorkoutIntensity {
                HStack(spacing: 4) {
                    Image(systemName: intensityIcon(for: intensity))
                        .font(.system(size: 8))
                    
                    Text(intensity.rawValue)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(intensityColor(for: intensity))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(intensityColor(for: intensity).opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recovery.state.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Muscle Icon
    
    @ViewBuilder
    private var muscleIcon: some View {
        let iconName = muscleIconName(for: recovery.muscleGroup)
        
        ZStack {
            Circle()
                .fill(muscleGradient.opacity(0.2))
            
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(muscleGradient)
        }
    }
    
    private func muscleIconName(for muscle: String) -> String {
        let lowercased = muscle.lowercased()
        
        if lowercased.contains("chest") {
            return "figure.arms.open"
        } else if lowercased.contains("back") || lowercased.contains("lat") {
            return "figure.strengthtraining.functional"
        } else if lowercased.contains("shoulder") {
            return "figure.boxing"
        } else if lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("arm") {
            return "figure.strengthtraining.traditional"
        } else if lowercased.contains("quad") || lowercased.contains("hamstring") || lowercased.contains("leg") {
            return "figure.run"
        } else if lowercased.contains("glute") {
            return "figure.walk"
        } else if lowercased.contains("calf") || lowercased.contains("calves") {
            return "figure.stairs"
        } else if lowercased.contains("core") || lowercased.contains("ab") {
            return "figure.core.training"
        } else if lowercased.contains("trap") {
            return "figure.mind.and.body"
        } else if lowercased.contains("forearm") {
            return "hand.raised.fill"
        } else if lowercased.contains("lower back") {
            return "figure.flexibility"
        }
        
        return "figure.mixed.cardio"
    }
    
    // MARK: - Muscle Gradient
    
    private var muscleGradient: LinearGradient {
        let lowercased = recovery.muscleGroup.lowercased()
        
        if lowercased.contains("chest") || lowercased.contains("shoulder") {
            return LinearGradient(
                colors: [Color(hex: "9333ea"), Color(hex: "ec4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("back") || lowercased.contains("lat") || lowercased.contains("trap") {
            return LinearGradient(
                colors: [Color(hex: "2563eb"), Color(hex: "06b6d4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("quad") || lowercased.contains("hamstring") || lowercased.contains("glute") || lowercased.contains("calf") || lowercased.contains("leg") {
            return LinearGradient(
                colors: [Color(hex: "16a34a"), Color(hex: "10b981")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("forearm") || lowercased.contains("arm") {
            return LinearGradient(
                colors: [Color(hex: "ea580c"), Color(hex: "f59e0b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("core") || lowercased.contains("ab") || lowercased.contains("lower back") {
            return LinearGradient(
                colors: [Color(hex: "dc2626"), Color(hex: "f43f5e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: [Color(hex: "0891b2"), Color(hex: "0ea5e9")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Card Background
    
    private var cardBackground: some View {
        Group {
            if recovery.state == .ready {
                LinearGradient(
                    colors: [Color(hex: "22c55e").opacity(0.05), AppColors.card],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if recovery.state == .exhausted {
                LinearGradient(
                    colors: [Color(hex: "ef4444").opacity(0.05), AppColors.card],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                AppColors.card
            }
        }
    }
    
    // MARK: - Intensity Helpers
    
    private func intensityIcon(for intensity: WorkoutIntensity) -> String {
        switch intensity {
        case .light: return "flame"
        case .moderate: return "flame.fill"
        case .intense: return "bolt.fill"
        case .extreme: return "bolt.horizontal.fill"
        }
    }
    
    private func intensityColor(for intensity: WorkoutIntensity) -> Color {
        switch intensity {
        case .light: return Color(hex: "22c55e")
        case .moderate: return Color(hex: "f59e0b")
        case .intense: return Color(hex: "f97316")
        case .extreme: return Color(hex: "ef4444")
        }
    }
}

// MARK: - Extended Muscle Recovery Card (for detail view)

struct MuscleRecoveryDetailCard: View {
    let recovery: MuscleRecoveryInfo
    @ObservedObject var recoveryManager: RecoveryManager
    @State private var showCustomTime = false
    @State private var customHours: Double = 48
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(recovery.state.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: recovery.state.icon)
                        .font(.system(size: 24))
                        .foregroundColor(recovery.state.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recovery.muscleGroup)
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Text(recovery.state.message)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Text("\(Int(recovery.recoveryPercentage * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(recovery.state.color)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.muted)
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [recovery.state.color.opacity(0.7), recovery.state.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(recovery.recoveryPercentage), height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("Last workout: \(recovery.hoursSinceWorked)h ago")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Text(recovery.formattedTimeRemaining)
                        .font(AppTypography.captionBold)
                        .foregroundColor(recovery.state.color)
                }
            }
            
            // Stats row
            HStack(spacing: 16) {
                statItem(title: "Required Rest", value: "\(recovery.requiredRecoveryHours)h")
                
                Divider().frame(height: 30)
                
                if let intensity = recovery.lastWorkoutIntensity {
                    statItem(title: "Intensity", value: intensity.rawValue)
                }
                
                if recovery.wasCompound {
                    Divider().frame(height: 30)
                    statItem(title: "Type", value: "Compound")
                }
            }
            
            // Custom recovery time toggle
            VStack(alignment: .leading, spacing: 8) {
                Button(action: { showCustomTime.toggle() }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                        
                        Text("Custom Recovery Time")
                            .font(AppTypography.caption)
                        
                        Spacer()
                        
                        Image(systemName: showCustomTime ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.mutedForeground)
                }
                
                if showCustomTime {
                    VStack(spacing: 8) {
                        Slider(value: $customHours, in: 24...120, step: 12)
                            .tint(AppColors.accent)
                        
                        HStack {
                            Text("\(Int(customHours)) hours")
                                .font(AppTypography.captionBold)
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            Button(action: {
                                recoveryManager.setCustomRecoveryHours(for: recovery.muscleGroup, hours: Int(customHours))
                            }) {
                                Text("Apply")
                                    .font(AppTypography.captionBold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .onAppear {
            customHours = Double(recovery.requiredRecoveryHours)
        }
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.foreground)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(AppColors.mutedForeground)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            MuscleRecoveryCard(recovery: MuscleRecoveryInfo(
                muscleGroup: "Chest",
                state: .ready,
                hoursSinceWorked: 78,
                requiredRecoveryHours: 72,
                recoveryPercentage: 1.0,
                lastWorkoutIntensity: .moderate,
                wasCompound: true
            ))
            
            MuscleRecoveryCard(recovery: MuscleRecoveryInfo(
                muscleGroup: "Back",
                state: .recovering,
                hoursSinceWorked: 56,
                requiredRecoveryHours: 72,
                recoveryPercentage: 0.78,
                lastWorkoutIntensity: .intense,
                wasCompound: true
            ))
            
            MuscleRecoveryCard(recovery: MuscleRecoveryInfo(
                muscleGroup: "Quads",
                state: .fatigued,
                hoursSinceWorked: 36,
                requiredRecoveryHours: 72,
                recoveryPercentage: 0.5,
                lastWorkoutIntensity: .extreme,
                wasCompound: true
            ))
            
            MuscleRecoveryCard(recovery: MuscleRecoveryInfo(
                muscleGroup: "Biceps",
                state: .exhausted,
                hoursSinceWorked: 12,
                requiredRecoveryHours: 48,
                recoveryPercentage: 0.25,
                lastWorkoutIntensity: .moderate,
                wasCompound: false
            ))
        }
        .padding()
    }
    .background(AppColors.background)
}
