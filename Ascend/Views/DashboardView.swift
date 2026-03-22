import SwiftUI

// MARK: - Dashboard (aligned with Habits — Kinetic palette)

private enum HabitsFonts {
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Bold", size: size, relativeTo: .body)
    }

    static func semiBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-SemiBold", size: size, relativeTo: .body)
    }

    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Medium", size: size, relativeTo: .body)
    }

    static func extraBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settingsManager: SettingsManager
    @EnvironmentObject var colorThemeProvider: ColorThemeProvider
    @Environment(\.kineticPalette) private var kp
    let onStartWorkout: () -> Void
    let onSettings: () -> Void
    let onNavigateToProgress: (() -> Void)?
    
    @State private var showWorkoutHistory = false

    private static let weeklyVolumeChartHeight: CGFloat = 80

    init(
        progressViewModel: ProgressViewModel,
        workoutViewModel: WorkoutViewModel,
        templatesViewModel: TemplatesViewModel,
        programViewModel: WorkoutProgramViewModel,
        themeManager: ThemeManager,
        settingsManager: SettingsManager,
        onStartWorkout: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onNavigateToProgress: (() -> Void)? = nil
    ) {
        self.progressViewModel = progressViewModel
        self.workoutViewModel = workoutViewModel
        self.templatesViewModel = templatesViewModel
        self.programViewModel = programViewModel
        self.themeManager = themeManager
        self.settingsManager = settingsManager
        self.onStartWorkout = onStartWorkout
        self.onSettings = onSettings
        self.onNavigateToProgress = onNavigateToProgress
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                settingsAccessoryRow
                welcomeAndStreakSection
                activeGoalCard
                metricsGrid
                restDayRow
                recentActivitySection
            }
            .frame(maxWidth: AppConstants.UI.mainColumnMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppConstants.UI.mainColumnGutter)
            .padding(.top, 16)
            .padding(.bottom, 128)
        }
        .scrollIndicators(.hidden)
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
        .background(kp.surface)
        .id(colorThemeProvider.themeID)
        .sheet(isPresented: $showWorkoutHistory) {
            WorkoutHistoryView()
        }
    }

    /// Settings only (no fixed header bar).
    private var settingsAccessoryRow: some View {
        HStack {
            Spacer()
            HelpButton(pageType: .dashboard)
            Button {
                HapticManager.impact(style: .light)
                onSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(kp.mutedNav)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var welcomeAndStreakSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back")
                    .font(HabitsFonts.bold(11))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.onSurfaceVariant)
                Text("Ready to Move?")
                    .font(HabitsFonts.extraBold(36))
                    .foregroundStyle(kp.onSurface)
                    .kineticDisplayTracking(for: 36)
            }
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(kp.tertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(progressViewModel.currentStreak) Days")
                        .font(HabitsFonts.bold(20))
                        .foregroundStyle(kp.onSurface)
                    Text("STREAK")
                        .font(HabitsFonts.bold(10))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.onSurfaceVariant)
                }
            }
            .padding(16)
            .background(kp.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var activeGoalCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(kp.primary.opacity(0.1))
                .blur(radius: 28)
                .padding(-8)

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dashboardActiveCardSectionLabel)
                        .font(HabitsFonts.bold(11))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary)
                    Text(dashboardActiveCardTitle)
                        .font(HabitsFonts.bold(30))
                        .foregroundStyle(kp.onSurface)
                    if let sub = dashboardActiveCardSubtitle {
                        Text(sub)
                            .font(HabitsFonts.medium(14))
                            .foregroundStyle(kp.onSurfaceVariant)
                    }
                }

                HStack(spacing: 16) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(kp.surfaceContainerHighest)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [kp.primary, kp.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * weeklyCompletionRatio))
                        }
                    }
                    .frame(height: 12)

                    Text("\(weeklyWorkoutCount) OF \(weeklyGoalTarget) WORKOUTS")
                        .font(HabitsFonts.bold(11))
                        .foregroundStyle(kp.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Button(action: handleDashboardActiveCardPrimaryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: dashboardActiveCardButtonIcon)
                            .font(.system(size: 20, weight: .bold))
                        Text(dashboardActiveCardButtonTitle)
                            .font(HabitsFonts.extraBold(16))
                    }
                    .foregroundStyle(kp.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(kp.primary)
                    .clipShape(Capsule())
                    .shadow(color: kp.primary.opacity(0.3), radius: 16, x: 0, y: 4)
                    .opacity(dashboardActiveCardButtonDisabled ? 0.45 : 1)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(dashboardActiveCardButtonDisabled)
            }
            .padding(32)
            .background(
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(kp.surfaceContainerHigh)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 160))
                        .foregroundStyle(kp.onSurface.opacity(0.05))
                        .offset(x: 32, y: 32)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var metricsGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            latestPRCard
            weeklyVolumeCard
        }
    }

    private var latestPRCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(kp.secondary)
                Spacer()
                Text("LATEST PR")
                    .font(HabitsFonts.bold(10))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            .padding(.bottom, 16)

            if let pr = latestPR {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(pr.weight))")
                        .font(HabitsFonts.bold(30))
                        .foregroundStyle(kp.onSurface)
                    Text("lbs")
                        .font(HabitsFonts.medium(18))
                        .foregroundStyle(kp.onSurfaceVariant)
                }
                Text(pr.exercise)
                    .font(HabitsFonts.medium(14))
                    .foregroundStyle(kp.onSurfaceVariant)
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(kp.outlineVariant.opacity(0.1))
                        .frame(height: 1)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12, weight: .semibold))
                        Text(prTrendLine)
                            .font(HabitsFonts.medium(12))
                    }
                    .foregroundStyle(kp.secondary)
                }
                .padding(.top, 16)
            } else {
                Text("No PRs")
                    .font(HabitsFonts.bold(24))
                    .foregroundStyle(kp.onSurface)
                Text("Log a workout to start tracking")
                    .font(HabitsFonts.medium(12))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .frame(minHeight: 200, alignment: .top)
        .background(kp.surfaceContainerLow)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            onNavigateToProgress?()
        }
    }

    private var weeklyVolumeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(kp.primary)
                Spacer()
                Text("WEEKLY VOLUME")
                    .font(HabitsFonts.bold(10))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            .padding(.bottom, 24)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(dailyVolumeRatios.enumerated()), id: \.offset) { index, ratio in
                    let maxR = dailyVolumeRatios.max() ?? 0
                    let height = Self.weeklyVolumeChartHeight * CGFloat(ratio)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ratio == maxR && ratio > 0 ? kp.primary : kp.surfaceContainerHighest)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(6, height))
                }
            }
            .frame(height: Self.weeklyVolumeChartHeight)

            HStack {
                ForEach(0..<7, id: \.self) { i in
                    Text(rollingWeekdayLetter(for: i))
                        .font(HabitsFonts.bold(8))
                        .textCase(.uppercase)
                        .foregroundStyle(kp.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .frame(minHeight: 200, alignment: .top)
        .background(kp.surfaceContainerLow)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var restDayRow: some View {
        RestDayButton(progressViewModel: progressViewModel)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(HabitsFonts.bold(20))
                    .foregroundStyle(kp.onSurface)
                Spacer()
                Button {
                    showWorkoutHistory = true
                } label: {
                    Text("View All")
                        .font(HabitsFonts.bold(12))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                ForEach(Array(recentWorkouts.prefix(3).enumerated()), id: \.element.id) { index, workout in
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(kp.surfaceContainerHigh)
                                .frame(width: 48, height: 48)
                            Image(systemName: workoutIcon(for: workout))
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(activityIconTint(for: index))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(HabitsFonts.bold(15))
                                .foregroundStyle(kp.onSurface)
                            Text(activitySubtitle(for: workout))
                                .font(HabitsFonts.medium(12))
                                .foregroundStyle(kp.onSurfaceVariant)
                        }
                        Spacer(minLength: 8)
                        Text(activityDateLabel(for: workout.startDate))
                            .font(HabitsFonts.bold(10))
                            .foregroundStyle(kp.onSurfaceVariant)
                    }
                    .padding(16)
                    .background(kp.surfaceContainerLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(kp.outlineVariant.opacity(0.05), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    /// Current program day for the dashboard hero card (nil when no plan is active).
    private var dashboardActiveProgramInfo: (program: WorkoutProgram, currentDay: WorkoutDay, dayIndex: Int)? {
        guard let active = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == active.programId }),
              let currentDay = programViewModel.getCurrentDay(for: program) else {
            return nil
        }
        let dayIndex = active.getCurrentDayIndex(totalDays: program.days.count)
        return (program, currentDay, dayIndex)
    }

    private func isDashboardRestProgramDay(_ day: WorkoutDay) -> Bool {
        day.isRestDay || day.name.lowercased().contains("rest")
    }

    private var dashboardActiveCardSectionLabel: String {
        dashboardActiveProgramInfo == nil ? "Quick start" : "Active plan"
    }

    private var dashboardActiveCardTitle: String {
        guard let info = dashboardActiveProgramInfo else {
            return "Random template"
        }
        if let templateId = info.currentDay.templateId,
           let template = templatesViewModel.templates.first(where: { $0.id == templateId }) {
            return template.name
        }
        return "Day \(info.currentDay.dayNumber): \(info.currentDay.name)"
    }

    private var dashboardActiveCardSubtitle: String? {
        if let info = dashboardActiveProgramInfo {
            return info.program.name
        }
        return "We’ll pick a saved workout for you"
    }

    private var dashboardActiveCardButtonTitle: String {
        if let info = dashboardActiveProgramInfo, isDashboardRestProgramDay(info.currentDay) {
            return progressViewModel.isRestDay ? "REST DAY LOGGED" : "MARK REST DAY"
        }
        if dashboardActiveProgramInfo != nil {
            return "START WORKOUT"
        }
        return "START RANDOM TEMPLATE"
    }

    private var dashboardActiveCardButtonIcon: String {
        if let info = dashboardActiveProgramInfo, isDashboardRestProgramDay(info.currentDay) {
            return progressViewModel.isRestDay ? "checkmark.circle.fill" : "moon.zzz.fill"
        }
        if dashboardActiveProgramInfo != nil {
            return "play.fill"
        }
        return "shuffle"
    }

    private var dashboardActiveCardButtonDisabled: Bool {
        guard let info = dashboardActiveProgramInfo, isDashboardRestProgramDay(info.currentDay) else {
            return false
        }
        return progressViewModel.isRestDay
    }

    private func handleDashboardActiveCardPrimaryAction() {
        HapticManager.impact(style: .medium)
        if let info = dashboardActiveProgramInfo {
            if isDashboardRestProgramDay(info.currentDay) {
                if !progressViewModel.isRestDay {
                    progressViewModel.markRestDay()
                    HapticManager.success()
                }
                return
            }
            ActiveProgramDayWorkoutStart.start(
                program: info.program,
                currentDay: info.currentDay,
                programViewModel: programViewModel,
                templatesViewModel: templatesViewModel,
                workoutViewModel: workoutViewModel,
                onWorkoutReady: onStartWorkout,
                onGeneratedTemplate: nil
            )
            return
        }
        startRandomTemplateWorkout()
    }

    private func startRandomTemplateWorkout() {
        let pool = templatesViewModel.templates.filter { !$0.exercises.isEmpty && !$0.name.contains("Progression") }
        if let template = pool.randomElement() {
            templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
            onStartWorkout()
        } else {
            let generated = templatesViewModel.generateWorkout(name: "Quick workout")
            templatesViewModel.startTemplate(generated, workoutViewModel: workoutViewModel)
            onStartWorkout()
        }
    }

    private var latestPR: PersonalRecord? {
        progressViewModel.prs.max(by: { $0.date < $1.date })
    }

    private var recentWorkouts: [Workout] {
        WorkoutHistoryManager.shared.completedWorkouts
            .sorted(by: { $0.startDate > $1.startDate })
    }

    private var weeklyGoalTarget: Int { settingsManager.weeklyWorkoutGoal }
    private var weeklyWorkoutCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return progressViewModel.workoutDates.filter { $0 >= weekAgo }.count
    }
    private var weeklyCompletionRatio: CGFloat {
        CGFloat(min(Double(weeklyWorkoutCount) / Double(weeklyGoalTarget), 1.0))
    }

    private var prTrendText: String {
        let sorted = progressViewModel.prs.sorted { $0.date > $1.date }
        guard sorted.count > 1 else { return "New PR logged" }
        let latest = sorted[0]
        let previous = sorted[1]
        let diff = Int(latest.weight - previous.weight)
        if diff > 0 { return "+\(diff) lbs from previous PR" }
        if diff < 0 { return "\(diff) lbs from previous PR" }
        return "Matched previous PR"
    }

    /// Prefer “last month” when a 30‑day baseline exists for the same lift.
    private var prTrendLine: String {
        let sorted = progressViewModel.prs.sorted { $0.date > $1.date }
        guard let latest = sorted.first else { return "New PR logged" }
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        if let older = sorted.first(where: { $0.exercise == latest.exercise && $0.date < latest.date && $0.date >= thirtyDaysAgo }) {
            let diff = Int(latest.weight - older.weight)
            if diff > 0 { return "+\(diff) lbs from last month" }
            if diff < 0 { return "\(diff) lbs from last month" }
        }
        guard sorted.count > 1 else { return "New PR logged" }
        let previous = sorted[1]
        let diff = Int(latest.weight - previous.weight)
        if diff > 0 { return "+\(diff) lbs from last PR" }
        if diff < 0 { return "\(diff) lbs from last PR" }
        return "Matched last PR"
    }

    private var dailyVolumeRatios: [CGFloat] {
        let calendar = Calendar.current
        let workouts = recentWorkouts
        let volumes: [Double] = (0..<7).map { offset in
            let targetDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date())
            let dayWorkouts = workouts.filter { calendar.isDate($0.startDate, inSameDayAs: targetDay) }
            return dayWorkouts.reduce(0.0) { total, workout in
                total + workout.exercises.reduce(0.0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                        setTotal + (set.weight * Double(set.reps))
                    }
                }
            }
        }
        let maxValue = max(volumes.max() ?? 1.0, 1.0)
        return volumes.map { CGFloat($0 / maxValue) }
    }

    private func workoutIcon(for workout: Workout) -> String {
        let lower = workout.name.lowercased()
        if lower.contains("cardio") { return "figure.run" }
        if lower.contains("yoga") || lower.contains("recovery") { return "figure.mind.and.body" }
        return "dumbbell.fill"
    }

    private func activitySubtitle(for workout: Workout) -> String {
        let volume = workout.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + Int(set.weight * Double(set.reps))
            }
        }
        let estMinutes = max(12, workout.exercises.count * 12)
        return "\(estMinutes) mins • \(volume.formatted()) lbs total"
    }

    private func activityDateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "TODAY" }
        if Calendar.current.isDateInYesterday(date) { return "YESTERDAY" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }

    private func rollingWeekdayLetter(for index: Int) -> String {
        let calendar = Calendar.current
        guard let day = calendar.date(byAdding: .day, value: -6 + index, to: Date()) else { return "?" }
        let weekday = calendar.component(.weekday, from: day)
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return letters[(weekday - 1) % 7]
    }

    private func activityIconTint(for index: Int) -> Color {
        switch index % 3 {
        case 0: return kp.secondary
        case 1: return kp.primary
        default: return kp.tertiary
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
    @Environment(\.kineticPalette) private var kp
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var showConfirmation = false

    private var hasWorkoutToday: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return progressViewModel.workoutDates.contains { cal.isDate($0, inSameDayAs: today) }
    }

    var body: some View {
        Group {
            if progressViewModel.isRestDay {
                restDayLoggedRow
            } else if hasWorkoutToday {
                workoutLoggedInfoRow
            } else {
                markRestDayButton
            }
        }
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

    private var restDayLoggedRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(kp.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest day logged")
                    .font(HabitsFonts.bold(15))
                    .foregroundStyle(kp.onSurface)
                Text("Today counts toward your streak")
                    .font(HabitsFonts.medium(12))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(kp.surfaceContainerLow)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rest day logged for today")
    }

    private var workoutLoggedInfoRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(kp.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Workout logged today")
                    .font(HabitsFonts.bold(15))
                    .foregroundStyle(kp.onSurface)
                Text("Rest day can’t be used on a workout day")
                    .font(HabitsFonts.medium(12))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(kp.surfaceContainerLow.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(kp.outlineVariant.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workout logged today, rest day unavailable")
    }

    private var markRestDayButton: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            showConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(kp.primary)
                Text("Mark today as rest day")
                    .font(HabitsFonts.bold(15))
                    .foregroundStyle(kp.onSurface)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(kp.onSurfaceVariant)
            }
            .padding(16)
            .background(kp.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Mark Rest Day")
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
            settingsManager: settingsMgr,
            onStartWorkout: {},
            onSettings: {},
            onNavigateToProgress: nil
        )
        .environmentObject(ColorThemeProvider.shared)
    }
}
