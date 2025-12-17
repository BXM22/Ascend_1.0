import SwiftUI

struct DashboardView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    let onSettings: () -> Void
    let onNavigateToProgress: (() -> Void)?
    @State private var showGenerateTypeDialog = false
    @State private var showWorkoutHistory = false
<<<<<<< Updated upstream
    @State private var showPRHistory = false
    
    init(
        progressViewModel: ProgressViewModel,
        workoutViewModel: WorkoutViewModel,
        templatesViewModel: TemplatesViewModel,
        programViewModel: WorkoutProgramViewModel,
        onStartWorkout: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onNavigateToProgress: (() -> Void)? = nil
    ) {
        self.progressViewModel = progressViewModel
        self.workoutViewModel = workoutViewModel
        self.templatesViewModel = templatesViewModel
        self.programViewModel = programViewModel
        self.onStartWorkout = onStartWorkout
        self.onSettings = onSettings
        self.onNavigateToProgress = onNavigateToProgress
    }
=======
    @State private var showSportsTimer = false
>>>>>>> Stashed changes
    
    private enum GeneratedDayType {
        case custom, push, pull, legs, fullBody
    }
    
    private func generateAndStartWorkout(for type: GeneratedDayType) {
        let template: WorkoutTemplate
        switch type {
        case .custom:
            template = templatesViewModel.generateWorkout()
        case .push:
            template = templatesViewModel.generatePushWorkout()
        case .pull:
            template = templatesViewModel.generatePullWorkout()
        case .legs:
            template = templatesViewModel.generateLegWorkout()
        case .fullBody:
            template = templatesViewModel.generateFullBodyWorkout()
        }
        
        workoutViewModel.startWorkoutFromTemplate(template)
        onStartWorkout()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Section with Greeting and Quick Stats
                    HeroSection(
                        progressViewModel: progressViewModel,
                        onGenerateWorkout: {
                            showGenerateTypeDialog = true
                        },
                        onOpenSportsTimer: {
                            showSportsTimer = true
                        }
                    )
                    .padding(.top, 60) // Add top padding to account for buttons
                    
                    // Header with Title
                    YourActivityHeader()
                    
                    VStack(spacing: 20) {
                    // Weekly Calendar (with program indicator if active)
                    WeeklyCalendarWidget(
                        progressViewModel: progressViewModel,
                        programViewModel: programViewModel
                    )
                    
                    // Workout Pattern Insight Card
                    WorkoutPatternInsightCard(progressViewModel: progressViewModel)
                    
                    // Recovery Suggestion Card
                    RecoverySuggestionCard()
                    
                    // Next Workout Day Card (only shows when program is active)
                    if programViewModel.activeProgram != nil {
                        NextWorkoutDayCard(
                            programViewModel: programViewModel,
                            templatesViewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            onStartWorkout: onStartWorkout
                        )
                    }
                    
                    // Personalized Recommendations Card (only show if sufficient history)
                    PersonalizedRecommendationsCard()
                    
                    // Suggested Workout Card (only show if no active program)
                    if programViewModel.activeProgram == nil {
                        SuggestedWorkoutCard(
                            workoutViewModel: workoutViewModel,
                            templatesViewModel: templatesViewModel,
                            programViewModel: programViewModel,
                            onStartWorkout: onStartWorkout
                        )
                    }
                    
                    // Sports Timer Card (prominent placement)
                    SportsTimerCard(onOpen: {
                        showSportsTimer = true
                    })
                    
                    // Stat Cards (Recent PRs + Top Exercise)
                    HStack(alignment: .top, spacing: 12) {
                        RecentPRsStatCard(
                            progressViewModel: progressViewModel,
                            onTap: {
                                HapticManager.impact(style: .light)
                                showPRHistory = true
                            }
                        )
                        TopExerciseStatCard(
                            progressViewModel: progressViewModel,
                            onTap: { exerciseName in
                                if let onNavigate = onNavigateToProgress {
                                    HapticManager.impact(style: .light)
                                    progressViewModel.selectedExercise = exerciseName
                                    onNavigate()
                                }
                            }
                        )
                    }
                    
                    // Rest Day Button
                    RestDayButton(progressViewModel: progressViewModel)
                    
                    // Muscle Group Chart
                    MuscleGroupChart(progressViewModel: progressViewModel)
                        .drawingGroup() // Optimize chart rendering
                        .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
            }
            
            // Top Right Buttons (Info, History, Settings)
            HStack(spacing: 12) {
                HelpButton(pageType: .dashboard)
                
                // Workout History Button
                Button(action: {
                    HapticManager.impact(style: .light)
                    showWorkoutHistory = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.foreground)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Workout History")
                
                SettingsButton(onSettings: onSettings)
            }
            .padding(.top, 8)
            .padding(.trailing, AppSpacing.lg)
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
        .confirmationDialog("Generate workout", isPresented: $showGenerateTypeDialog, titleVisibility: .visible) {
            Button("Custom") { generateAndStartWorkout(for: .custom) }
            Button("Push") { generateAndStartWorkout(for: .push) }
            Button("Pull") { generateAndStartWorkout(for: .pull) }
            Button("Legs") { generateAndStartWorkout(for: .legs) }
            Button("Full Body") { generateAndStartWorkout(for: .fullBody) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select the day type to auto-generate and start your workout.")
        }
        .sheet(isPresented: $showWorkoutHistory) {
            WorkoutHistoryView()
        }
<<<<<<< Updated upstream
        .sheet(isPresented: $showPRHistory) {
            PRHistoryView(progressViewModel: progressViewModel)
        }
=======
        .fullScreenCover(isPresented: $showSportsTimer) {
            SportsTimerView()
        }
    }
}

// MARK: - Sports Timer Card

struct SportsTimerCard: View {
    let onOpen: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            onOpen()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sports Timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Boxing, MMA, Wrestling & more")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(20)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
>>>>>>> Stashed changes
    }
}

// MARK: - Header

struct YourActivityHeader: View {
    var body: some View {
        HStack {
            Text("Your Activity")
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
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
                    TrendIndicator(
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
                        TrendIndicator(
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

struct TrendIndicator: View {
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
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Day")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Mark today as rest day")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Mark Rest Day", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Rest Day") {
                progressViewModel.markRestDay()
                HapticManager.success()
            }
        } message: {
            Text("This will mark today as a rest day and increment your streak. You can still work out later today if needed.")
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
            onStartWorkout: {},
            onSettings: {},
            onNavigateToProgress: nil
        )
    }
}
