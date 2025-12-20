//
//  CollapsibleInsightsView.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Collapsible container for insights grid
struct CollapsibleInsightsView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle
            Button(action: {
                HapticManager.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Insights")
                        .font(AppTypography.heading2)
                        .foregroundColor(AppColors.foreground)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible Content
            if isExpanded {
                InsightsGrid(progressViewModel: progressViewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        CollapsibleInsightsView(progressViewModel: ProgressViewModel())
    }
    .background(AppColors.background)
}

