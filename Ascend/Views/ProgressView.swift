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
                    // Stat Cards Row
                    HStack(spacing: 12) {
                        StreakStatCard(
                            currentStreak: viewModel.currentStreak,
                            longestStreak: viewModel.longestStreak
                        )
                        
                        WorkoutCountStatCard(viewModel: viewModel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Charts Header
                    HStack {
                        Text("Charts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Trend Graphs (Horizontal Scrolling)
                    TrendGraphsView(viewModel: viewModel)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                    
                    // Exercise PR Tracker
                    ExercisePRTrackerView(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                   
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
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            HStack(spacing: 12) {
                HelpButton(pageType: .progress)
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Settings")
                
                Menu {
                    Button(action: {
                        HapticManager.impact(style: .light)
                        onWeekSelected()
                    }) {
                        HStack {
                            Text("Week")
                            if selectedView == .week {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        HapticManager.impact(style: .light)
                        onMonthSelected()
                    }) {
                        HStack {
                            Text("Month")
                            if selectedView == .month {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedView == .week ? "Week" : "Month")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.primary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    .frame(minWidth: 80)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.border)
                .offset(x: 4, y: 4)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Exercise PR Tracker View
struct ExercisePRTrackerView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showExercisePicker = false
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var selectedBodyPart: String? = nil
    @State private var debounceTask: Task<Void, Never>?
    
    private var filteredExercises: [String] {
        viewModel.getFilteredExercises(searchText: debouncedSearchText, bodyPart: selectedBodyPart)
    }
    
    private var availableBodyParts: [String] {
        viewModel.getAvailableBodyParts()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.armsGradientEnd.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.armsGradient)
                }
                
                Text("PR Tracker")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
            }
            
            // Exercise Picker Button - Most Prominent
            Button(action: {
                showExercisePicker = true
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exercise")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.accentForeground.opacity(0.8))
                        
                        Text(viewModel.selectedExercise.isEmpty ? "Select Exercise" : viewModel.selectedExercise)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentForeground)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accentForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            
            if viewModel.selectedExercise.isEmpty || filteredExercises.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    if filteredExercises.isEmpty && (!debouncedSearchText.isEmpty || selectedBodyPart != nil) {
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(
                viewModel: viewModel,
                searchText: $searchText,
                debouncedSearchText: $debouncedSearchText,
                selectedBodyPart: $selectedBodyPart,
                filteredExercises: filteredExercises,
                availableBodyParts: availableBodyParts,
                onSelect: { exercise in
                    viewModel.selectedExercise = exercise
                    showExercisePicker = false
                    searchText = ""
                    debouncedSearchText = ""
                    selectedBodyPart = nil
                }
            )
        }
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
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: pr.exercise)
    }
    
    var body: some View {
        GradientBorderedCard(gradient: gradient) {
            VStack(spacing: 16) {
                Text("Current PR")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.mutedForeground)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(pr.weight))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(gradient)
                    
                    Text("lbs")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("×")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("\(pr.reps)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(gradient)
                    
                    Text("reps")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Text(dateString)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.mutedForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
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
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Modern Stat Cards

struct StreakStatCard: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.armsGradientEnd.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.armsGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(LinearGradient.armsGradient)
                
                Text("Day Streak")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                if longestStreak > 0 {
                    Text("Best: \(longestStreak)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.armsGradient.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct WorkoutCountStatCard: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var weeklyWorkouts: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return viewModel.workoutDates.filter { $0 >= weekAgo }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.backGradientEnd.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.backGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(weeklyWorkouts)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(LinearGradient.backGradient)
                
                Text("This Week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("Total: \(viewModel.workoutCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.backGradient.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Exercise Picker Sheet
struct ExercisePickerSheet: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var searchText: String
    @Binding var debouncedSearchText: String
    @Binding var selectedBodyPart: String?
    @State private var debounceTask: Task<Void, Never>?
    let filteredExercises: [String]
    let availableBodyParts: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.mutedForeground)
                    
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(AppColors.foreground)
                        .onChange(of: searchText) { _, newValue in
                            debounceTask?.cancel()
                            debounceTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                if !Task.isCancelled {
                                    debouncedSearchText = newValue
                                }
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            debouncedSearchText = ""
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
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1))
                .padding(16)
                
                // Body Part Filter
                if !availableBodyParts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
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
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                }
                
                Divider()
                
                // Exercise List
                if filteredExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.mutedForeground)
                        Text("No exercises found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        Text("Try adjusting your search or filter")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredExercises, id: \.self) { exercise in
                                Button(action: {
                                    onSelect(exercise)
                                }) {
                                    HStack {
                                        Text(exercise)
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.foreground)
                                        
                                        Spacer()
                                        
                                        if viewModel.selectedExercise == exercise {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(AppColors.background)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if exercise != filteredExercises.last {
                                    Divider()
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

#Preview {
    ProgressView(
        viewModel: ProgressViewModel(),
        onSettings: {}
    )
}
