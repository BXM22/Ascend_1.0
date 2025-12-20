# Progress View Redesign - Implementation Plan

## Overview
Comprehensive UI/UX overhaul of the Progress View in the Ascend iOS workout app, inspired by the successful Templates View redesign. This redesign focuses on segmented content organization, tap-to-preview interactions, enhanced filtering, and improved visual hierarchy while preserving all existing functionality.

## Design Philosophy

Following the **Templates View redesign** approach:
- ✅ **Segmented content** (reduce scroll depth, organize complexity)
- ✅ **Tap-to-preview** interactions (medium detent sheets for quick views)
- ✅ **Consolidated settings** (cleaner header, overflow menus)
- ✅ **Smart filtering** (muscle groups, time periods, intensity)
- ✅ **Enhanced empty states** (contextual messaging, actionable CTAs)
- ✅ **Rich exercise cards** (preview current PR, trends, metadata)
- ✅ **Swipe actions** (quick operations without menus)

---

## Current State Analysis

### **Existing Features**
- PR tracking with automatic detection during workouts
- Streak calculation (current streak, longest streak)
- Workout count and volume statistics
- PR trend charts for selected exercise
- Exercise picker with body part filters
- PR history with improvement indicators
- Manual PR deletion
- Week/month view toggle (currently unclear usage)

### **Current Layout**
1. Header (Help, Settings, Week/Month toggle)
2. Stat cards row (Streak, Workout Count)
3. Charts header
4. Trend graphs section (line chart)
5. Exercise PR tracker (picker button + current PR card)
6. PR history list
7. View all PRs button

### **Pain Points Identified**
- 🔴 **Sparse content**: Lots of vertical scrolling for limited data
- 🔴 **Hidden features**: PR history below fold, requires scrolling
- 🔴 **Navigation friction**: Too many taps to see exercise details
- 🔴 **Limited filtering**: Only search/filter in PRHistoryView
- 🔴 **Week/month toggle unclear**: Purpose not immediately obvious
- 🔴 **No comparisons**: Can't compare PRs across exercises
- 🔴 **Missing insights**: No AI-generated patterns or recommendations
- 🔴 **Basic empty states**: Generic messaging, limited guidance

---

## Redesign Strategy

### **PHASE 1: Header Redesign**

**Before:**
```
[Help] [Settings] [Week/Month ▼]
```

**After:**
```swift
HStack {
    Text("Progress")
        .font(AppTypography.largeTitleBold)
        .foregroundStyle(LinearGradient.primaryGradient)
    
    Spacer()
    
    HStack(spacing: 12) {
        HelpButton(pageType: .progress)
        
        Menu {
            Section("Time Period") {
                Button("This Week") { selectedPeriod = .week }
                Button("This Month") { selectedPeriod = .month }
                Button("This Year") { selectedPeriod = .year }
                Button("All Time") { selectedPeriod = .allTime }
            }
            
            Section {
                Button("Export Data") { showExportSheet = true }
                Button("Set Goals") { showGoalsView = true }
                Button("Settings") { showSettings = true }
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
```

**Benefits:**
- Consolidated 3 buttons → 1 overflow menu
- Clearer time period selection with labels
- Room for future features (export, goals)
- Follows iOS design patterns

---

### **PHASE 2: Segmented Content Organization**

**New 3-Tab Layout:**

```swift
enum ProgressTab: String, CaseIterable {
    case overview = "Overview"
    case exercises = "Exercises"
    case stats = "Stats"
    
    var icon: String {
        switch self {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .exercises: return "figure.strengthtraining.traditional"
        case .stats: return "chart.bar.fill"
        }
    }
}
```

#### **Tab 1: Overview** (Glanceable summary)

