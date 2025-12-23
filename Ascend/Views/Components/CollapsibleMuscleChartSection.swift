//
//  CollapsibleMuscleChartSection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Collapsible container for muscle chart
struct CollapsibleMuscleChartSection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @Binding var isExpanded: Bool
    let onToggle: (() -> Void)?
    
    init(progressViewModel: ProgressViewModel, isExpanded: Binding<Bool>? = nil, onToggle: (() -> Void)? = nil) {
        self.progressViewModel = progressViewModel
        self._isExpanded = isExpanded ?? .constant(true)
        self.onToggle = onToggle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle
            Button(action: {
                HapticManager.impact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    onToggle?()
                }
            }) {
                HStack {
                    Text("Muscle Chart")
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
                MuscleGroupChart(progressViewModel: progressViewModel)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

