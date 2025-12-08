import SwiftUI
import Charts

struct ExerciseHistoryView: View {
    let exerciseName: String
    let progressViewModel: ProgressViewModel?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var workoutHistoryManager = WorkoutHistoryManager.shared
    
    private var exerciseHistory: [ExerciseSetData] {
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
        return sets.sorted { $0.date > $1.date }
    }
    
    private var prs: [PersonalRecord] {
        progressViewModel?.prs.filter { $0.exercise == exerciseName } ?? []
    }
    
    private var chartData: [ChartDataPoint] {
        exerciseHistory.map { set in
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
                        
                        Text("\(exerciseHistory.count) sets completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
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

