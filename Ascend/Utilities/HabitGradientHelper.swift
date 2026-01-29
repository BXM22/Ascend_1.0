//
//  HabitGradientHelper.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

/// Utility for creating consistent gradients for habits
enum HabitGradientHelper {
    /// Creates a gradient for a habit based on its color
    static func gradient(for habit: Habit) -> LinearGradient {
        if let hex = habit.colorHex {
            let color = Color(hex: hex)
            return LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient.primaryGradient
    }
    
    /// Standard streak gradient (orange to red)
    static var streakGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Muted gradient for inactive states
    static var mutedGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.mutedForeground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}


