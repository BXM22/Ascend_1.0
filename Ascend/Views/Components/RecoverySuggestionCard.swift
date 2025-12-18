//
//  RecoverySuggestionCard.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct RecoverySuggestionCard: View {
    @ObservedObject private var personalizationManager = PersonalizationManager.shared
    
    private var recoverySuggestion: RecoverySuggestion? {
        personalizationManager.calculateRecoveryTime()
    }
    
    private var statusColor: Color {
        guard let suggestion = recoverySuggestion else { return AppColors.mutedForeground }
        switch suggestion.status {
        case .ready:
            return AppColors.success
        case .needsRest:
            return AppColors.warning
        case .optimal:
            return AppColors.accent
        }
    }
    
    private var statusIcon: String {
        guard let suggestion = recoverySuggestion else { return "questionmark.circle" }
        switch suggestion.status {
        case .ready:
            return "checkmark.circle.fill"
        case .needsRest:
            return "moon.zzz.fill"
        case .optimal:
            return "clock.fill"
        }
    }
    
    var body: some View {
        if let suggestion = recoverySuggestion, suggestion.daysSinceLastWorkout >= 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(statusColor)
                    }
                    
                    Text("Recovery Status")
                        .font(AppTypography.heading4)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(suggestion.message)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                    }
                    
                    if suggestion.daysSinceLastWorkout > 0 {
                        Text("You worked out \(suggestion.daysSinceLastWorkout) day\(suggestion.daysSinceLastWorkout > 1 ? "s" : "") ago")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    
                    if !suggestion.muscleGroupsNeedingRecovery.isEmpty {
                        Text("Muscle groups needing recovery: \(suggestion.muscleGroupsNeedingRecovery.prefix(3).joined(separator: ", "))")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.top, 4)
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







