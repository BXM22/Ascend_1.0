//
//  MuscleChartSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Section wrapper for muscle group distribution chart
struct MuscleChartSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text("Muscle Chart")
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.foreground)
                .padding(.horizontal, 20)
            
            // Muscle Group Chart
            MuscleGroupChart(progressViewModel: progressViewModel)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        MuscleChartSection(progressViewModel: ProgressViewModel())
    }
    .background(AppColors.background)
}

