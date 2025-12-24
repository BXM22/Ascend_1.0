import SwiftUI
import Charts

/// Displays PR trend charts for the currently selected exercise on the Progress screen.
struct TrendGraphsView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    private var selectedExerciseName: String {
        viewModel.selectedExercise
    }
    
    private var selectedExercisePRs: [PersonalRecord] {
        viewModel.selectedExercisePRs.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            PRTrendCard(
                exerciseName: selectedExerciseName,
                prs: selectedExercisePRs
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - PR Trend Card

private struct PRTrendCard: View {
    let exerciseName: String
    let prs: [PersonalRecord]
    
    private var hasEnoughData: Bool {
        prs.count >= 2
    }
    
    private var title: String {
        exerciseName.isEmpty ? "PR Trend" : "\(exerciseName) PR Trend"
    }
    
    private var subtitle: String {
        if prs.isEmpty {
            return "Select an exercise with PRs to see your progress"
        } else if let first = prs.first, let last = prs.last {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: first.date)) – \(formatter.string(from: last.date))"
        } else {
            return "Personal record progression over time"
        }
    }
    
    var body: some View {
        TrendCardContainer(
            title: title,
            subtitle: subtitle,
            systemImage: "chart.line.uptrend.xyaxis",
            gradient: LinearGradient.primaryGradient
        ) { width, height in
            if !hasEnoughData {
                EmptyTrendPlaceholder(
                    message: prs.isEmpty
                        ? "Hit a few PRs to unlock your trend chart"
                        : "Keep training to build a clearer PR trend"
                )
                .frame(width: width, height: height, alignment: .center)
            } else {
                Chart {
                    ForEach(prs, id: \.id) { pr in
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
                        .symbolSize(60)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight)) lbs")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColors.mutedForeground)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(width: width, height: height)
            }
        }
    }
}

// MARK: - Shared Card Container

private struct TrendCardContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: LinearGradient
    @ViewBuilder let content: (CGFloat, CGFloat) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .opacity(0.25)
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.alabasterGrey)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
            }
            
            GeometryReader { proxy in
                content(proxy.size.width, proxy.size.height)
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Empty State

private struct EmptyTrendPlaceholder: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}













