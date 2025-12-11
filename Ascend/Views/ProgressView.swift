//
//  ProgressView.swift
//  WorkoutTracker
//
//  Created on 2024
//

import SwiftUI

struct ProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel
    let onSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                ProgressHeader(
                    selectedView: $viewModel.selectedView,
                    onWeekSelected: { viewModel.selectedView = .week },
                    onMonthSelected: { viewModel.selectedView = .month },
                    onSettings: onSettings
                )
                
                VStack(spacing: 20) {
                    // Workout Streak Card
                    WorkoutStreakCard(
                        currentStreak: viewModel.currentStreak,
                        longestStreak: viewModel.longestStreak
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Trend Graphs (Horizontal Scrolling)
                    TrendGraphsView(viewModel: viewModel)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                    
                    // Exercise PR Tracker
                    ExercisePRTrackerView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                    
                   
                }
            }
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
    }
}

struct ProgressHeader: View {
    @Binding var selectedView: ProgressViewModel.ProgressViewType
    let onWeekSelected: () -> Void
    let onMonthSelected: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Progress")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Settings")
                
                Button(action: onWeekSelected) {
                    Text("Week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedView == .week ? AppColors.primary : AppColors.mutedForeground)
                        .frame(minWidth: 60)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedView == .week ? AppColors.secondary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onMonthSelected) {
                    Text("Month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedView == .month ? AppColors.primary : AppColors.mutedForeground)
                        .frame(minWidth: 60)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedView == .month ? AppColors.secondary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: - Workout Streak Card
struct WorkoutStreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                Text("Workout Streak")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // Current Streak
                VStack(spacing: 8) {
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Current Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("days")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(LinearGradient.cardGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                
                // Longest Streak
                VStack(spacing: 8) {
                    Text("\(longestStreak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(LinearGradient.accentGradient)
                    
                    Text("Longest Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("days")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(LinearGradient.cardGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
        }
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Exercise PR Tracker View
struct ExercisePRTrackerView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showExercisePicker = false
    @State private var searchText: String = ""
    @State private var selectedBodyPart: String? = nil
    
    private var filteredExercises: [String] {
        viewModel.getFilteredExercises(searchText: searchText, bodyPart: selectedBodyPart)
    }
    
    private var availableBodyParts: [String] {
        viewModel.getAvailableBodyParts()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                Text("PR Tracker")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(AppColors.foreground)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.mutedForeground)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            
            // Body Part Filter
            if !availableBodyParts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" option
                        Button(action: {
                            selectedBodyPart = nil
                        }) {
                            Text("All")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedBodyPart == nil ? AppColors.alabasterGrey : AppColors.foreground)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedBodyPart == nil ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                                .clipShape(Capsule())
                        }
                        
                        ForEach(availableBodyParts, id: \.self) { bodyPart in
                            Button(action: {
                                selectedBodyPart = bodyPart
                            }) {
                                Text(bodyPart)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedBodyPart == bodyPart ? AppColors.alabasterGrey : AppColors.foreground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedBodyPart == bodyPart ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.secondary))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Exercise Dropdown
            if !filteredExercises.isEmpty {
                Menu {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        Button(action: {
                            viewModel.selectedExercise = exercise
                        }) {
                            HStack {
                                Text(exercise)
                                    .foregroundColor(AppColors.textPrimary)
                                if viewModel.selectedExercise == exercise {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.selectedExercise.isEmpty ? "Select Exercise" : viewModel.selectedExercise)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.accentForeground)
                        
                        Image(systemName: "chevron.down")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.accentForeground)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            if viewModel.selectedExercise.isEmpty || filteredExercises.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    if filteredExercises.isEmpty && (!searchText.isEmpty || selectedBodyPart != nil) {
                        Text("No exercises found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("Try adjusting your search or filter")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No PRs yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Text("Complete sets to earn your first PR!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Current PR Display
                if let currentPR = viewModel.currentPR {
                    CurrentPRCard(pr: currentPR)
                }
                
                // PR History
                if viewModel.selectedExercisePRs.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PR History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                            .padding(.top, 8)
                        
                        ForEach(Array(viewModel.selectedExercisePRs.enumerated()), id: \.element.id) { index, pr in
                            if index > 0 { // Skip first one (current PR)
                                PRHistoryItemView(pr: pr, previousPR: index > 1 ? viewModel.selectedExercisePRs[index - 1] : nil)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Current PR Card
struct CurrentPRCard: View {
    let pr: PersonalRecord
    @Environment(\.colorScheme) var colorScheme
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: pr.date)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Current PR")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(pr.weight))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("lbs")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("×")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("\(pr.reps)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(LinearGradient.accentGradient)
                
                Text("reps")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Text(dateString)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(LinearGradient.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient.primaryGradient, lineWidth: 2)
        )
    }
}

// MARK: - PR History Item
struct PRHistoryItemView: View {
    let pr: PersonalRecord
    let previousPR: PersonalRecord?
    @Environment(\.colorScheme) var colorScheme
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: pr.date)
    }
    
    private var improvementText: String? {
        guard let previous = previousPR else { return nil }
        
        if pr.weight > previous.weight {
            return "+\(Int(pr.weight - previous.weight)) lbs"
        } else if pr.weight == previous.weight && pr.reps > previous.reps {
            return "+\(pr.reps - previous.reps) reps"
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(Int(pr.weight)) lbs × \(pr.reps) reps")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    if let improvement = improvementText {
                        Text(improvement)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.success.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                Text(dateString)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
        .padding(16)
        .background(LinearGradient.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

struct PRListView: View {
    let prs: [PersonalRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                Text("Personal Records")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
            }
            
            if prs.isEmpty {
                VStack(spacing: 12) {
                    Text("No PRs yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Complete sets to earn your first PR!")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(prs) { pr in
                    PRItemView(pr: pr)
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct PRItemView: View {
    let pr: PersonalRecord
    @Environment(\.colorScheme) var colorScheme
    
    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: pr.date, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pr.exercise)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.foreground)
            
            Text("\(Int(pr.weight)) lbs × \(pr.reps) reps • \(dateString)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}



struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    ProgressView(
        viewModel: ProgressViewModel(),
        onSettings: {}
    )
}