```swift
ScrollView {
    LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
        // Stat Cards (redesigned)
        HStack(spacing: 12) {
            EnhancedStatCard(
                icon: "flame.fill",
                gradient: AppColors.armsGradient,
                primaryValue: "\(currentStreak)",
                primaryLabel: "Day Streak",
                secondaryValue: "Best: \(longestStreak)",
                secondaryLabel: "Personal Best"
            )
            
            EnhancedStatCard(
                icon: "chart.bar.fill",
                gradient: AppColors.backGradient,
                primaryValue: "\(weeklyWorkouts)",
                primaryLabel: "This Week",
                secondaryValue: "\(totalWorkouts) Total",
                secondaryLabel: "All Time"
            )
        }
        
        // Recent PRs Section
        SectionHeader(title: "Recent PRs", subtitle: "Last 7 days")
        
        ForEach(recentPRs, id: \.id) { pr in
            RecentPRCard(pr: pr)
                .onTapGesture {
                    selectedExercise = pr.exercise
                    showExerciseDetail = true
                }
        }
        
        // Top Exercises
        SectionHeader(title: "Top Exercises", subtitle: "Most improved")
        
        HStack(spacing: 12) {
            ForEach(topExercises.prefix(3), id: \.exercise) { item in
                TopExerciseCard(
                    exercise: item.exercise,
                    prCount: item.prCount,
                    gradient: categoryGradient(for: item.exercise)
                )
                .onTapGesture {
                    selectedExercise = item.exercise
                    showExerciseDetail = true
                }
            }
        }
        
        // Quick Insights
        if let insight = generateInsight() {
            InsightCard(insight: insight)
        }
        
        // Weekly Activity Calendar
        WeeklyActivityCalendar(workoutDates: workoutDates)
    }
    .padding(.horizontal, 20)
}
```

#### **Tab 2: Exercises** (Core PR tracking)

```swift
VStack(spacing: 0) {
    // Search & Filter Bar
    HStack(spacing: 12) {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.mutedForeground)
            TextField("Search exercises", text: $searchText)
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
        
        Button(action: { showFilterSheet = true }) {
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
    
    // Exercise List
    ScrollView {
        LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
            if viewMode == .grouped {
                // Grouped by muscle group
                ForEach(groupedExercises.keys.sorted(), id: \.self) { group in
                    Section {
                        ForEach(groupedExercises[group] ?? [], id: \.self) { exercise in
                            ExercisePreviewCard(
                                exercise: exercise,
                                currentPR: currentPR(for: exercise),
                                prCount: prCount(for: exercise),
                                lastPerformed: lastPerformed(for: exercise),
                                trend: calculateTrend(for: exercise)
                            )
                            .onTapGesture {
                                selectedExercise = exercise
                                showExerciseDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteAllPRs(for: exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    showManualPREntry(for: exercise)
                                } label: {
                                    Label("Add PR", systemImage: "plus.circle")
                                }
                                .tint(AppColors.accent)
                            }
                        }
                    } header: {
                        GroupedSectionHeader(
                            group: group,
                            count: groupedExercises[group]?.count ?? 0,
                            isExpanded: expandedGroups.contains(group)
                        )
                        .onTapGesture {
                            withAnimation(.smooth) {
                                toggleGroup(group)
                            }
                        }
                    }
                }
            } else {
                // List view
                ForEach(filteredExercises, id: \.self) { exercise in
                    ExercisePreviewCard(...)
                }
            }
            
            if filteredExercises.isEmpty {
                EnhancedEmptyState(
                    icon: "magnifyingglass",
                    title: searchText.isEmpty ? "No PRs Yet" : "No exercises found",
                    message: searchText.isEmpty ? 
                        "Complete a workout and crush some sets to earn your first personal record!" :
                        "Try adjusting your filters or search terms",
                    primaryAction: searchText.isEmpty ?
                        EmptyStateAction(title: "Start Workout", action: navigateToWorkout) :
                        EmptyStateAction(title: "Clear Filters", action: clearFilters)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}
```

#### **Tab 3: Stats** (Analytics & visualizations)

