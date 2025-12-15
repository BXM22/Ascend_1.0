//
//  GradientBorderedCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

/// A reusable card component with gradient border
struct GradientBorderedCard<Content: View>: View {
    let gradient: LinearGradient
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let content: Content
    
    init(
        gradient: LinearGradient,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 3,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.content = content()
    }
    
    var body: some View {
        content
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(gradient, lineWidth: borderWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.border)
                    .offset(x: 4, y: 4)
            )
            .shadow(color: AppColors.foreground.opacity(0.1), radius: 8, x: 0, y: 4)
            .shadow(color: AppColors.foreground.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

/// Version with muscle group detection
struct CategoryBorderedCard<Content: View>: View {
    let muscleGroup: String
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let content: Content
    
    init(
        muscleGroup: String,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 3,
        @ViewBuilder content: () -> Content
    ) {
        self.muscleGroup = muscleGroup
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.content = content()
    }
    
    var body: some View {
        GradientBorderedCard(
            gradient: AppColors.categoryGradient(for: muscleGroup),
            cornerRadius: cornerRadius,
            borderWidth: borderWidth
        ) {
            content
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        GradientBorderedCard(gradient: LinearGradient.chestGradient) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Chest Exercise")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.foreground)
                
                Text("3 sets × 12 reps")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding()
        }
        .padding(.horizontal)
        
        CategoryBorderedCard(muscleGroup: "Back") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Back Exercise")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.foreground)
                
                Text("4 sets × 10 reps")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding()
        }
        .padding(.horizontal)
        
        CategoryBorderedCard(muscleGroup: "Legs") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Leg Exercise")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.foreground)
                
                Text("5 sets × 8 reps")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    .background(AppColors.background)
}



