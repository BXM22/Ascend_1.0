//
//  RedesignedDashboardHeader.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Streamlined dashboard header with greeting, streak, and active program/rest day status
struct RedesignedDashboardHeader: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
    
    private var currentStreak: Int {
        progressViewModel.currentStreak
    }
    
    private var statusMessage: String {
        if progressViewModel.isRestDay {
            return "Rest Day"
        } else if let activeProgram = programViewModel.activeProgram,
                  let program = programViewModel.programs.first(where: { $0.id == activeProgram.programId }) {
            return "Following \(program.name)"
        } else if let lastWorkoutDate = progressViewModel.workoutDates.max(),
                  Calendar.current.isDateInToday(lastWorkoutDate) {
            return "Workout Complete"
        } else {
            return "Ready to Train"
        }
    }
    
    private var statusColor: Color {
        if progressViewModel.isRestDay {
            return AppColors.warning
        } else if programViewModel.activeProgram != nil {
            return AppColors.accent
        } else if let lastWorkoutDate = progressViewModel.workoutDates.max(),
                  Calendar.current.isDateInToday(lastWorkoutDate) {
            return AppColors.success
        } else {
            return AppColors.secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Greeting + Streak
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(greeting)
                    .font(AppTypography.largeTitleBold)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                if currentStreak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(currentStreak)")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    .accessibilityLabel("\(currentStreak) day workout streak")
                }
            }
            
            // Status Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(statusMessage)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, 60) // Account for top buttons
        .padding(.bottom, AppSpacing.md)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        RedesignedDashboardHeader(
            progressViewModel: ProgressViewModel(),
            programViewModel: WorkoutProgramViewModel()
        )
        Spacer()
    }
    .background(AppColors.background)
}
