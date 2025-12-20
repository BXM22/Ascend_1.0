//
//  PRFilterSheet.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

struct PRFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: PRFilters
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Period") {
                    Picker("Range", selection: $filters.timeRange) {
                        ForEach(PRFilters.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Muscle Groups") {
                    FlowLayout(spacing: 8) {
                        ForEach(["Chest", "Back", "Legs", "Arms", "Core", "Cardio"], id: \.self) { group in
                            FilterChip(
                                title: group,
                                isSelected: filters.muscleGroups.contains(group),
                                gradient: AppColors.categoryGradient(for: group)
                            ) {
                                HapticManager.selection()
                                if filters.muscleGroups.contains(group) {
                                    filters.muscleGroups.remove(group)
                                } else {
                                    filters.muscleGroups.insert(group)
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
                
                Section("Weight") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("0", value: $filters.minWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("lbs")
                    }
                }
                
                Section("Sort By") {
                    Picker("Order", selection: $filters.sortOrder) {
                        ForEach(PRFilters.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
            }
            .navigationTitle("Filter PRs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        HapticManager.impact(style: .light)
                        withAnimation(.smooth) {
                            filters = PRFilters()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.impact(style: .light)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                        AnyView(gradient) :
                        AnyView(AppColors.muted.opacity(0.3))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? gradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 0 : 1)
                        .opacity(isSelected ? 0 : 0.3)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Flow Layout for Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
