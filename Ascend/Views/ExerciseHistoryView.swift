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
        
        // Sort by date (newest first)
        cachedExerciseHistory = sets.sorted { $0.date > $1.date }
        
        // Update PRs
        cachedPRs = progressViewModel?.prs.filter { $0.exercise == exerciseName } ?? []
        
        // Update chart data
        cachedChartData = cachedExerciseHistory.map { set in
            ChartDataPoint(
                date: set.date,
                weight: set.weight,
                reps: set.reps,
                volume: set.weight * Double(set.reps)
            )
        }
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
                    
                    // PR Trend Chart
                    if prs.count >= 2 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PR Progression")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 20)
                            
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
                    
                    // Weight Progression Chart
                    if !chartData.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weight Progression")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 20)
                            
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

