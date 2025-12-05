import SwiftUI
import Charts

// MARK: - Horizontal Scrolling Graphs Container
struct TrendGraphsView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // PR Trend Graph
                if !viewModel.selectedExercise.isEmpty && !viewModel.selectedExercisePRs.isEmpty {
                    PRTrendGraphView(viewModel: viewModel)
                }
                
                // Volume Trend Graph
                VolumeTrendGraphView(viewModel: viewModel)
                
                // Workout Frequency Graph
                WorkoutFrequencyGraphView(viewModel: viewModel)
                
                // Rep Trend Graph
                if !viewModel.selectedExercise.isEmpty && !viewModel.selectedExercisePRs.isEmpty {
                    RepTrendGraphView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - PR Trend Graph
struct PRTrendGraphView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var chartData: [PRDataPoint] {
        viewModel.selectedExercisePRs
            .sorted { $0.date < $1.date }
            .map { PRDataPoint(date: $0.date, weight: $0.weight) }
    }
    
    var body: some View {
        GraphCard(
            title: "PR Trend",
            subtitle: viewModel.selectedExercise,
            icon: "chart.line.uptrend.xyaxis"
        ) {
            if chartData.isEmpty {
                EmptyGraphView(message: "No PR data available")
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Weight", dataPoint.weight)
                        )
                        .foregroundStyle(AppColors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Weight", dataPoint.weight)
                        )
                        .foregroundStyle(AppColors.primary)
                        .symbolSize(60)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Rep Trend Graph
struct RepTrendGraphView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var chartData: [RepDataPoint] {
        viewModel.selectedExercisePRs
            .sorted { $0.date < $1.date }
            .map { RepDataPoint(date: $0.date, reps: $0.reps) }
    }
    
    var body: some View {
        GraphCard(
            title: "Rep Trend",
            subtitle: viewModel.selectedExercise,
            icon: "arrow.up.circle.fill"
        ) {
            if chartData.isEmpty {
                EmptyGraphView(message: "No rep data available")
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Reps", dataPoint.reps)
                        )
                        .foregroundStyle(AppColors.accent)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Reps", dataPoint.reps)
                        )
                        .foregroundStyle(AppColors.accent)
                        .symbolSize(60)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Volume Trend Graph
struct VolumeTrendGraphView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var chartData: [VolumeDataPoint] {
        viewModel.weeklyVolumeData
    }
    
    var body: some View {
        GraphCard(
            title: "Volume Trend",
            subtitle: "Last 8 weeks",
            icon: "chart.bar.fill"
        ) {
            if chartData.isEmpty {
                EmptyGraphView(message: "No volume data available")
            } else {
                Chart {
                    ForEach(chartData, id: \.week) { dataPoint in
                        BarMark(
                            x: .value("Week", dataPoint.weekLabel),
                            y: .value("Volume", dataPoint.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Workout Frequency Graph
struct WorkoutFrequencyGraphView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var chartData: [FrequencyDataPoint] {
        viewModel.weeklyWorkoutFrequency
    }
    
    var body: some View {
        GraphCard(
            title: "Workout Frequency",
            subtitle: "Last 8 weeks",
            icon: "calendar"
        ) {
            if chartData.isEmpty {
                EmptyGraphView(message: "No workout data available")
            } else {
                Chart {
                    ForEach(chartData, id: \.week) { dataPoint in
                        BarMark(
                            x: .value("Week", dataPoint.weekLabel),
                            y: .value("Workouts", dataPoint.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.success, AppColors.accent],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColors.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppColors.mutedForeground)
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Graph Card Container
struct GraphCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            // Chart Content
            content
        }
        .padding(20)
        .frame(width: 320)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Empty Graph View
struct EmptyGraphView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppColors.mutedForeground.opacity(0.5))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Data Point Models
struct PRDataPoint {
    let date: Date
    let weight: Double
}

struct RepDataPoint {
    let date: Date
    let reps: Int
}

