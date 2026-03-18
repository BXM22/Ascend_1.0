import SwiftUI

// MARK: - Redesigned Dashboard View
/// Streamlined dashboard with improved information hierarchy and progressive disclosure
/// Created: December 18, 2025
struct DashboardView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @EnvironmentObject var colorThemeProvider: ColorThemeProvider
    let onStartWorkout: () -> Void
    let onSettings: () -> Void
    let onNavigateToProgress: (() -> Void)?
    
    @State private var showWorkoutHistory = false
    @State private var selectedTab: DashboardTab = .overview
    @State private var insightsExpanded: Bool = true
    @State private var muscleChartExpanded: Bool = true
    
    // Habits
    @StateObject private var habitViewModel = HabitViewModel()
    @State private var showCreateHabit = false
    @State private var editingHabit: Habit?
    @State private var selectedHabit: Habit?
    @State private var expandedHabits: Set<UUID> = []
    
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case analytics = "Analytics"
        case habits = "Habits"
        
        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .analytics: return "chart.bar.fill"
            case .habits: return "checkmark.circle.fill"
            }
        }
    }
    
    init(
        progressViewModel: ProgressViewModel,
        workoutViewModel: WorkoutViewModel,
        templatesViewModel: TemplatesViewModel,
        programViewModel: WorkoutProgramViewModel,
        themeManager: ThemeManager,
        onStartWorkout: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onNavigateToProgress: (() -> Void)? = nil
    ) {
        self.progressViewModel = progressViewModel
        self.workoutViewModel = workoutViewModel
        self.templatesViewModel = templatesViewModel
        self.programViewModel = programViewModel
        self.themeManager = themeManager
        self.onStartWorkout = onStartWorkout
        self.onSettings = onSettings
        self.onNavigateToProgress = onNavigateToProgress
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky Header
            DashboardHeader(
                progressViewModel: progressViewModel,
                programViewModel: programViewModel,
                themeManager: themeManager,
                onSettings: onSettings,
                onShowHistory: {
                    showWorkoutHistory = true
                }
            )
            .id(colorThemeProvider.themeID)
            .background(AppColors.background)
            
            // Tab Selector
            DashboardTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .background(AppColors.background)
            
            // Tab Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    tabContent
                }
                .padding(.bottom, 100) // Padding for tab bar
            }
        }
        .onAppear {
            // Ensure data is loaded when dashboard appears
            progressViewModel.updateVolumeAndCount()
            // Force refresh of workout dates from history
            let historyManager = WorkoutHistoryManager.shared
            let calendar = Calendar.current
            let workoutDatesFromHistory = historyManager.completedWorkouts.map { workout in
                calendar.startOfDay(for: workout.startDate)
            }
            let existingDates = Set(progressViewModel.workoutDates.map { calendar.startOfDay(for: $0) })
            let newDates = workoutDatesFromHistory.filter { !existingDates.contains($0) }
            for date in newDates {
                progressViewModel.addWorkoutDate(date)
            }
            
            // Load saved preferences (default to collapsed for better initial view)
            if UserDefaults.standard.object(forKey: "dashboard.insightsExpanded") == nil {
                insightsExpanded = false // Default collapsed
            } else {
                insightsExpanded = UserDefaults.standard.bool(forKey: "dashboard.insightsExpanded")
            }
            
            if UserDefaults.standard.object(forKey: "dashboard.muscleChartExpanded") == nil {
                muscleChartExpanded = true // Default expanded
            } else {
                muscleChartExpanded = UserDefaults.standard.bool(forKey: "dashboard.muscleChartExpanded")
            }
            
            // Preload template data for active program
            if programViewModel.activeProgram != nil {
                preloadActiveProgramData()
            }
            
            // Warm cache
            CardDetailCacheManager.shared.warmCache(
                programs: programViewModel.programs,
                templates: templatesViewModel.templates
            )
        }
        .background(AppColors.background)
        .id(colorThemeProvider.themeID)
        .sheet(isPresented: $showWorkoutHistory) {
            WorkoutHistoryView()
        }
        .sheet(isPresented: $showCreateHabit) {
            HabitEditView(
                habit: nil,
                onSave: { habit in
                    habitViewModel.createHabit(habit)
                    showCreateHabit = false
                },
                onCancel: {
                    showCreateHabit = false
                }
            )
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditView(
                habit: habit,
                onSave: { updatedHabit in
                    habitViewModel.updateHabit(updatedHabit)
                    editingHabit = nil
                },
                onCancel: {
                    editingHabit = nil
                },
                onDelete: {
                    habitViewModel.deleteHabit(habit)
                    editingHabit = nil
                }
            )
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(
                habit: habit,
                viewModel: habitViewModel
            )
        }
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .analytics:
            analyticsContent
        case .habits:
            habitsContent
        }
    }
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Streak and Workout Count Card
            StreakWorkoutCard(progressViewModel: progressViewModel)
                .padding(.horizontal, 20)
            
            // Calendar View (moved from Activity section)
            WeeklyCalendarWidget(
                progressViewModel: progressViewModel,
                programViewModel: programViewModel
            )
            .padding(.horizontal, 20)
            
            // Active Program Day Card (if program is active)
            if programViewModel.activeProgram != nil {
                ActiveProgramDayCard(
                    programViewModel: programViewModel,
                    templatesViewModel: templatesViewModel,
                    workoutViewModel: workoutViewModel,
                    progressViewModel: progressViewModel,
                    onStartWorkout: onStartWorkout
                )
                .padding(.horizontal, 20)
            }
            
            // Suggested Workout Card (only show if no active program)
            if programViewModel.activeProgram == nil {
                SuggestedWorkoutCard(
                    workoutViewModel: workoutViewModel,
                    templatesViewModel: templatesViewModel,
                    programViewModel: programViewModel,
                    onStartWorkout: onStartWorkout
                )
                .padding(.horizontal, 20)
            }
            
            // Quick Actions (only show if no active program)
            if programViewModel.activeProgram == nil {
                QuickActionsSection(
                    progressViewModel: progressViewModel,
                    workoutViewModel: workoutViewModel,
                    templatesViewModel: templatesViewModel,
                    programViewModel: programViewModel,
                    onStartWorkout: onStartWorkout
                )
            }
            
            // Rest Day Button — only when no active program and today not already logged
            if programViewModel.activeProgram == nil && !progressViewModel.isRestDay {
                RestDayButton(progressViewModel: progressViewModel)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var analyticsContent: some View {
        VStack(spacing: 16) {
            // Recovery Section
            RecoverySectionView(progressViewModel: progressViewModel)
                .padding(.top, 8)
            
            // Muscle Chart
            MuscleChartSection(progressViewModel: progressViewModel)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private var habitsContent: some View {
        VStack(spacing: 16) {
            if habitViewModel.activeHabits.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Habits Yet",
                    message: "Create your first habit to start building consistency.",
                    actionTitle: "Add Habit",
                    action: {
                        HapticManager.impact(style: .medium)
                        showCreateHabit = true
                    },
                    style: .standard
                )
                .padding(.horizontal, 20)
                .padding(.top, 40)
            } else {
                HabitsSummaryCard(viewModel: habitViewModel)
                    .padding(.horizontal, 20)
                
                LazyVStack(spacing: 12) {
                    ForEach(habitViewModel.activeHabits) { habit in
                        HabitCard(
                            habit: habit,
                            viewModel: habitViewModel,
                            isExpanded: expandedHabits.contains(habit.id),
                            onTap: {
                                selectedHabit = habit
                            },
                            onToggleExpand: {
                                if expandedHabits.contains(habit.id) {
                                    expandedHabits.remove(habit.id)
                                } else {
                                    expandedHabits.insert(habit.id)
                                }
                            },
                            onEdit: { habit in
                                // Ensure we present the editor, not the detail sheet
                                selectedHabit = nil
                                editingHabit = habit
                            },
                            onDelete: { habit in
                                habitViewModel.deleteHabit(habit)
                            }
                        )
                        // Force refresh when completion state changes
                        .id(habit.id.uuidString + "_\(habitViewModel.isCompleted(habitId: habit.id))")
                        .padding(.horizontal, 20)
                    }
                }
                
                Button(action: {
                    HapticManager.impact(style: .medium)
                    showCreateHabit = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Add Habit")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }
    
    private func preloadActiveProgramData() {
        // Capture needed values explicitly
        let programVM = programViewModel
        let templatesVM = templatesViewModel
        
        DispatchQueue.global(qos: .utility).async {
            guard let active = programVM.activeProgram,
                  let program = programVM.programs.first(where: { $0.id == active.programId }),
                  let currentDay = programVM.getCurrentDay(for: program) else {
                return
            }
            
            // Preload current day template
            if let templateId = currentDay.templateId {
                if CardDetailCacheManager.shared.getCachedTemplate(templateId) == nil {
                    if let template = templatesVM.templates.first(where: { $0.id == templateId }) {
                        CardDetailCacheManager.shared.cacheTemplate(template)
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard Tab Bar

private struct DashboardTabBar: View {
    @Binding var selectedTab: DashboardView.DashboardTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DashboardView.DashboardTab.allCases, id: \.self) { tab in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.mutedForeground)
                            .frame(height: 22)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppColors.primary : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .accessibilityLabel(tab.rawValue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeader: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @EnvironmentObject var colorThemeProvider: ColorThemeProvider
    let onSettings: () -> Void
    let onShowHistory: () -> Void
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }
    
    var body: some View {
        HStack {
            Text("Dashboard")
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            HStack(spacing: 12) {
                HelpButton(pageType: .dashboard)
                
                HeaderThemeToggle(themeManager: themeManager)
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onShowHistory()
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Workout History")
                
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
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .id(colorThemeProvider.themeID)
    }
}


// MARK: - Settings Button

struct SettingsButton: View {
    let onSettings: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            onSettings()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.foreground)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Settings")
    }
}

// MARK: - Stat Cards

struct RecentPRsStatCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    let onTap: () -> Void
    
    private var recentPRsCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return progressViewModel.prs.filter { $0.date >= weekAgo }.count
    }
    
    private var trendData: (change: Int, percentage: Double, isNew: Bool) {
        let calendar = Calendar.current
        let today = Date()
        
        // Current period: Last 7 days
        let currentPeriodStart = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let currentCount = progressViewModel.prs.filter { $0.date >= currentPeriodStart }.count
        
        // Previous period: 7 days before that (days 8-14 ago)
        let previousPeriodStart = calendar.date(byAdding: .day, value: -14, to: today) ?? today
        let previousPeriodEnd = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let previousCount = progressViewModel.prs.filter { 
            $0.date >= previousPeriodStart && $0.date < previousPeriodEnd 
        }.count
        
        let change = currentCount - previousCount
        let percentage: Double
        let isNew: Bool
        
        if previousCount == 0 {
            percentage = currentCount > 0 ? 100.0 : 0.0
            isNew = true
        } else {
            percentage = (Double(change) / Double(previousCount)) * 100.0
            isNew = false
        }
        
        return (change: change, percentage: percentage, isNew: isNew)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon with sparkle effect
            ZStack {
                Circle()
                    .fill(LinearGradient.chestGradient.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .shadow(color: AppColors.chestGradientEnd.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(LinearGradient.chestGradient)
                
                if recentPRsCount > 0 {
                    SparkleEffect(count: 4, iconSize: 60)
                }
            }
            .frame(height: 60)
            
            Spacer(minLength: 0)
            
            // Number with pulse animation
            VStack(alignment: .leading, spacing: 6) {
                Text("\(recentPRsCount)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(LinearGradient.chestGradient)
                    .contentTransition(.numericText())
                    .pulseEffect(scale: 1.02, duration: 2.0)
                    .frame(height: 52)
                
                Text("PRs This Week")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .frame(height: 18)
                
                // Trend indicator
                if recentPRsCount > 0 {
                    TrendIndicatorView(
                        change: trendData.change,
                        percentage: trendData.percentage,
                        isNew: trendData.isNew
                    )
                    .frame(height: 24)
                } else {
                    Spacer()
                        .frame(height: 24)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .frame(height: 220)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.card)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.chestGradient.opacity(0.12))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.chestGradient.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 16, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            onTap()
        }
    }
}

struct TopExerciseStatCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    let onTap: (String) -> Void
    
    private var topExercise: (name: String, count: Int)? {
        let exerciseCounts = Dictionary(grouping: progressViewModel.prs, by: { $0.exercise })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return exerciseCounts.first.map { ($0.key, $0.value) }
    }
    
    private var trendData: (change: Int, percentage: Double, isNew: Bool) {
        guard let exercise = topExercise else {
            return (change: 0, percentage: 0, isNew: false)
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Current period: Last 7 days
        let currentPeriodStart = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let currentCount = progressViewModel.prs.filter { 
            $0.exercise == exercise.name && $0.date >= currentPeriodStart 
        }.count
        
        // Previous period: 7 days before that (days 8-14 ago)
        let previousPeriodStart = calendar.date(byAdding: .day, value: -14, to: today) ?? today
        let previousPeriodEnd = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let previousCount = progressViewModel.prs.filter { 
            $0.exercise == exercise.name && 
            $0.date >= previousPeriodStart && $0.date < previousPeriodEnd 
        }.count
        
        let change = currentCount - previousCount
        let percentage: Double
        let isNew: Bool
        
        if previousCount == 0 {
            percentage = currentCount > 0 ? 100.0 : 0.0
            isNew = true
        } else {
            percentage = (Double(change) / Double(previousCount)) * 100.0
            isNew = false
        }
        
        return (change: change, percentage: percentage, isNew: isNew)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(LinearGradient.backGradient.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .shadow(color: AppColors.backGradientEnd.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(LinearGradient.backGradient)
            }
            .frame(height: 60)
            
            Spacer(minLength: 0)
            
            if let exercise = topExercise {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LinearGradient.backGradient)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(height: 44, alignment: .top)
                    
                    Text("\(exercise.count) PRs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .frame(height: 18)
                    
                    // Trend indicator
                    if exercise.count > 0 {
                        TrendIndicatorView(
                            change: trendData.change,
                            percentage: trendData.percentage,
                            isNew: trendData.isNew
                        )
                        .frame(height: 24)
                    } else {
                        Spacer()
                            .frame(height: 24)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No Data")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.mutedForeground)
                        .frame(height: 44, alignment: .top)
                    
                    Text("Start tracking")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .frame(height: 18)
                    
                    Spacer()
                        .frame(height: 24)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .frame(height: 220)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.card)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient.backGradient.opacity(0.12))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.backGradient.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: AppColors.foreground.opacity(0.1), radius: 16, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            if let exercise = topExercise {
                onTap(exercise.name)
            }
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicatorView: View {
    let change: Int
    let percentage: Double
    let isNew: Bool
    
    private var trendColor: Color {
        if isNew {
            return AppColors.success
        } else if change > 0 {
            return AppColors.success
        } else if change < 0 {
            return AppColors.mutedForeground
        } else {
            return AppColors.mutedForeground
        }
    }
    
    private var trendIcon: String {
        if isNew {
            return "sparkles"
        } else if change > 0 {
            return "arrow.up"
        } else if change < 0 {
            return "arrow.down"
        } else {
            return "minus"
        }
    }
    
    private var trendText: String {
        if isNew {
            return "New"
        } else if change == 0 {
            return "0%"
        } else {
            let sign = change > 0 ? "+" : ""
            return "\(sign)\(Int(abs(percentage)))%"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.system(size: 10, weight: .semibold))
            
            Text(trendText)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(trendColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trendColor.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Rest Day Button

struct RestDayButton: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            showConfirmation = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.accent)
                
                Text("Mark today as rest day")
                    .font(AppTypography.bodySmallMedium)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 12)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.foreground.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Mark Rest Day", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Rest Day") {
                progressViewModel.markRestDay()
                HapticManager.success()
            }
        } message: {
            Text("Marks today as rest and keeps your streak going.")
        }
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let progressVM = ProgressViewModel()
        let settingsMgr = SettingsManager()
        let templatesVM = TemplatesViewModel()
        let programVM = WorkoutProgramViewModel()
        let themeMgr = ThemeManager()
        let workoutVM = WorkoutViewModel(
            settingsManager: settingsMgr,
            progressViewModel: progressVM,
            programViewModel: programVM,
            templatesViewModel: templatesVM,
            themeManager: themeMgr
        )
        
        return DashboardView(
            progressViewModel: progressVM,
            workoutViewModel: workoutVM,
            templatesViewModel: templatesVM,
            programViewModel: programVM,
            themeManager: themeMgr,
            onStartWorkout: {},
            onSettings: {},
            onNavigateToProgress: nil
        )
    }
}
