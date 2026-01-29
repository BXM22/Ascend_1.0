//
//  CompactStreakBadge.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Compact streak badge component showing flame icon and streak count
struct CompactStreakBadge: View {
    let streak: Int
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(gradient)
            
            Text("\(streak)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("days")
                .font(.system(size: 10))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(gradient.opacity(0.15))
        )
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: 12) {
        CompactStreakBadge(
            streak: 5,
            gradient: HabitGradientHelper.streakGradient
        )
        
        CompactStreakBadge(
            streak: 12,
            gradient: LinearGradient.primaryGradient
        )
    }
    .padding()
    .background(AppColors.background)
}