```swift
ScrollView {
    LazyVStack(spacing: 24) {
        // Progress Summary Card
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 22, weight: .bold))
            
            // Grid of stat pills
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatPill(
                    value: "\(totalPRs)",
                    label: "Total PRs",
                    gradient: LinearGradient.primaryGradient
                )
                StatPill(
                    value: "\(prThisMonth)",
                    label: "This Month",
                    gradient: LinearGradient.accentGradient
                )
                StatPill(
                    value: "+\(avgWeightIncrease)%",
                    label: "Avg Gain",
                    gradient: AppColors.chestGradient
                )
                StatPill(
                    value: "\(daysActive)",
                    label: "Days Active",
                    gradient: AppColors.armsGradient
                )
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        
        // PR Trend Chart (selected exercise)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PR Progression")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { showExercisePicker = true }) {
                    HStack(spacing: 4) {
                        Text(selectedExercise.isEmpty ? "Select exercise" : selectedExercise)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            
            if !selectedExercise.isEmpty {
                PRTrendChart(prs: selectedExercisePRs)
                    .frame(height: 200)
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        
        // Muscle Group Distribution
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Group Focus")
                .font(.system(size: 18, weight: .semibold))
            
            MuscleGroupDistributionChart(prs: prs)
                .frame(height: 250)
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        
        // Volume Progression
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume Trend")
                .font(.system(size: 18, weight: .semibold))
            
            VolumeTrendChart(workoutHistory: workoutHistory)
                .frame(height: 180)
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    .padding(.horizontal, 20)
}
```

---

### **PHASE 3: Enhanced Exercise Cards**

```swift
struct ExercisePreviewCard: View {
    let exercise: String
    let currentPR: PersonalRecord?
    let prCount: Int
    let lastPerformed: Date?
    let trend: TrendIndicator
    
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: exercise)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Muscle group icon with gradient background
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24))
                    .foregroundStyle(gradient)
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                if let pr = currentPR {
                    HStack(spacing: 6) {
                        Text("\(Int(pr.weight)) lbs × \(pr.reps)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(gradient)
                        
                        trend.icon
                            .font(.system(size: 12))
                            .foregroundColor(trend.color)
                    }
                }
                
                if let date = lastPerformed {
                    Text(date, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            Spacer()
            
            // PR count badge
            VStack(spacing: 2) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(gradient)
                
                Text("\(prCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

enum TrendIndicator {
    case improving, stable, declining, new
    
    var icon: Image {
        switch self {
        case .improving: return Image(systemName: "arrow.up.right")
        case .stable: return Image(systemName: "arrow.right")
        case .declining: return Image(systemName: "arrow.down.right")
        case .new: return Image(systemName: "sparkles")
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return AppColors.success
        case .stable: return AppColors.mutedForeground
        case .declining: return AppColors.destructive
        case .new: return AppColors.accent
        }
    }
}
```

---

### **PHASE 4: Exercise Detail Sheet** (Tap-to-preview)

