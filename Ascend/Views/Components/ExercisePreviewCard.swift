//
//  ExercisePreviewCard.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct ExercisePreviewCard: View {
    let exercise: String
    let currentPR: PersonalRecord?
    let prCount: Int
    let lastPerformed: Date?
    let trend: TrendIndicator
    
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: exercise)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Muscle group icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundStyle(gradient)
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                
                if let pr = currentPR {
                    HStack(spacing: 6) {
                        Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(gradient)
                        
                        trend.icon
                            .font(.system(size: 12))
                            .foregroundColor(trend.color)
                    }
                }
                
                if let date = lastPerformed {
                    Text(date, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            // PR count badge
            VStack(spacing: 2) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(gradient)
                
                Text("\(prCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise), current PR: \(currentPR.map { "\(Int($0.weight)) pounds for \($0.reps) reps" } ?? "No PR yet")")
        .accessibilityHint("Double tap to view detailed PR history and charts")
        .accessibilityAddTraits(.isButton)
    }
}
