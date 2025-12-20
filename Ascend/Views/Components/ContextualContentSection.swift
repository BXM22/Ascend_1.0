//
//  ContextualContentSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Contextual content section showing up to 3 relevant cards based on user state
struct ContextualContentSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onNavigateToProgress: (() -> Void)?
    
    @State private var showPRHistory = false
    
    private var contextualCards: [ContextualCard] {
        var cards: [ContextualCard] = []
        
        // Card 1: Next Program Workout (if active program)
        if programViewModel.activeProgram != nil {
            cards.append(.nextProgramWorkout)
        }
        
        // Card 2: Recent PR
        if let recentPR = progressViewModel.getRecentPRs().first {
            cards.append(.recentPR(recentPR))
        }
        
        // Card 3: Workout Pattern Insight
        if progressViewModel.workoutDates.count >= 4 {
            cards.append(.workoutPattern)
        }
        
        // Card 4: Recovery Suggestion (if needed)
        let daysSinceLastWorkout = progressViewModel.daysSinceLastWorkout
        if daysSinceLastWorkout >= 3 {
            cards.append(.recoverySuggestion)
        } else if daysSinceLastWorkout == 0 && !progressViewModel.isRestDay {
            // Just worked out today, suggest recovery
            cards.append(.recoverySuggestion)
        }
        
        // Card 5: Top Exercise
        if let topExercise = progressViewModel.topExercise {
            cards.append(.topExercise(topExercise))
        }
        
        // Return up to 3 cards
        return Array(cards.prefix(3))
    }
    
    var body: some View {
        if !contextualCards.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Section Title
                Text("Insights")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.foreground)
                    .padding(.horizontal, AppSpacing.lg)
                
                // Cards
                VStack(spacing: 12) {
                    ForEach(contextualCards.indices, id: \.self) { index in
                        contextualCardView(for: contextualCards[index])
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
    
    @ViewBuilder
    private func contextualCardView(for card: ContextualCard) -> some View {
        switch card {
        case .nextProgramWorkout:
            NextWorkoutDayCard(
                programViewModel: programViewModel,
                templatesViewModel: TemplatesViewModel(),
                workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager(), progressViewModel: progressViewModel),
                onStartWorkout: {}
            )
            
        case .recentPR(let pr):
            ContextualRecentPRCard(
                pr: pr,
                onTap: {
                    HapticManager.impact(style: .light)
                    showPRHistory = true
                }
            )
            .sheet(isPresented: $showPRHistory) {
                PRHistoryView(progressViewModel: progressViewModel)
            }
            
        case .workoutPattern:
            WorkoutPatternInsightCard(progressViewModel: progressViewModel)
            
        case .recoverySuggestion:
            RecoverySuggestionCard()
            
        case .topExercise(let exercise):
            ContextualTopExerciseCard(
                exerciseName: exercise,
                progressViewModel: progressViewModel,
                onTap: {
                    if let onNavigate = onNavigateToProgress {
                        HapticManager.impact(style: .light)
                        progressViewModel.selectedExercise = exercise
                        onNavigate()
                    }
                }
            )
        }
    }
}

/// Types of contextual cards that can be shown
private enum ContextualCard: Identifiable {
    case nextProgramWorkout
    case recentPR(PersonalRecord)
    case workoutPattern
    case recoverySuggestion
    case topExercise(String)
    
    var id: String {
        switch self {
        case .nextProgramWorkout: return "nextWorkout"
        case .recentPR: return "recentPR"
        case .workoutPattern: return "pattern"
        case .recoverySuggestion: return "recovery"
        case .topExercise: return "topExercise"
        }
    }
}

/// Compact recent PR card for contextual content
struct ContextualRecentPRCard: View {
    let pr: PersonalRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Trophy Icon
                ZStack {
                    Circle()
                        .fill(AppColors.warning.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // PR Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("New PR!")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.warning)
                    
                    Text(pr.exercise)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                    
                    Text("\(Int(pr.weight)) lbs × \(pr.reps) reps")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("New PR: \(pr.exercise), \(Int(pr.weight)) pounds, \(pr.reps) reps")
    }
}

/// Compact top exercise card for contextual content
struct ContextualTopExerciseCard: View {
    let exerciseName: String
    let progressViewModel: ProgressViewModel
    let onTap: () -> Void
    
    private var exerciseStats: (totalSets: Int, totalVolume: Double)? {
        let history = WorkoutHistoryManager.shared
        var totalSets = 0
        var totalVolume = 0.0
        
        for workout in history.completedWorkouts {
            for exercise in workout.exercises where exercise.name == exerciseName {
                for set in exercise.sets {
                    totalSets += 1
                    totalVolume += set.weight * Double(set.reps)
                }
            }
        }
        
        guard totalSets > 0 else { return nil }
        
        return (totalSets, totalVolume)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Dumbbell Icon
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Exercise")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.accent)
                    
                    Text(exerciseName)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.foreground)
                        .lineLimit(1)
                    
                    if let stats = exerciseStats {
                        Text("\(stats.totalSets) sets • \(Int(stats.totalVolume)) lbs total")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Top exercise: \(exerciseName)")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        ContextualContentSection(
            progressViewModel: ProgressViewModel(),
            programViewModel: WorkoutProgramViewModel(),
            onNavigateToProgress: nil
        )
    }
    .background(AppColors.background)
}
