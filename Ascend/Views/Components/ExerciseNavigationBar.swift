//
//  ExerciseNavigationBar.swift
//  Ascend
//
//  Created on 2024
//

import SwiftUI

struct ExerciseNavigationBar: View {
    let exercises: [Exercise]
    @Binding var currentIndex: Int
    let onExerciseSelect: (Int) -> Void
    
    private var hasPrevious: Bool {
        currentIndex > 0
    }
    
    private var hasNext: Bool {
        currentIndex < exercises.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Dot indicators
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        let isActive = index == currentIndex
                        let isCompleted = exercise.sets.count >= exercise.targetSets
                        
                        Circle()
                            .fill(
                                isCompleted 
                                    ? AnyShapeStyle(AppColors.success)
                                    : (isActive ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                            )
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: isActive ? 2 : 0)
                            )
                            .onTapGesture {
                                withAnimation(.smooth) {
                                    onExerciseSelect(index)
                                }
                                HapticManager.impact(style: .light)
                            }
                            .accessibilityLabel("\(exercise.name), \(isCompleted ? "completed" : isActive ? "current" : "not started")")
                            .accessibilityAddTraits(isActive ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
            
            Divider()
                .background(AppColors.border)
            
            // Current exercise name + arrows
            HStack(spacing: 12) {
                Button(action: {
                    if hasPrevious {
                        withAnimation(.smooth) {
                            onExerciseSelect(currentIndex - 1)
                        }
                        HapticManager.impact(style: .light)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasPrevious ? AppColors.textPrimary : AppColors.muted)
                        .frame(width: 40, height: 40)
                }
                .disabled(!hasPrevious)
                .accessibilityLabel("Previous exercise")
                .accessibilityHint(hasPrevious ? "Navigate to previous exercise" : "No previous exercise")
                
                VStack(spacing: 4) {
                    Text(exercises[currentIndex].name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("Exercise \(currentIndex + 1) of \(exercises.count)")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    if hasNext {
                        withAnimation(.smooth) {
                            onExerciseSelect(currentIndex + 1)
                        }
                        HapticManager.impact(style: .light)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasNext ? AppColors.textPrimary : AppColors.muted)
                        .frame(width: 40, height: 40)
                }
                .disabled(!hasNext)
                .accessibilityLabel("Next exercise")
                .accessibilityHint(hasNext ? "Navigate to next exercise" : "No next exercise")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
