//
//  ProgressBarView.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Reusable progress bar component following DRY principle
struct ProgressBarView: View {
    let progress: Double // 0.0 to 1.0
    let gradient: LinearGradient
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(
        progress: Double,
        gradient: LinearGradient,
        height: CGFloat = 12,
        cornerRadius: CGFloat = 8
    ) {
        self.progress = progress
        self.gradient = gradient
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.border.opacity(0.2))
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ProgressBarView(
            progress: 0.65,
            gradient: HabitGradientHelper.streakGradient
        )
        .frame(width: 200)
        
        ProgressBarView(
            progress: 0.3,
            gradient: LinearGradient.primaryGradient,
            height: 6,
            cornerRadius: 4
        )
        .frame(width: 80)
    }
    .padding()
}

