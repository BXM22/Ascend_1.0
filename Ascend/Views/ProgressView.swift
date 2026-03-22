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

// MARK: - Kinetic Progress (Progress / Stats mock — tonal surfaces + Manrope)

/// Nested segments inside Progress → Exercises (HTML: Stats | Exercises | Records).
enum ExercisesProgressSubTab: String, CaseIterable {
    case stats = "Stats"
    case exercises = "Exercises"
    case records = "Records"
}

private enum ProgressFonts {
    static func medium(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Medium", size: size, relativeTo: .body)
    }
    static func semiBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-SemiBold", size: size, relativeTo: .body)
    }
    static func bold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-Bold", size: size, relativeTo: .body)
    }
    static func extraBold(_ size: CGFloat) -> Font {
        Font.custom("Manrope-ExtraBold", size: size, relativeTo: .body)
    }
}

struct ProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @ObservedObject var themeManager: ThemeManager
    let onSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.kineticPalette) private var kp
    
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
    @State private var exercisesProgressSubTab: ExercisesProgressSubTab = .exercises
    
    // Performance: Cache filtered exercises
    @State private var cachedFilteredExercises: [String] = []
    @State private var lastFilterCacheKey: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // No avatar / KINETIC ATELIER — keep title + subtitle on all Progress sub-tabs.
            KineticProgressTopBar(
                progressViewModel: viewModel,
                themeManager: themeManager,
                onSettings: onSettings,
                showLeadingBrand: false
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Progress")
                    .font(ProgressFonts.extraBold(34))
                    .foregroundStyle(kp.onSurface)
                    .kineticDisplayTracking(for: 34)
                Text("Performance tracking and kinetic analysis")
                    .font(ProgressFonts.medium(14))
                    .foregroundStyle(kp.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            KineticProgressSegmentedBar(selection: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)

            // Use `switch` instead of `TabView(.page)`: page-style TabViews often fail to sync
            // `selection` when swiping, so `selectedTab` stayed wrong and the header never hid on Stats.
            Group {
                switch selectedTab {
                case .overview:
                    OverviewTab(viewModel: viewModel, showExerciseDetail: $showExerciseDetail, selectedExercise: $selectedExerciseForDetail)
                case .exercises:
                    ExercisesTab(
                        viewModel: viewModel,
                        searchText: $searchText,
                        filters: $filters,
                        showFilterSheet: $showFilterSheet,
                        showExerciseDetail: $showExerciseDetail,
                        selectedExercise: $selectedExerciseForDetail,
                        viewMode: $viewMode,
                        expandedGroups: $expandedGroups,
                        exercisesSubTab: $exercisesProgressSubTab
                    )
                case .stats:
                    StatsTab(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .background(kp.surface)
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

// MARK: - Kinetic top chrome

private struct KineticProgressTopBar: View {
    @Environment(\.kineticPalette) private var kp
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var themeManager: ThemeManager
    let onSettings: () -> Void
    /// When false, hides avatar + **KINETIC ATELIER** (Progress uses this for all sub-tabs).
    var showLeadingBrand: Bool = true

    @State private var showExportShare = false
    @State private var exportFileURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            if showLeadingBrand {
                ZStack {
                    Circle()
                        .fill(kp.surfaceContainerHighest)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(kp.tertiary.opacity(0.85))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                Text("KINETIC ATELIER")
                    .font(ProgressFonts.bold(17))
                    .tracking(-0.34)
                    .foregroundStyle(kp.primary)
            }

            Spacer()

            HStack(spacing: 16) {
                HelpButton(pageType: .progress)
                
                HeaderThemeToggle(themeManager: themeManager)
                
                Menu {
                    Section("Export") {
                        Button(action: {
                            HapticManager.impact(style: .light)
                            do {
                                exportFileURL = try AppDataExportService.writeTempExportFile(progressViewModel: progressViewModel)
                                showExportShare = true
                            } catch {
                                Logger.error("Failed to export data", error: error, category: .persistence)
                            }
                        }) {
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
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(kp.primary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .sheet(isPresented: $showExportShare) {
            if let url = exportFileURL {
                ActivityShareSheet(activityItems: [url])
            }
        }
    }
}

private struct KineticProgressSegmentedBar: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var selection: ProgressTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProgressTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                        HapticManager.selection()
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(ProgressFonts.semiBold(14))
                        .foregroundStyle(selection == tab ? kp.primary : kp.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selection == tab ? kp.surfaceContainerHighest : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(kp.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct KineticExercisesSubSegmentedBar: View {
    @Environment(\.kineticPalette) private var kp
    @Binding var selection: ExercisesProgressSubTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ExercisesProgressSubTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                        HapticManager.selection()
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(ProgressFonts.semiBold(14))
                        .foregroundStyle(selection == tab ? kp.primary : kp.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selection == tab ? kp.surfaceContainerHighest : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var viewModel: ProgressViewModel
    @Binding var showExerciseDetail: Bool
    @Binding var selectedExercise: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp

    private var isWide: Bool { horizontalSizeClass == .regular }
    
    private var improvementRows: [(exercise: String, percent: Int)] {
        viewModel.topImprovementPercentages(limit: 4)
    }
    
    private var maxImprovementPercent: Int {
        max(improvementRows.map(\.percent).max() ?? 1, 1)
    }
    
    private var kineticInsightBody: String {
        if let insight = viewModel.generateInsight() {
            return insight.message
        }
        return "Your strength trends and recovery signals will appear here as you log workouts and PRs."
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                Group {
                    if isWide {
                        HStack(alignment: .top, spacing: 16) {
                            streakColumn
                            workoutPairColumn
                        }
                    } else {
                        streakColumn
                        workoutPairColumn
                    }
                }
                
                kineticIntelligenceCard
                
                Group {
                    if isWide {
                        HStack(alignment: .top, spacing: 16) {
                            recentPRsPanel
                            topImprovementsPanel
                        }
                    } else {
                        recentPRsPanel
                        topImprovementsPanel
                    }
                }
                
                if viewModel.prs.isEmpty {
                    ProgressEmptyState(
                        icon: "trophy.fill",
                        title: "No PRs Yet",
                        message: "Complete a workout and crush some sets to earn your first personal record!",
                        primaryAction: nil,
                        secondaryAction: nil
                    )
                    .padding(.vertical, 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
    
    private var streakColumn: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Momentum")
                        .font(ProgressFonts.bold(10))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary.opacity(0.6))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(viewModel.currentStreak)")
                            .font(ProgressFonts.extraBold(48))
                            .foregroundStyle(kp.primary)
                            .kineticDisplayTracking(for: 48)
                        Text("days")
                            .font(ProgressFonts.medium(18))
                            .foregroundStyle(kp.tertiary)
                    }
                    Text("Current Day Streak")
                        .font(ProgressFonts.medium(12))
                        .foregroundStyle(kp.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(kp.surfaceContainerHighest)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(kp.primary.opacity(0.12))
                    .offset(x: 16, y: 16)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal Record")
                    .font(ProgressFonts.bold(10))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(viewModel.longestStreak)")
                        .font(ProgressFonts.extraBold(40))
                        .foregroundStyle(kp.onSurface)
                        .kineticDisplayTracking(for: 40)
                    Text("days")
                        .font(ProgressFonts.medium(16))
                        .foregroundStyle(kp.tertiary)
                }
                Text("Best Workout Streak")
                    .font(ProgressFonts.medium(12))
                    .foregroundStyle(kp.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(kp.surfaceContainerHigh)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(kp.outlineVariant.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    private var workoutPairColumn: some View {
        HStack(alignment: .top, spacing: 16) {
            workoutMetricCard(
                icon: "calendar",
                title: "Weekly Workouts",
                value: "\(viewModel.weeklyWorkouts)",
                iconTint: kp.secondary
            )
            workoutMetricCard(
                icon: "dumbbell.fill",
                title: "Total Workouts",
                value: "\(viewModel.workoutCount)",
                iconTint: kp.primary
            )
        }
    }
    
    private func workoutMetricCard(icon: String, title: String, value: String, iconTint: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(iconTint)
                Spacer(minLength: 0)
            }
            .padding(.bottom, 16)
            Text(title)
                .font(ProgressFonts.medium(14))
                .foregroundStyle(kp.tertiary)
            Spacer(minLength: 12)
            Text(value)
                .font(ProgressFonts.extraBold(48))
                .foregroundStyle(kp.onSurface)
                .kineticDisplayTracking(for: 48)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(minHeight: 160)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var kineticIntelligenceCard: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(kp.primary.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(kp.primary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Kinetic Intelligence")
                    .font(ProgressFonts.bold(18))
                    .foregroundStyle(kp.primary)
                Text(kineticInsightBody)
                    .font(ProgressFonts.medium(17))
                    .foregroundStyle(kp.onSurface.opacity(0.9))
                    .kineticBodyLineHeight()
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            kp.secondaryContainer.opacity(0.35),
                            kp.primaryContainer.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(kp.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    private var recentPRsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent PRs")
                    .font(ProgressFonts.bold(20))
                    .foregroundStyle(kp.onSurface)
                Spacer()
                Text("Last 7 Days")
                    .font(ProgressFonts.bold(10))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary)
            }
            
            if viewModel.recentPRs().isEmpty {
                Text("No PRs in the last week.")
                    .font(ProgressFonts.medium(14))
                    .foregroundStyle(kp.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recentPRs().prefix(5), id: \.id) { pr in
                        KineticOverviewPRRow(
                            pr: pr,
                            delta: viewModel.weightDeltaFromPreviousPR(for: pr)
                        )
                        .onTapGesture {
                            HapticManager.impact(style: .light)
                            selectedExercise = pr.exercise
                            showExerciseDetail = true
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var topImprovementsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Improvements")
                    .font(ProgressFonts.bold(20))
                    .foregroundStyle(kp.onSurface)
                Spacer()
                Text("Growth Ratio")
                    .font(ProgressFonts.bold(10))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(kp.tertiary)
            }
            
            if improvementRows.isEmpty {
                Text("Log at least two PRs per exercise to see improvement percentages.")
                    .font(ProgressFonts.medium(14))
                    .foregroundStyle(kp.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 20) {
                    ForEach(improvementRows, id: \.exercise) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(row.exercise)
                                    .font(ProgressFonts.medium(14))
                                    .foregroundStyle(kp.onSurface)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(row.percent)%")
                                    .font(ProgressFonts.medium(14))
                                    .foregroundStyle(kp.secondary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(kp.surfaceContainerHighest)
                                    Capsule()
                                        .fill(kp.secondary)
                                        .frame(width: max(0, geo.size.width * CGFloat(row.percent) / CGFloat(maxImprovementPercent)))
                                        .shadow(color: kp.secondary.opacity(0.45), radius: 8, x: 0, y: 0)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kp.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct KineticOverviewPRRow: View {
    @Environment(\.kineticPalette) private var kp
    let pr: PersonalRecord
    let delta: Int?

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()
    
    private var whenLabel: String {
        KineticOverviewPRRow.relativeFormatter.localizedString(for: pr.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise)
                    .font(ProgressFonts.medium(17))
                    .foregroundStyle(kp.onSurface)
                Text(whenLabel)
                    .font(ProgressFonts.medium(12))
                    .foregroundStyle(kp.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(pr.weight)) lbs")
                    .font(ProgressFonts.bold(18))
                    .foregroundStyle(kp.primary)
                if let delta {
                    Text("+\(delta) lbs")
                        .font(ProgressFonts.bold(10))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.primary.opacity(0.75))
                }
            }
        }
        .padding(16)
        .background(kp.surfaceContainerHighest.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    @Binding var exercisesSubTab: ExercisesProgressSubTab

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.kineticPalette) private var kp

    private var filteredExercises: [String] {
        var exercises = viewModel.availableExercises
        
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        exercises = exercises.filter { exercise in
            let prs = viewModel.prsForExercise(exercise)
            return prs.contains { filters.matches($0) }
        }
        
        return exercises
    }
    
    var body: some View {
        VStack(spacing: 0) {
            KineticExercisesSubSegmentedBar(selection: $exercisesSubTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            Group {
                switch exercisesSubTab {
                case .stats:
                    exercisesStatsPane
                case .exercises:
                    exercisesBrowsePane
                case .records:
                    exercisesRecordsPane
                }
            }
        }
    }
    
    // MARK: Sub-tab: Stats (summary)
    
    private var exercisesStatsPane: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    KineticExerciseStatTile(
                        title: "Total PRs",
                        value: "\(viewModel.prs.count)",
                        accent: kp.primary
                    )
                    KineticExerciseStatTile(
                        title: "Exercises",
                        value: "\(viewModel.availableExercises.count)",
                        accent: kp.secondary
                    )
                    KineticExerciseStatTile(
                        title: "PRs This Month",
                        value: "\(viewModel.monthlyPRs)",
                        accent: kp.primary
                    )
                    KineticExerciseStatTile(
                        title: "Current Streak",
                        value: "\(viewModel.currentStreak)d",
                        accent: kp.secondary
                    )
                }
                .padding(.horizontal, 16)
                
                if let insight = viewModel.generateInsight() {
                    InsightCard(insight: insight)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: Sub-tab: Exercises (search + cards)
    
    private var exercisesBrowsePane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(kp.outline)
                        .padding(.leading, 16)
                    TextField("Search exercises...", text: $searchText)
                        .font(ProgressFonts.medium(16))
                        .foregroundStyle(kp.onSurface)
                        .padding(.vertical, 14)
                        .padding(.trailing, 12)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(kp.outline)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .background(kp.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                Button {
                    HapticManager.impact(style: .light)
                    showFilterSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(kp.surfaceContainerLow)
                            .frame(width: 56, height: 56)
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(kp.onSurface)
                        if filters.isActive {
                            Circle()
                                .fill(kp.primary)
                                .frame(width: 8, height: 8)
                                .padding(10)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            ScrollView {
                LazyVStack(spacing: 16) {
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            let prsForExercise = viewModel.prsForExercise(exercise)
                            let currentPR = prsForExercise.first
                            KineticExerciseProgressCard(
                                exercise: exercise,
                                currentPR: currentPR,
                                prCount: prsForExercise.count,
                                prHistory: prsForExercise,
                                isWideLayout: horizontalSizeClass == .regular
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.impact(style: .light)
                                selectedExercise = exercise
                                showExerciseDetail = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    for pr in prsForExercise {
                                        viewModel.deletePR(pr)
                                    }
                                } label: {
                                    Label("Delete All PRs for \(exercise)", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: Sub-tab: Records (chronological PRs)
    
    private var exercisesRecordsPane: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.prs.isEmpty {
                    Text("No PR records yet.")
                        .font(ProgressFonts.medium(15))
                        .foregroundStyle(kp.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                }
                ForEach(viewModel.prs.sorted { $0.date > $1.date }) { pr in
                    Button {
                        HapticManager.impact(style: .light)
                        selectedExercise = pr.exercise
                        showExerciseDetail = true
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pr.exercise)
                                    .font(ProgressFonts.semiBold(16))
                                    .foregroundStyle(kp.onSurface)
                                    .lineLimit(1)
                                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(ProgressFonts.medium(13))
                                    .foregroundStyle(kp.tertiary)
                            }
                            Spacer()
                            Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                                .font(ProgressFonts.bold(15))
                                .foregroundStyle(kp.primary)
                        }
                        .padding(16)
                        .background(kp.surfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Kinetic exercise cards (Exercises progress)

private struct KineticExerciseStatTile: View {
    @Environment(\.kineticPalette) private var kp
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(accent.opacity(0.5))
                .frame(width: 28, height: 4)
            Text(title)
                .font(ProgressFonts.medium(14))
                .foregroundStyle(kp.tertiary)
            Text(value)
                .font(ProgressFonts.extraBold(28))
                .foregroundStyle(kp.onSurface)
                .kineticDisplayTracking(for: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct KineticExerciseProgressCard: View {
    @Environment(\.kineticPalette) private var kp
    let exercise: String
    let currentPR: PersonalRecord?
    let prCount: Int
    let prHistory: [PersonalRecord]
    let isWideLayout: Bool

    private static let lastPerformedFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    private var category: (label: String, useSecondary: Bool) {
        let (primary, _) = ExerciseDataManager.shared.getMuscleGroups(for: exercise)
        let p = (primary.first ?? "").lowercased()
        if p.contains("chest") || p.contains("pectoral") {
            return ("Chest", true)
        }
        return ("Strength", false)
    }
    
    private var sparklineHeights: [CGFloat] {
        let sorted = prHistory.sorted { $0.date < $1.date }
        let last = Array(sorted.suffix(6))
        let volumes = last.map { $0.weight * Double($0.reps) }
        guard let maxV = volumes.max(), maxV > 0, !volumes.isEmpty else {
            return Array(repeating: 0.28, count: 6)
        }
        var normalized = volumes.map { CGFloat($0 / maxV) }
        while normalized.count < 6 {
            normalized.insert(0.12, at: 0)
        }
        return Array(normalized.suffix(6))
    }
    
    private var accent: Color {
        category.useSecondary ? kp.secondary : kp.primary
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text("PR")
                .font(ProgressFonts.extraBold(64))
                .foregroundStyle(kp.onSurface.opacity(0.08))
                .padding(16)
                .accessibilityHidden(true)
            
            Group {
                if isWideLayout {
                    HStack(alignment: .top, spacing: 20) {
                        exerciseThumbnail
                        exerciseDetails
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        exerciseThumbnail
                            .frame(maxWidth: .infinity)
                        exerciseDetails
                    }
                }
            }
            .padding(16)
        }
        .background(kp.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(kp.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var exerciseThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(kp.surfaceContainerLow)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.categoryGradient(for: exercise))
                .opacity(0.22)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(accent.opacity(0.95))
        }
        .frame(width: isWideLayout ? 128 : nil, height: 128)
        .frame(maxWidth: isWideLayout ? 128 : .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private var exerciseDetails: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(exercise)
                    .font(ProgressFonts.bold(20))
                    .foregroundStyle(kp.onSurface)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(category.label)
                    .font(ProgressFonts.bold(10))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .padding(.bottom, 4)
            
            if let date = currentPR?.date {
                Text("Last performed: \(Self.lastPerformedFormatter.string(from: date))")
                    .font(ProgressFonts.medium(14))
                    .foregroundStyle(kp.tertiary)
                    .padding(.bottom, 16)
            } else {
                Text("No PR logged yet")
                    .font(ProgressFonts.medium(14))
                    .foregroundStyle(kp.tertiary)
                    .padding(.bottom, 16)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Record")
                        .font(ProgressFonts.bold(10))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.outline)
                    if let pr = currentPR {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(pr.weight))")
                                .font(ProgressFonts.extraBold(28))
                                .foregroundStyle(kp.onSurface)
                            Text("lbs")
                                .font(ProgressFonts.medium(14))
                                .foregroundStyle(kp.tertiary)
                        }
                    } else {
                        Text("—")
                            .font(ProgressFonts.extraBold(28))
                            .foregroundStyle(kp.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PR Count")
                        .font(ProgressFonts.bold(10))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.outline)
                    Text(String(format: "%02d", min(prCount, 99)))
                        .font(ProgressFonts.extraBold(28))
                        .foregroundStyle(kp.onSurface)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(ProgressFonts.bold(10))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(kp.outline)
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<sparklineHeights.count, id: \.self) { i in
                            let h = sparklineHeights[i]
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(accent.opacity(0.2 + Double(h) * 0.75))
                                .frame(maxWidth: .infinity)
                                .frame(height: max(4, 40 * h))
                        }
                    }
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Stats Tab

struct StatsTab: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Progress Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    // Grid of stat pills
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
