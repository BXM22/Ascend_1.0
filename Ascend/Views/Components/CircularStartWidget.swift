//
//  CircularStartWidget.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

/// Circular widget for quick workout start with calendar heatmap
struct CircularStartWidget: View {
    let onStartWorkout: () -> Void
    @ObservedObject var progressViewModel: ProgressViewModel
    
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            Spacer()
            
            // Circular Start Button
            Button(action: {
                HapticManager.impact(style: .medium)
                onStartWorkout()
            }) {
                ZStack {
                    // Background circle with gradient border
                    Circle()
                        .fill(AppColors.card)
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.primaryGradient, lineWidth: 3)
                        )
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    // Center play icon
                    Image(systemName: "play.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .offset(x: 3) // Slight offset to center triangle visually
                    
                    // Curved text around top
                    CurvedText(text: "START", radius: 60, angle: -180, fontSize: 14, fontWeight: .bold)
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .offset(y: -12)
                    
                    // Curved text around bottom
                    CurvedText(text: "WORKOUT", radius: 60, angle: 0, fontSize: 14, fontWeight: .bold)
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .offset(y: 12)
                    
                    // Scattered exercise icons
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary.opacity(0.3))
                        .offset(x: -50, y: -30)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accent.opacity(0.3))
                        .offset(x: 50, y: -30)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.armsGradientEnd.opacity(0.3))
                        .offset(x: -50, y: 30)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.legsGradientEnd.opacity(0.3))
                        .offset(x: 50, y: 30)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .pressEvents {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
            } onRelease: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }
}

/// Curved text for circular widget
struct CurvedText: View {
    let text: String
    let radius: CGFloat
    let angle: Double
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    
    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: fontSize, weight: fontWeight))
                    .rotationEffect(.degrees(angle + Double(index) * (360.0 / Double(text.count * 3))))
                    .offset(y: -radius)
                    .rotationEffect(.degrees(-angle - Double(index) * (360.0 / Double(text.count * 3))))
            }
        }
    }
}

/// Mini workout heatmap visualization
struct WorkoutHeatmap: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private let columns = 7
    private let rows = 5
    
    private var workoutDates: Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(progressViewModel.workoutDates.map { date in
            formatter.string(from: date)
        })
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Last 35 Days")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .padding(.bottom, 4)
            
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<columns, id: \.self) { col in
                            HeatmapCell(
                                dayOffset: row * columns + col,
                                workoutDates: workoutDates
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Individual heatmap cell
struct HeatmapCell: View {
    let dayOffset: Int
    let workoutDates: Set<String>
    
    private var hasWorkout: Bool {
        guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else {
            return false
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return workoutDates.contains(dateString)
    }
    
    var body: some View {
        if hasWorkout {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient.primaryGradient)
                .frame(width: 20, height: 20)
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 20, height: 20)
        }
    }
}

/// Button press event helpers
extension View {
    func pressEvents(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}

#Preview {
    CircularStartWidget(
        onStartWorkout: {},
        progressViewModel: ProgressViewModel()
    )
    .padding()
    .background(AppColors.background)
}

