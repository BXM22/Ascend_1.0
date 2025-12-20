//
//  ProgressTab.swift
//  Ascend
//
//  Created on 2025
//

import SwiftUI

enum ProgressTab: String, CaseIterable {
    case overview = "Overview"
    case exercises = "Exercises"
    case stats = "Stats"
    
    var icon: String {
        switch self {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .exercises: return "figure.strengthtraining.traditional"
        case .stats: return "chart.bar.fill"
        }
    }
}

enum TrendIndicator {
    case improving
    case stable
    case declining
    case new
    
    var icon: Image {
        switch self {
        case .improving: return Image(systemName: "arrow.up.right")
        case .stable: return Image(systemName: "arrow.right")
        case .declining: return Image(systemName: "arrow.down.right")
        case .new: return Image(systemName: "sparkles")
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return AppColors.success
        case .stable: return AppColors.mutedForeground
        case .declining: return AppColors.destructive
        case .new: return AppColors.accent
        }
    }
    
    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .new: return "New"
        }
    }
}

enum ProgressInsight {
    case onFire(prCount: Int)
    case consistent(streak: Int)
    case improving(percentage: Double)
    case needsAttention(exercise: String)
    case milestone(achievement: String)
    
    var icon: String {
        switch self {
        case .onFire: return "flame.fill"
        case .consistent: return "calendar.badge.checkmark"
        case .improving: return "chart.line.uptrend.xyaxis"
        case .needsAttention: return "exclamationmark.triangle.fill"
        case .milestone: return "star.fill"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .onFire: return LinearGradient.primaryGradient
        case .consistent: return LinearGradient.accentGradient
        case .improving: return LinearGradient.chestGradient
        case .needsAttention: return LinearGradient(colors: [AppColors.destructive, AppColors.destructive.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .milestone: return LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var title: String {
        switch self {
        case .onFire: return "You're on Fire!"
        case .consistent: return "Great Consistency"
        case .improving: return "Keep It Up!"
        case .needsAttention: return "Time to Challenge?"
        case .milestone: return "Achievement Unlocked!"
        }
    }
    
    var message: String {
        switch self {
        case .onFire(let count):
            return "\(count) PRs this week! Your hard work is paying off."
        case .consistent(let streak):
            return "\(streak) day streak. Consistency is the key to progress."
        case .improving(let percentage):
            return "You're \(Int(percentage))% stronger this month. Incredible gains!"
        case .needsAttention(let exercise):
            return "No PRs in \(exercise) for 2 weeks. Time to push harder?"
        case .milestone(let achievement):
            return achievement
        }
    }
}
