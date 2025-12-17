import SwiftUI

/// Displays weekly training trends (volume and workout frequency) using simple bar charts.
struct TrendGraphsView: View {
    @ObservedObject var viewModel: ProgressViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            FrequencyTrendCard(data: viewModel.weeklyWorkoutFrequency)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Volume Trend

private struct VolumeTrendCard: View {
    let data: [VolumeDataPoint]
    
    private var maxVolume: Double {
        let maxValue = data.map { $0.volume }.max() ?? 0
        return max(1, Double(maxValue))
    }
    
    var body: some View {
        TrendCardContainer(
            title: "Weekly Volume",
            subtitle: "Last \(AppConstants.Progress.weeksToDisplay) weeks",
            systemImage: "chart.bar.fill",
            gradient: LinearGradient.primaryGradient
        ) { width, height in
            if data.isEmpty {
                EmptyTrendPlaceholder(message: "No volume data yet")
                    .frame(width: width, height: height, alignment: .center)
            } else {
                let barAreaHeight = height - 24 // leave room for labels
                let barCount = max(data.count, 1)
                let barWidth = max(6, (width / CGFloat(barCount)) * 0.5)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.primaryGradient)
                                .frame(
                                    width: barWidth,
                                    height: max(
                                        4,
                                        CGFloat(point.volume) / CGFloat(maxVolume) * barAreaHeight
                                    )
                                )
                            
                            Text(point.weekLabel)
                                .font(.system(size: 9))
                                .foregroundColor(AppColors.mutedForeground)
                                .lineLimit(1)
                                .frame(maxWidth: barWidth * 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}

// MARK: - Frequency Trend

private struct FrequencyTrendCard: View {
    let data: [FrequencyDataPoint]
    
    private var maxCount: Double {
        let maxValue = data.map { $0.count }.max() ?? 0
        return max(1, Double(maxValue))
    }
    
    var body: some View {
        TrendCardContainer(
            title: "Workout Frequency",
            subtitle: "Sessions per week",
            systemImage: "calendar",
            gradient: LinearGradient.backGradient
        ) { width, height in
            if data.isEmpty {
                EmptyTrendPlaceholder(message: "No workouts logged yet")
                    .frame(width: width, height: height, alignment: .center)
            } else {
                let barAreaHeight = height - 24
                let barCount = max(data.count, 1)
                let barWidth = max(6, (width / CGFloat(barCount)) * 0.5)
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, point in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.backGradient)
                                .frame(
                                    width: barWidth,
                                    height: max(
                                        4,
                                        CGFloat(point.count) / CGFloat(maxCount) * barAreaHeight
                                    )
                                )
                            
                            Text(point.weekLabel)
                                .font(.system(size: 9))
                                .foregroundColor(AppColors.mutedForeground)
                                .lineLimit(1)
                                .frame(maxWidth: barWidth * 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
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




