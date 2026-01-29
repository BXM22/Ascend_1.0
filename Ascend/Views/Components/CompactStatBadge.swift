//
//  CompactStatBadge.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Compact stat badge component for displaying statistics with icon, value, and label
struct CompactStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(gradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.card)
        )
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 8) {
        CompactStatBadge(
            icon: "list.bullet",
            value: "5",
            label: "Total",
            gradient: LinearGradient.primaryGradient
        )
        
        CompactStatBadge(
            icon: "checkmark.circle.fill",
            value: "3",
            label: "Today",
            gradient: HabitGradientHelper.streakGradient
        )
        
        CompactStatBadge(
            icon: "chart.bar.fill",
            value: "60%",
            label: "Rate",
            gradient: LinearGradient.primaryGradient
        )
    }
    .padding()
    .background(AppColors.background)
}