```swift
struct ExerciseDetailSheet: View {
    let exercise: String
    @ObservedObject var viewModel: ProgressViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showManualPREntry = false
    
    var gradient: LinearGradient {
        AppColors.categoryGradient(for: exercise)
    }
    
    var currentPR: PersonalRecord? {
        viewModel.currentPR(for: exercise)
    }
    
    var prs: [PersonalRecord] {
        viewModel.prsForExercise(exercise)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(gradient.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(gradient)
                        }
                        
                        Text(exercise)
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        // Metadata badges
                        HStack(spacing: 12) {
                            MetadataBadge(
                                icon: "trophy.fill",
                                text: "\(prs.count) PRs"
                            )
                            
                            if let lastDate = prs.first?.date {
                                MetadataBadge(
                                    icon: "calendar",
                                    text: lastDate.formatted(.relative(presentation: .named))
                                )
                            }
                            
                            MetadataBadge(
                                icon: "chart.line.uptrend.xyaxis",
                                text: calculateTrend(for: exercise).label
                            )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Current PR Card (large display)
                    if let pr = currentPR {
                        CurrentPRCard(pr: pr, gradient: gradient)
                    }
                    
                    // PR Trend Chart (inline)
                    if prs.count >= 2 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PR Progression")
                                .font(.system(size: 18, weight: .semibold))
                            
                            PRTrendChart(prs: prs)
                                .frame(height: 200)
                        }
                        .padding(20)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // PR History List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PR History")
                            .font(.system(size: 18, weight: .semibold))
                        
                        ForEach(Array(prs.enumerated()), id: \.element.id) { index, pr in
                            let previousPR = index < prs.count - 1 ? prs[index + 1] : nil
                            
                            PRHistoryRow(
                                pr: pr,
                                previousPR: previousPR,
                                gradient: gradient
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deletePR(pr)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: { showManualPREntry = true }) {
                            Label("Add Manual PR", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: shareProgress) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Set Goal", action: { /* ... */ })
                        Button("View in Workout History", action: { /* ... */ })
                        Divider()
                        Button("Delete All PRs", role: .destructive, action: {
                            showDeleteConfirmation = true
                        })
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showManualPREntry) {
                ManualPREntrySheet(
                    exercise: exercise,
                    viewModel: viewModel
                )
            }
            .alert("Delete All PRs?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllPRs()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete all \(prs.count) personal records for \(exercise). This action cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
```

---

### **PHASE 5: PR Filter Sheet**

```swift
struct PRFilters {
    var timeRange: TimeRange = .allTime
    var muscleGroups: Set<String> = []
    var minWeight: Double? = nil
    var sortOrder: SortOrder = .dateDescending
    
    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case allTime = "All Time"
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case weightDescending = "Highest Weight"
        case improvementDescending = "Biggest Gains"
        case alphabetical = "A-Z"
    }
    
    var isActive: Bool {
        timeRange != .allTime || !muscleGroups.isEmpty || minWeight != nil
    }
}

struct PRFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: PRFilters
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Period") {
                    Picker("Range", selection: $filters.timeRange) {
                        ForEach(PRFilters.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Muscle Groups") {
                    FlowLayout(spacing: 8) {
                        ForEach(["Chest", "Back", "Legs", "Arms", "Core", "Cardio"], id: \.self) { group in
                            FilterChip(
                                title: group,
                                isSelected: filters.muscleGroups.contains(group),
                                gradient: AppColors.categoryGradient(for: group)
                            ) {
                                if filters.muscleGroups.contains(group) {
                                    filters.muscleGroups.remove(group)
                                } else {
                                    filters.muscleGroups.insert(group)
                                }
                            }
                        }
                    }
                }
                
                Section("Weight") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("0", value: $filters.minWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("lbs")
                    }
                }
                
                Section("Sort By") {
                    Picker("Order", selection: $filters.sortOrder) {
                        ForEach(PRFilters.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
            }
            .navigationTitle("Filter PRs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation(.smooth) {
                            filters = PRFilters()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
```

---

### **PHASE 6: Enhanced Empty States**

```swift
struct EnhancedEmptyState: View {
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
            VStack(spacing: 12) {
                if let primary = primaryAction {
                    Button(action: primary.action) {
                        Text(primary.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryGradientButtonStyle())
                }
                
                if let secondary = secondaryAction {
                    Button(action: secondary.action) {
                        Text(secondary.title)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

struct EmptyStateAction {
    let title: String
    let action: () -> Void
}
```

---

### **PHASE 7: Progress Insights**

