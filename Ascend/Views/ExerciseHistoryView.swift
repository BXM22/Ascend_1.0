import SwiftUI
import Charts

struct ExerciseHistoryView: View {
    let exerciseName: String
    let progressViewModel: ProgressViewModel?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutHistoryManager = WorkoutHistoryManager.shared
    
    // Cache computed values to avoid recalculation on every render
    @State private var cachedExerciseHistory: [ExerciseSetData] = []
    @State private var cachedPRs: [PersonalRecord] = []
    @State private var cachedChartData: [ChartDataPoint] = []
    @State private var isLoading: Bool = true
    @State private var loadError: Error?
    
    private var exerciseHistory: [ExerciseSetData] {
        cachedExerciseHistory
    }
    
    private var prs: [PersonalRecord] {
        cachedPRs
    }
    
    private var chartData: [ChartDataPoint] {
        cachedChartData
    }
    
    // Collapsible chart sections
    @State private var showPRChart: Bool = true
    @State private var showWeightChart: Bool = true
    
    private func loadExerciseHistory() {
        // Check cache first
        if let cached = CardDetailCacheManager.shared.getCachedExerciseHistory(exerciseName) {
            cachedExerciseHistory = cached.history
            cachedPRs = cached.prs
            cachedChartData = cached.chartData
            isLoading = false
            return
        }
        
        isLoading = true
        loadError = nil
        
        // Capture values needed for background processing
        let exerciseNameToLoad = exerciseName
        let workoutsToProcess = workoutHistoryManager.completedWorkouts
        let progressPRs = progressViewModel?.prs
        
        // Load on background queue for better performance
        DispatchQueue.global(qos: .userInitiated).async {
            // Get all workouts containing this exercise
            let workouts = workoutsToProcess
                .filter { workout in
                    workout.exercises.contains { $0.name == exerciseNameToLoad }
                }
            
            // Extract all sets for this exercise
            var sets: [ExerciseSetData] = []
            for workout in workouts {
                if let exercise = workout.exercises.first(where: { $0.name == exerciseNameToLoad }) {
                    for set in exercise.sets where !set.isDropset {
                        sets.append(ExerciseSetData(
                            date: workout.startDate,
                            weight: set.weight,
                            reps: set.reps,
                            workoutName: workout.name
                        ))
                    }
                }
            }
            
            // Sort history for table / weight progression (newest first)
            let sortedHistory = sets.sorted { $0.date > $1.date }
            
            // Prefer explicitly tracked PRs when available
            let explicitPRs = progressPRs?.filter { $0.exercise == exerciseNameToLoad } ?? []
            let prs: [PersonalRecord]
            if !explicitPRs.isEmpty {
                prs = explicitPRs
            } else {
                // Derive PR milestones from historical sets so charts work with legacy data
                let ascendingHistory = sets.sorted { $0.date < $1.date }
                prs = ExerciseHistoryView.derivePRsFromHistory(ascendingHistory, exerciseName: exerciseNameToLoad)
            }
            
            // Update chart data from full history
            let chartData = sortedHistory.map { set in
                ChartDataPoint(
                    date: set.date,
                    weight: set.weight,
                    reps: set.reps,
                    volume: set.weight * Double(set.reps)
                )
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.cachedExerciseHistory = sortedHistory
                self.cachedPRs = prs
                self.cachedChartData = chartData
                self.isLoading = false
                
                // Cache the results
                CardDetailCacheManager.shared.cacheExerciseHistory(
                    exerciseNameToLoad,
                    history: sortedHistory,
                    prs: prs,
                    chartData: chartData
                )
            }
        }
    }
    
