//
//  WorkoutPatternInsightCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct WorkoutPatternInsightCard: View {
    @ObservedObject private var personalizationManager = PersonalizationManager.shared
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private var workoutPattern: WorkoutDayPattern? {
        personalizationManager.analyzeWorkoutDays()
    }
    
    private var frequencyText: String {
        guard let pattern = workoutPattern else { return "" }
        let frequency = pattern.frequencyPerWeek
        if frequency < 2 {
            return "1-2 times per week"
        } else if frequency < 3 {
            return "2-3 times per week"
        } else if frequency < 4 {
            return "3-4 times per week"
        } else if frequency < 5 {
            return "4-5 times per week"
        } else {
            return "5+ times per week"
        }
    }
    
    var body: some View {
        if let pattern = workoutPattern {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text("Workout Pattern")
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(pattern.formattedInsight)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text(frequencyText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
            .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}







