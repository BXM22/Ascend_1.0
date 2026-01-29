//
//  ProgressView.swift
//  Ascend
//
//  Redesigned on 2025
//

import SwiftUI

enum ViewMode {
    case list, grouped
}

struct ProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var habitViewModel: HabitViewModel
    let onSettings: () -> Void
    let onNavigateToHabits: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    // State for redesign
    @State private var selectedTab: ProgressTab = .overview
    @State private var showPRHistory = false
    @State private var showFilterSheet = false
    @State private var showExerciseDetail = false
    @State private var selectedExerciseForDetail: String = ""
    @State private var searchText: String = ""
    @State private var filters = PRFilters()
    @State private var viewMode: ViewMode = .list
    @State private var expandedGroups: Set<String> = []
    
    // Performance: Cache filtered exercises
    @State private var cachedFilteredExercises: [String] = []
    @State private var lastFilterCacheKey: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Redesigned Header
            RedesignedProgressHeader(
                selectedTab: $selectedTab,
                themeManager: themeManager,
                onSettings: onSettings
            )
            
            // Segment Control
            Picker("Progress Tab", selection: $selectedTab) {
                ForEach(ProgressTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewTab(
                    viewModel: viewModel,
                    habitViewModel: habitViewModel,
                    showExerciseDetail: $showExerciseDetail,
                    selectedExercise: $selectedExerciseForDetail,
                    onNavigateToHabits: onNavigateToHabits
                )
                .tag(ProgressTab.overview)
                
                ExercisesTab(
                    viewModel: viewModel,
                    searchText: $searchText,
                    filters: $filters,
                    showFilterSheet: $showFilterSheet,
                    showExerciseDetail: $showExerciseDetail,
                    selectedExercise: $selectedExerciseForDetail,
                    viewMode: $viewMode,
                    expandedGroups: $expandedGroups
                )
                .tag(ProgressTab.exercises)
                
                StatsTab(
                    viewModel: viewModel,
                    habitViewModel: habitViewModel
                )
                .tag(ProgressTab.stats)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
        .sheet(isPresented: $showPRHistory) {
            PRHistoryView(progressViewModel: viewModel)
        }
        .sheet(isPresented: $showFilterSheet) {
            PRFilterSheet(filters: $filters)
        }
        .sheet(isPresented: $showExerciseDetail) {
            if !selectedExerciseForDetail.isEmpty {
                ExerciseDetailSheet(exercise: selectedExerciseForDetail, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Redesigned Header

struct RedesignedProgressHeader: View {
    @Binding var selectedTab: ProgressTab
    @ObservedObject var themeManager: ThemeManager
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Progress")
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Spacer()
            
            HStack(spacing: 12) {
                HelpButton(pageType: .progress)
                
                // Theme Toggle
                HeaderThemeToggle(themeManager: themeManager)
                
                // Consolidated Settings Menu
                Menu {
                    Section("Export") {
                        Button(action: { /* Future: Export data */ }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    Section {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            onSettings()
                        }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var viewModel: ProgressViewModel
    @ObservedObject var habitViewModel: HabitViewModel
    @Binding var showExerciseDetail: Bool
    @Binding var selectedExercise: String
    let onNavigateToHabits: (() -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: []) {
                // Stat Cards
                HStack(spacing: 12) {
                    EnhancedStatCard(
                        icon: "flame.fill",
                        gradient: LinearGradient.armsGradient,
                        primaryValue: "\(viewModel.currentStreak)",
                        primaryLabel: "Day Streak",
                        secondaryValue: "Best: \(viewModel.longestStreak)",
                        secondaryLabel: "Personal Best"
                    )
                    
                    EnhancedStatCard(
                        icon: "chart.bar.fill",
                        gradient: LinearGradient.backGradient,
                        primaryValue: "\(viewModel.weeklyWorkouts)",
                        primaryLabel: "This Week",
                        secondaryValue: "\(viewModel.workoutCount) Total",
                        secondaryLabel: "All Time"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Habit Stats Cards
                if habitViewModel.totalHabits > 0 {
                    HStack(spacing: 12) {
                        EnhancedStatCard(
                            icon: "checkmark.circle.fill",
                            gradient: LinearGradient.primaryGradient,
                            primaryValue: "\(Int(habitViewModel.todayCompletionRate * 100))%",
                            primaryLabel: "Habit Rate",
                            secondaryValue: "\(habitViewModel.todayCompletions)/\(habitViewModel.totalHabits)",
                            secondaryLabel: "Today"
                        )
                        
                        EnhancedStatCard(
                            icon: "flame.fill",
                            gradient: HabitGradientHelper.streakGradient,
                            primaryValue: "\(habitViewModel.activeHabits.count)",
                            primaryLabel: "Active Habits",
                            secondaryValue: "\(habitViewModel.totalHabits) Total",
                            secondaryLabel: "All Habits"
                        )
                    }
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        onNavigateToHabits?()
                    }
                }
                
                // Recent PRs Section
                if !viewModel.recentPRs().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent PRs", subtitle: "Last 7 days")
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(viewModel.recentPRs().prefix(5), id: \.id) { pr in
                                RecentPRCard(pr: pr)
                                    .onTapGesture {
                                        HapticManager.impact(style: .light)
                                        selectedExercise = pr.exercise
                                        showExerciseDetail = true
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Recent Habit Completions Section
                let recentHabitCompletions = habitViewModel.recentCompletions(days: 7)
                if !recentHabitCompletions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent Habits", subtitle: "Last 7 days")
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(recentHabitCompletions.prefix(5).enumerated()), id: \.offset) { index, completion in
                                RecentHabitCompletionCard(
                                    habit: completion.habit,
                                    date: completion.date,
                                    viewModel: habitViewModel
                                )
                                .onTapGesture {
                                    HapticManager.impact(style: .light)
                                    onNavigateToHabits?()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Top Exercises
                if !viewModel.topExercises().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Top Exercises", subtitle: "Most improved")
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            ForEach(viewModel.topExercises(), id: \.exercise) { item in
                                TopExerciseCard(
                                    exercise: item.exercise,
                                    prCount: item.prCount,
                                    gradient: AppColors.categoryGradient(for: item.exercise)
                                )
                                .onTapGesture {
                                    HapticManager.impact(style: .light)
                                    selectedExercise = item.exercise
                                    showExerciseDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Quick Insights
                if let insight = viewModel.generateInsight() {
                    InsightCard(insight: insight)
                        .padding(.horizontal, 20)
                }
                
                // Empty state if no PRs
                if viewModel.prs.isEmpty {
                    ProgressEmptyState(
                        icon: "trophy.fill",
                        title: "No PRs Yet",
                        message: "Complete a workout and crush some sets to earn your first personal record!",
                        primaryAction: nil,
                        secondaryAction: nil
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Exercises Tab

struct ExercisesTab: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var searchText: String
    @Binding var filters: PRFilters
    @Binding var showFilterSheet: Bool
    @Binding var showExerciseDetail: Bool
    @Binding var selectedExercise: String
    @Binding var viewMode: ViewMode
    @Binding var expandedGroups: Set<String>
    
    private var filteredExercises: [String] {
        var exercises = viewModel.availableExercises
        
        // Apply search
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply filters
        exercises = exercises.filter { exercise in
            let prs = viewModel.prsForExercise(exercise)
            return prs.contains { filters.matches($0) }
        }
        
        return exercises
    }
    
    private var groupedExercises: [String: [String]] {
        var groups: [String: [String]] = [:]
        
        for exercise in filteredExercises {
            let (primary, _) = ExerciseDataManager.shared.getMuscleGroups(for: exercise)
            let group = primary.first ?? "Other"
            
            if groups[group] == nil {
                groups[group] = []
            }
            groups[group]?.append(exercise)
        }
        
        return groups
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.mutedForeground)
                    TextField("Search exercises", text: $searchText)
                        .foregroundColor(AppColors.textPrimary)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.mutedForeground)
                        }
                    }
                }
                .padding(12)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: { 
                    HapticManager.impact(style: .light)
                    showFilterSheet = true 
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if filters.isActive {
                            Circle()
                                .fill(AppColors.destructive)
                                .frame(width: 8, height: 8)
                                .offset(x: -8, y: 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Exercise List
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    if filteredExercises.isEmpty {
                        ProgressEmptyState(
                            icon: "magnifyingglass",
                            title: searchText.isEmpty ? "No PRs Yet" : "No exercises found",
                            message: searchText.isEmpty ?
                                "Complete a workout and crush some sets to earn your first personal record!" :
                                "Try adjusting your filters or search terms",
                            primaryAction: searchText.isEmpty ? nil : EmptyStateAction(title: "Clear Filters", action: {
                                searchText = ""
                                filters = PRFilters()
                            }),
                            secondaryAction: nil
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises, id: \.self) { exercise in
                                // Pull PR data once per exercise to avoid repeated work during rendering
                                let prsForExercise = viewModel.prsForExercise(exercise)
                                let currentPR = prsForExercise.first
                                
                                ExercisePreviewCard(
                                    exercise: exercise,
                                    currentPR: currentPR,
                                    prCount: prsForExercise.count,
                                    lastPerformed: currentPR?.date,
                                    trend: viewModel.calculateTrend(for: exercise, using: prsForExercise)
                                )
                                .onTapGesture {
                                    HapticManager.impact(style: .light)
                                    selectedExercise = exercise
                                    showExerciseDetail = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(style: .light)
                                        for pr in prsForExercise {
                                            viewModel.deletePR(pr)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Stats Tab

struct StatsTab: View {
    @ObservedObject var viewModel: ProgressViewModel
    @ObservedObject var habitViewModel: HabitViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Progress Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Progress")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Grid of stat pills (2x3 or 3x2 depending on habits)
                    let columns = habitViewModel.totalHabits > 0 
                        ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                        : [GridItem(.flexible()), GridItem(.flexible())]
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        StatPill(
                            value: "\(viewModel.prs.count)",
                            label: "Total PRs",
                            gradient: LinearGradient.primaryGradient
                        )
                        StatPill(
                            value: "\(viewModel.monthlyPRs)",
                            label: "This Month",
                            gradient: LinearGradient.accentGradient
                        )
                        StatPill(
                            value: "\(viewModel.currentStreak)",
                            label: "Day Streak",
                            gradient: LinearGradient.armsGradient
                        )
                        StatPill(
                            value: "\(viewModel.workoutCount)",
                            label: "Workouts",
                            gradient: LinearGradient.backGradient
                        )
                        
                        // Habit stats
                        if habitViewModel.totalHabits > 0 {
                            StatPill(
                                value: "\(habitViewModel.totalHabits)",
                                label: "Habits",
                                gradient: LinearGradient.primaryGradient
                            )
                            StatPill(
                                value: "\(Int(habitViewModel.todayCompletionRate * 100))%",
                                label: "Habit Rate",
                                gradient: HabitGradientHelper.streakGradient
                            )
                            StatPill(
                                value: "\(habitViewModel.todayCompletions)",
                                label: "Today",
                                gradient: LinearGradient.primaryGradient
                            )
                        }
                    }
                }
                .padding(20)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AppColors.foreground.opacity(0.05), radius: 8)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Trend chart if exercise selected
                if !viewModel.selectedExercise.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PR Progression")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(viewModel.selectedExercise)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TrendGraphsView(viewModel: viewModel)
                            .frame(height: 200)
                    }
                    .padding(20)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AppColors.foreground.opacity(0.05), radius: 8)
                    .padding(.horizontal, 20)
                }
                
                // Empty state if no PRs
                if viewModel.prs.isEmpty {
                    ProgressEmptyState(
                        icon: "chart.bar.fill",
                        title: "No Stats Yet",
                        message: "Start tracking your workouts to see detailed progress statistics and insights!",
                        primaryAction: nil,
                        secondaryAction: nil
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Progress Empty State

struct ProgressEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let primaryAction: EmptyStateAction?
    let secondaryAction: EmptyStateAction?
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action buttons
            if let primary = primaryAction {
                VStack(spacing: 12) {
                    Button(action: primary.action) {
                        Text(primary.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryGradientButtonStyle())
                    .padding(.horizontal, 40)
                    
                    if let secondary = secondaryAction {
                        Button(action: secondary.action) {
                            Text(secondary.title)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateAction {
    let title: String
    let action: () -> Void
}

// MARK: - Button Styles

struct PrimaryGradientButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.onPrimary)
            .padding(.vertical, 14)
            .background(LinearGradient.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.impact(style: .light)
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.primary)
            .padding(.vertical, 14)
            .background(AppColors.secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.buttonPress, value: configuration.isPressed)
            .animation(AppAnimations.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticManager.impact(style: .light)
                }
            }
    }
}

// MARK: - Legacy Components (kept for compatibility with other views)

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
    @State private var showExerciseHistory = false
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
                    CurrentPRCard(pr: currentPR, viewModel: viewModel, showExerciseHistory: $showExerciseHistory)
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
                                PRHistoryItemView(pr: pr, previousPR: index > 1 ? viewModel.selectedExercisePRs[index - 1] : nil, viewModel: viewModel)
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
        .sheet(isPresented: $showExerciseHistory) {
            if !viewModel.selectedExercise.isEmpty {
                ExerciseHistoryView(
                    exerciseName: viewModel.selectedExercise,
                    progressViewModel: viewModel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Current PR Card
struct CurrentPRCard: View {
    let pr: PersonalRecord
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteConfirmation = false
    @Binding var showExerciseHistory: Bool
    
    // Reuse a single formatter instance to avoid repeated allocations during rendering
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var dateString: String {
        CurrentPRCard.dateFormatter.string(from: pr.date)
    }
    
    private var gradient: LinearGradient {
        AppColors.categoryGradient(for: pr.exercise)
    }
    
    var body: some View {
        GradientBorderedCard(gradient: gradient) {
            VStack(spacing: 16) {
                HStack {
                    Text("Current PR")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticManager.impact(style: .light)
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(width: 32, height: 32)
                            .background(AppColors.secondary.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
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
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.impact(style: .light)
            showExerciseHistory = true
        }
        .alert("Delete Personal Record", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deletePR(pr)
                HapticManager.success()
            }
        } message: {
            Text("Are you sure you want to delete this personal record? This action cannot be undone.")
        }
    }
}

// MARK: - PR History Item
struct PRHistoryItemView: View {
    let pr: PersonalRecord
    let previousPR: PersonalRecord?
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteConfirmation = false
    
    // Shared formatter to reduce allocation cost across list rows
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var dateString: String {
        PRHistoryItemView.dateFormatter.string(from: pr.date)
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
            
            Button(action: {
                HapticManager.impact(style: .light)
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
                    .frame(width: 32, height: 32)
                    .background(AppColors.secondary.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(LinearGradient.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .alert("Delete Personal Record", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deletePR(pr)
                HapticManager.success()
            }
        } message: {
            Text("Are you sure you want to delete this personal record? This action cannot be undone.")
        }
    }
}

// MARK: - Recent Habit Completion Card

struct RecentHabitCompletionCard: View {
    let habit: Habit
    let date: Date
    @ObservedObject var viewModel: HabitViewModel
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var dateString: String {
        RecentHabitCompletionCard.dateFormatter.string(from: date)
    }
    
    private var habitGradient: LinearGradient {
        HabitGradientHelper.gradient(for: habit)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(habitGradient.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(habitGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                HStack(spacing: 8) {
                    Text(dateString)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    if let streak = viewModel.getStreak(habitId: habit.id), streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(HabitGradientHelper.streakGradient)
                            Text("\(streak) day streak")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HabitGradientHelper.streakGradient.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(habitGradient)
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
    
    // Shared relative date formatter for lightweight list rendering
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    private var dateString: String {
        PRItemView.relativeFormatter.localizedString(for: pr.date, relativeTo: Date())
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
        themeManager: ThemeManager(),
        onSettings: {}
    )
}