    /// Derive a sequence of PR milestones from raw set history.
    /// This allows PR charts to render even for workouts logged before explicit PR tracking existed.
    private static func derivePRsFromHistory(_ history: [ExerciseSetData], exerciseName: String) -> [PersonalRecord] {
        var derived: [PersonalRecord] = []
        var bestWeight: Double = 0
        var bestReps: Int = 0
        
        for set in history {
            let weight = set.weight
            let reps = set.reps
            
            // Skip empty / placeholder sets
            if weight <= 0 || reps <= 0 {
                continue
            }
            
            let isBetter: Bool
            if derived.isEmpty {
                isBetter = true
            } else if weight > bestWeight {
                isBetter = true
            } else if weight == bestWeight && reps > bestReps {
                isBetter = true
            } else {
                isBetter = false
            }
            
            if isBetter {
                bestWeight = weight
                bestReps = reps
                derived.append(
                    PersonalRecord(
                        exercise: exerciseName,
                        weight: weight,
                        reps: reps,
                        date: set.date
                    )
                )
            }
        }
        
        return derived
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exerciseName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        if isLoading {
                            ShimmerView()
                                .frame(height: 16)
                                .frame(maxWidth: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if exerciseHistory.isEmpty {
                            Text("No sets completed yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                        } else {
                            Text("\(exerciseHistory.count) sets completed")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Loading State
                    if isLoading {
                        ExerciseHistoryPlaceholder()
                    }
                    
                    // Error State
                    if let error = loadError {
                        ErrorStateView(
                            message: "Failed to load exercise history",
                            error: error.localizedDescription,
                            onRetry: {
                                loadExerciseHistory()
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Empty State
                    if !isLoading && loadError == nil && exerciseHistory.isEmpty && prs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Text("No history yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            Text("Complete sets to see your progress here")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // PR Trend Chart (collapsible)
                    // Show as soon as at least one PR exists for this exercise
                    if !isLoading && !prs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPRChart.toggle()
                                }
                            }) {
                                HStack {
                                    Text("PR Progression")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showPRChart ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showPRChart {
                                Chart {
                                    ForEach(prs.sorted { $0.date < $1.date }, id: \.id) { pr in
                                        LineMark(
                                            x: .value("Date", pr.date, unit: .day),
                                            y: .value("Weight", pr.weight)
                                        )
                                        .foregroundStyle(LinearGradient.primaryGradient)
                                        .interpolationMethod(.catmullRom)
                                        .lineStyle(StrokeStyle(lineWidth: 3))
                                        
                                        PointMark(
                                            x: .value("Date", pr.date, unit: .day),
                                            y: .value("Weight", pr.weight)
                                        )
                                        .foregroundStyle(AppColors.accent)
                                        .symbolSize(100)
                                        .symbol {
                                            Image(systemName: "trophy.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.accent)
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let weight = value.as(Double.self) {
                                                Text("\(Int(weight)) lbs")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(AppColors.mutedForeground)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: max(1, prs.count / 5))) { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    }
                                }
                                .frame(height: 220)
                                .padding()
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // PR Section
                    if !isLoading && !prs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Records")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 20)
                            
                            ForEach(prs.sorted { $0.date > $1.date }.prefix(5), id: \.id) { pr in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(pr.weight)) lbs × \(pr.reps) reps")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.foreground)
                                        
                                        Text(pr.date, style: .date)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppColors.accent)
                                }
                                .padding()
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Weight Progression Chart (collapsible)
                    if !isLoading && !chartData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showWeightChart.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Weight Progression")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppColors.foreground)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showWeightChart ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.mutedForeground)
                                }
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if showWeightChart {
                                Chart {
                                    ForEach(chartData, id: \.date) { point in
                                        LineMark(
                                            x: .value("Date", point.date, unit: .day),
                                            y: .value("Weight", point.weight)
                                        )
                                        .foregroundStyle(AppColors.accent)
                                        .interpolationMethod(.catmullRom)
                                        
                                        PointMark(
                                            x: .value("Date", point.date, unit: .day),
                                            y: .value("Weight", point.weight)
                                        )
                                        .foregroundStyle(AppColors.accent)
                                        .symbolSize(50)
                                    }
                                }
                                .frame(height: 200)
                                .padding()
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    
                    // Recent Sets
                    if !isLoading && !exerciseHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sets")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 20)
                            
                            ForEach(Array(exerciseHistory.prefix(10).enumerated()), id: \.element.id) { index, set in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.foreground)
                                        
                                        Text(set.date, style: .date)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(set.workoutName)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.mutedForeground)
                                        .lineLimit(1)
                                }
                                .padding()
                                .background(AppColors.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .onAppear {
                loadExerciseHistory()
            }
            .onChange(of: workoutHistoryManager.completedWorkouts.count) { _, _ in
                // Invalidate cache when workouts change
                CardDetailCacheManager.shared.invalidateExerciseHistoryCache(exerciseName)
                loadExerciseHistory()
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

// MARK: - Supporting Data Structures
struct ExerciseSetData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
    let workoutName: String
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
    let volume: Double
}

