//
//  CompactStatCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Compact stat card for horizontal scrollable stat display in detail views
struct CompactStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let gradient: LinearGradient
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(gradient)
                
                Text(title)
                    .font(AppTypography.labelSmallUppercase)
                    .foregroundColor(AppColors.onSurfaceVariant)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            
            Text(value)
                .font(AppTypography.numberInputLarge)
                .foregroundStyle(gradient)
            
            Text(subtitle)
                .font(AppTypography.bodyMediumEditorial)
                .foregroundColor(AppColors.onSurfaceVariant)
        }
        .frame(width: 100)
        .padding(AppSpacing.md)
        .background(AppColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardRadiusXL, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            CompactStatCard(
                title: "Current Streak",
                value: "5",
                subtitle: "days",
                gradient: HabitGradientHelper.streakGradient,
                icon: "flame.fill"
            )
            
            CompactStatCard(
                title: "Longest Streak",
                value: "12",
                subtitle: "days",
                gradient: LinearGradient.primaryGradient,
                icon: "star.fill"
            )
            
            CompactStatCard(
                title: "Completed",
                value: "24",
                subtitle: "times",
                gradient: LinearGradient.primaryGradient,
                icon: "checkmark.circle.fill"
            )
        }
        .padding(.horizontal, 20)
    }
    .padding()
    .background(AppColors.background)
}




