//
//  DashboardFooterSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Footer section with rest day management
/// Note: Sports timer has been moved to the tab bar
struct DashboardFooterSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Rest Day Button
            RestDayButton(progressViewModel: progressViewModel)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, 100) // Extra padding for bottom safe area
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        Spacer()
            .frame(height: 400)
        
        DashboardFooterSection(progressViewModel: ProgressViewModel())
    }
    .background(AppColors.background)
}
