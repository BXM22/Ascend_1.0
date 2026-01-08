//
//  RecoverySectionView.swift
//  Ascend
//
//  Comprehensive recovery section for the Analytics tab
//

import SwiftUI

struct RecoverySectionView: View {
    @StateObject private var recoveryManager = RecoveryManager.shared
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var showSettings = false
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection
            
            if isExpanded {
                // Overall Status Card
                overallStatusCard
                
                // CNS Status
                cnsStatusCard
                
                // Training Recommendation
                trainingRecommendationCard
                
                // Muscle Recovery Grid
                muscleRecoverySection
                
                // Deload Alert (if needed)
                if recoveryManager.getRecoverySummary().deloadRecommended {
                    deloadAlertCard
                }
                
                // Quick Tips
                quickTipsSection
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showSettings) {
            RecoverySettingsView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "ec4899"), Color(hex: "8b5cf6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Recovery Status")
                        .font(AppTypography.heading3)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(8)
                    .background(AppColors.muted.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Overall Status Card
    
    private var overallStatusCard: some View {
        let summary = recoveryManager.getRecoverySummary()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(summary.overallStatus.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: summary.overallStatus.icon)
                        .font(.system(size: 24))
                        .foregroundColor(summary.overallStatus.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.overallStatus.rawValue)
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Text(summary.message)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Ready count badge
                VStack(spacing: 2) {
                    Text("\(summary.readyToTrain.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "22c55e"))
                    
                    Text("Ready")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            // Progress bar showing overall recovery
            let overallProgress = calculateOverallProgress(from: summary.muscleRecoveries)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Overall Recovery")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Text("\(Int(overallProgress * 100))%")
                        .font(AppTypography.captionBold)
                        .foregroundColor(summary.overallStatus.color)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.muted)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [summary.overallStatus.color.opacity(0.7), summary.overallStatus.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(overallProgress), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - CNS Status Card
    
    private var cnsStatusCard: some View {
        let summary = recoveryManager.getRecoverySummary()
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(summary.cnsLevel.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundColor(summary.cnsLevel.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("CNS Recovery")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
                
                Text(summary.cnsLevel.message)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Text(summary.cnsLevel.rawValue)
                .font(AppTypography.captionBold)
                .foregroundColor(summary.cnsLevel.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(summary.cnsLevel.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Training Recommendation Card
    
    private var trainingRecommendationCard: some View {
        let summary = recoveryManager.getRecoverySummary()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "f59e0b"))
                
                Text("Today's Recommendation")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
            }
            
            Text(summary.trainingRecommendation)
                .font(AppTypography.body)
                .foregroundColor(AppColors.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
            
            if !summary.readyToTrain.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(summary.readyToTrain, id: \.self) { muscle in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "22c55e"))
                                
                                Text(muscle)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.foreground)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "22c55e").opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "f59e0b").opacity(0.1), AppColors.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "f59e0b").opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Muscle Recovery Section
    
    private var muscleRecoverySection: some View {
        let summary = recoveryManager.getRecoverySummary()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Groups")
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.foreground)
            
            if summary.muscleRecoveries.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.mutedForeground.opacity(0.5))
                    
                    Text("No recent workouts")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Complete a workout to see recovery tracking")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(summary.muscleRecoveries) { recovery in
                        MuscleRecoveryCard(recovery: recovery)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Deload Alert Card
    
    private var deloadAlertCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "f97316").opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "f97316"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Deload Week Recommended")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
                
                Text("Cut volume by 40-50% this week")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {
                recoveryManager.markDeloadComplete()
            }) {
                Text("Done")
                    .font(AppTypography.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "f97316"))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color(hex: "f97316").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "f97316").opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Tips Section
    
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
                
                Text("Recovery Tips")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "bed.double.fill", text: "Sleep 7-9 hours for optimal recovery", color: Color(hex: "8b5cf6"))
                tipRow(icon: "drop.fill", text: "Stay hydrated throughout the day", color: Color(hex: "0ea5e9"))
                tipRow(icon: "fork.knife", text: "Protein intake: 1.6-2.2g per kg bodyweight", color: Color(hex: "22c55e"))
                tipRow(icon: "figure.walk", text: "Light cardio on rest days aids recovery", color: Color(hex: "f59e0b"))
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.mutedForeground)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallProgress(from recoveries: [MuscleRecoveryInfo]) -> Double {
        guard !recoveries.isEmpty else { return 1.0 }
        return recoveries.reduce(0.0) { $0 + $1.recoveryPercentage } / Double(recoveries.count)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        RecoverySectionView(progressViewModel: ProgressViewModel())
    }
    .background(AppColors.background)
}
