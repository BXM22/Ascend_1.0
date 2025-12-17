//
//  PersonalizedRecommendationsCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct PersonalizedRecommendationsCard: View {
    @ObservedObject private var personalizationManager = PersonalizationManager.shared
    
    private var recommendation: PersonalizedRecommendation? {
        personalizationManager.getPersonalizedRecommendations()
    }
    
    private var workoutTypeGradient: LinearGradient {
        guard let rec = recommendation else {
            return LinearGradient.primaryGradient
        }
        
        switch rec.workoutType {
        case "Push":
            return LinearGradient.chestGradient
        case "Pull":
            return LinearGradient.backGradient
        case "Legs":
            return LinearGradient.legsGradient
        default:
            return LinearGradient.primaryGradient
        }
    }
    
    var body: some View {
        if let rec = recommendation {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(workoutTypeGradient.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(workoutTypeGradient)
                    }
                    
                    Text("Personalized Recommendations")
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                }
                
                // Recommended Workout Type
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Try:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text(rec.workoutType)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(workoutTypeGradient)
                    }
                    
                    Text(rec.reasoning)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                // Most Frequent Exercises
                if !rec.mostFrequentExercises.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Top Exercises")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.mutedForeground)
                            .textCase(.uppercase)
                        
                        ForEach(Array(rec.mostFrequentExercises.prefix(3).enumerated()), id: \.offset) { index, exercise in
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                    .frame(width: 20)
                                
                                Text(exercise.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
                                Text("\(exercise.count)x")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Underworked Muscle Groups
                if !rec.underworkedMuscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Underworked")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.mutedForeground)
                            .textCase(.uppercase)
                            .padding(.top, 8)
                        
                        ForEach(Array(rec.underworkedMuscleGroups.prefix(2).enumerated()), id: \.offset) { _, group in
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.warning)
                                
                                Text(group.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
                                Text("\(group.daysSince) days ago")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
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


