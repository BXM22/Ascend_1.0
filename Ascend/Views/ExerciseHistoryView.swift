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
        // Get all workouts containing this exercise
        let workouts = workoutHistoryManager.completedWorkouts
            .filter { workout in
                workout.exercises.contains { $0.name == exerciseName }
            }
        
        // Extract all sets for this exercise
        var sets: [ExerciseSetData] = []
        for workout in workouts {
            if let exercise = workout.exercises.first(where: { $0.name == exerciseName }) {
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
        cachedExerciseHistory = sets.sorted { $0.date > $1.date }
        
        // Prefer explicitly tracked PRs when available
        let explicitPRs = progressViewModel?.prs.filter { $0.exercise == exerciseName } ?? []
        if !explicitPRs.isEmpty {
            cachedPRs = explicitPRs
        } else {
            // Derive PR milestones from historical sets so charts work with legacy data
            let ascendingHistory = sets.sorted { $0.date < $1.date }
            cachedPRs = derivePRsFromHistory(ascendingHistory)
        }
        
        // Update chart data from full history
        cachedChartData = cachedExerciseHistory.map { set in
            ChartDataPoint(
                date: set.date,
                weight: set.weight,
                reps: set.reps,
                volume: set.weight * Double(set.reps)
            )
        }
    }
    
    /// Derive a sequence of PR milestones from raw set history.
    /// This allows PR charts to render even for workouts logged before explicit PR tracking existed.
    private func derivePRsFromHistory(_ history: [ExerciseSetData]) -> [PersonalRecord] {
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
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exerciseName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.foreground)
                        
                        if exerciseHistory.isEmpty {
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
                    
                    // Empty State
                    if exerciseHistory.isEmpty && prs.isEmpty {
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
                    if !prs.isEmpty {
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
                    if !prs.isEmpty {
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
                    if !chartData.isEmpty {
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
                    if !exerciseHistory.isEmpty {
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
                loadExerciseHistory()
            }
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

