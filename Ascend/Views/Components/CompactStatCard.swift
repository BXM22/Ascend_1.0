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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(gradient)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(gradient)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(width: 100)
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.card)
        )
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