```swift
enum ProgressInsight {
    case onFire(prCount: Int)
    case consistent(streak: Int)
    case improving(percentage: Double)
    case needsAttention(exercise: String)
    case milestone(achievement: String)
    
    var icon: String {
        switch self {
        case .onFire: return "flame.fill"
        case .consistent: return "calendar.badge.checkmark"
        case .improving: return "chart.line.uptrend.xyaxis"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .milestone: return "star.fill"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .onFire: return LinearGradient.primaryGradient
        case .consistent: return AppColors.accentGradient
        case .improving: return AppColors.chestGradient
        case .needsAttention: return AppColors.destructiveGradient
        case .milestone: return LinearGradient.goldGradient
        }
    }
    
    var title: String {
        switch self {
        case .onFire: return "You're on Fire!"
        case .consistent: return "Great Consistency"
        case .improving: return "Keep It Up!"
        case .needsAttention: return "Time to Challenge?"
        case .milestone: return "Achievement Unlocked!"
        }
    }
    
    var message: String {
        switch self {
        case .onFire(let count):
            return "\(count) PRs this week! Your hard work is paying off."
        case .consistent(let streak):
            return "\(streak) day streak. Consistency is the key to progress."
        case .improving(let percentage):
            return "You're \(Int(percentage))% stronger this month. Incredible gains!"
        case .needsAttention(let exercise):
            return "No PRs in \(exercise) for 2 weeks. Time to push harder?"
        case .milestone(let achievement):
            return achievement
        }
    }
}

struct InsightCard: View {
    let insight: ProgressInsight
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.gradient.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(insight.gradient)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(insight.message)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 8)
    }
}

// Generate insights based on PR data
func generateInsight() -> ProgressInsight? {
    let recentPRs = prs.filter { $0.date > Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
    
    if recentPRs.count >= 3 {
        return .onFire(prCount: recentPRs.count)
    }
    
    if currentStreak >= 5 {
        return .consistent(streak: currentStreak)
    }
    
    let thisMonth = prs.filter { $0.date > Calendar.current.date(byAdding: .month, value: -1, to: Date())! }
    let lastMonth = prs.filter {
        $0.date > Calendar.current.date(byAdding: .month, value: -2, to: Date())! &&
        $0.date < Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    }
    
    if !thisMonth.isEmpty && !lastMonth.isEmpty {
        let thisMonthAvg = thisMonth.map { $0.weight * Double($0.reps) }.reduce(0, +) / Double(thisMonth.count)
        let lastMonthAvg = lastMonth.map { $0.weight * Double($0.reps) }.reduce(0, +) / Double(lastMonth.count)
        let improvement = ((thisMonthAvg - lastMonthAvg) / lastMonthAvg) * 100
        
        if improvement > 5 {
            return .improving(percentage: improvement)
        }
    }
    
    // Check for exercises without recent PRs
    let exerciseLastPRs = Dictionary(grouping: prs, by: { $0.exercise })
        .mapValues { $0.max(by: { $0.date < $1.date })! }
    
    for (exercise, lastPR) in exerciseLastPRs {
        if lastPR.date < Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())! {
            return .needsAttention(exercise: exercise)
        }
    }
    
    return nil
}
```

---

## Key Files to Create/Modify

### **New Component Files:**
1. `ExerciseDetailSheet.swift` - Exercise drill-down with inline charts
2. `PRFilterSheet.swift` - Advanced filtering interface
3. `ExercisePreviewCard.swift` - Rich exercise list cards
4. `CurrentPRCard.swift` - Large PR display in detail sheet
5. `PRHistoryRow.swift` - History item with improvement indicators
6. `InsightCard.swift` - AI-generated progress insights
7. `ManualPREntrySheet.swift` - Manual PR entry form
8. `EnhancedStatCard.swift` - Redesigned stat cards
9. `SectionHeader.swift` - Reusable section headers
10. `MetadataBadge.swift` - Icon + text badge component

### **Modified Files:**
1. `ProgressView.swift` - Complete redesign with segments
2. `ProgressViewModel.swift` - Add filtering, trends, insights
3. `PRHistoryView.swift` - Enhanced with filters
4. `PRTrendChart.swift` - Inline chart variant

---

## Implementation Checklist

### **Week 1: Foundation**
- [ ] Create segment control with 3 tabs
- [ ] Redesign header with consolidated menu
- [ ] Implement enhanced stat cards
- [ ] Create SectionHeader component

### **Week 2: Exercise Cards & Detail**
- [ ] Build ExercisePreviewCard component
- [ ] Implement TrendIndicator logic
- [ ] Create ExerciseDetailSheet
- [ ] Add swipe actions (delete, add PR)

### **Week 3: Filtering & Search**
- [ ] Create PRFilterSheet component
- [ ] Implement PRFilters data model
- [ ] Add filter badge indicator
- [ ] Wire up filter logic in ViewModel

### **Week 4: Stats Tab**
- [ ] Build progress summary card
- [ ] Add muscle group distribution chart
- [ ] Create volume trend chart
- [ ] Implement exercise comparison

### **Week 5: Insights & Polish**
- [ ] Create InsightCard component
- [ ] Implement insight generation algorithm
- [ ] Add manual PR entry
- [ ] Build enhanced empty states

### **Week 6: Accessibility & Testing**
- [ ] Add VoiceOver labels/hints
- [ ] Test Dynamic Type support
- [ ] Implement haptic feedback
- [ ] Performance testing
- [ ] Bug fixes

---

## Success Metrics

- ✅ **Navigation depth reduced** from 3-4 taps to 1-2 taps
- ✅ **Content discoverability** improved with segmented layout
- ✅ **Filtering capabilities** enhanced (time, muscle group, weight, sort)
- ✅ **Visual hierarchy** clearer with redesigned cards
- ✅ **Empty states** provide actionable guidance
- ✅ **Insights** offer personalized recommendations
- ✅ **Accessibility** comprehensive VoiceOver support

---

## Future Enhancements

### **Phase 2 Features:**
1. **Goal Tracking**: Set target PRs, track progress toward goals
2. **PR Comparison**: Side-by-side comparison of multiple exercises
3. **Export/Share**: Generate shareable PR summaries
4. **Template from PRs**: Create workout template from top exercises
5. **PR Predictions**: AI-powered PR predictions based on trends
6. **Workout Correlation**: Analyze which workout splits yield most PRs
7. **Rest Days Impact**: Correlate rest days with PR frequency
8. **Volume Tracking**: Track total volume progression over time

---

## Design Decisions

### **Why Segmented Tabs?**
- Reduces scroll depth (no scrolling through unrelated content)
- Clear mental model (Overview → Exercises → Stats)
- Improves performance (only render active tab)
- Scalable for future additions

### **Why Tap-to-Preview?**
- Faster access to exercise details (1 tap vs 2-3 taps)
- Medium detent allows quick view without navigation
- Matches successful Templates View pattern
- Preserves context (can dismiss easily)

### **Why Enhanced Insights?**
- Provides actionable recommendations
- Increases engagement and motivation
- Personalizes the experience
- Guides users toward better training decisions

### **Why Rich Exercise Cards?**
- Shows critical info at a glance (current PR, trend, last performed)
- Reduces need to tap into detail for quick checks
- Visual indicators (trend arrows, gradients) improve scanability
- Consistent with modern iOS design patterns

---

## Conclusion

This redesign transforms the Progress View from a **linear scroll-heavy interface** into a **segmented, data-rich experience** with:

✅ **Better Organization**: 3 focused tabs instead of single scroll  
✅ **Improved Discovery**: Tap-to-preview cards, smart filtering  
✅ **Richer Insights**: AI-generated recommendations, trend analysis  
✅ **Enhanced Visual Hierarchy**: Consistent card design, clear typography  
✅ **Superior Accessibility**: Full VoiceOver, Dynamic Type support  
✅ **Maintained Performance**: All optimizations preserved, new ones added

The redesign follows the successful **Templates View** pattern while addressing the unique needs of progress tracking and PR management.
