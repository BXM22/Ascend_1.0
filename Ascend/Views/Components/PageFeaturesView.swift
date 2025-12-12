import SwiftUI

enum PageType {
    case dashboard
    case workout
    case progress
    case templates
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .workout: return "Workout"
        case .progress: return "Progress"
        case .templates: return "Templates"
        }
    }
    
    var features: [PageFeature] {
        switch self {
        case .dashboard:
            return [
                PageFeature(icon: "flame.fill", title: "Workout Streak", description: "Track your consecutive workout days and maintain your fitness momentum."),
                PageFeature(icon: "chart.bar.fill", title: "Quick Stats", description: "View your total volume, workout count, and other key metrics at a glance."),
                PageFeature(icon: "list.bullet.rectangle", title: "Quick Start Templates", description: "Access your favorite templates instantly to begin a workout."),
                PageFeature(icon: "calendar", title: "Workout Calendar", description: "See your workout schedule and track your training days."),
                PageFeature(icon: "star.fill", title: "Top Exercises", description: "View your most frequently performed exercises."),
                PageFeature(icon: "clock.fill", title: "Recent Activity", description: "See your latest workout sessions and achievements.")
            ]
        case .workout:
            return [
                PageFeature(icon: "dumbbell.fill", title: "Track Exercises", description: "Log sets, weight, and reps for each exercise in your workout."),
                PageFeature(icon: "timer", title: "Rest Timer", description: "Use the built-in rest timer between sets to optimize your recovery."),
                PageFeature(icon: "trophy.fill", title: "PR Detection", description: "Automatically detects and celebrates when you hit a personal record."),
                PageFeature(icon: "arrow.triangle.2.circlepath", title: "Alternative Exercises", description: "Swap exercises with alternatives if needed during your workout."),
                PageFeature(icon: "chart.line.uptrend.xyaxis", title: "Previous Sets", description: "View your previous performance for each exercise to guide your current sets."),
                PageFeature(icon: "checkmark.circle.fill", title: "Complete Sets", description: "Mark sets as complete to track your progress through the workout.")
            ]
        case .progress:
            return [
                PageFeature(icon: "chart.line.uptrend.xyaxis", title: "Progress Charts", description: "Visualize your strength and volume progress over time with detailed charts."),
                PageFeature(icon: "trophy.fill", title: "Personal Records", description: "View all your personal records and when you achieved them."),
                PageFeature(icon: "calendar", title: "Workout History", description: "Browse your complete workout history organized by date."),
                PageFeature(icon: "magnifyingglass", title: "Exercise Search", description: "Search for specific exercises to view their detailed progress history."),
                PageFeature(icon: "chart.bar.fill", title: "Volume Tracking", description: "Track your total training volume over time."),
                PageFeature(icon: "clock.fill", title: "Time Periods", description: "View your progress by week or month to see trends.")
            ]
        case .templates:
            return [
                PageFeature(icon: "plus.circle.fill", title: "Create Templates", description: "Build custom workout templates with your preferred exercises and sets."),
                PageFeature(icon: "wand.and.stars", title: "Generate Workouts", description: "Use AI to generate workout templates based on your preferences."),
                PageFeature(icon: "list.bullet.rectangle", title: "Workout Programs", description: "Create and follow structured workout programs with multiple days."),
                PageFeature(icon: "figure.strengthtraining.traditional", title: "Calisthenics Skills", description: "Access progression-based calisthenics skill templates."),
                PageFeature(icon: "pencil", title: "Edit Templates", description: "Modify existing templates to match your evolving training needs."),
                PageFeature(icon: "magnifyingglass", title: "Search Templates", description: "Quickly find templates by name or exercise.")
            ]
        }
    }
}

struct PageFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct PageFeaturesView: View {
    let pageType: PageType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pageType.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(LinearGradient.primaryGradient)
                        
                        Text("Features & Tips")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    // Features List
                    VStack(spacing: 16) {
                        ForEach(pageType.features) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let feature: PageFeature
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(feature.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

struct HelpButton: View {
    let pageType: PageType
    @State private var showFeatures = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .light)
            showFeatures = true
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 44, height: 44)
        }
        .sheet(isPresented: $showFeatures) {
            PageFeaturesView(pageType: pageType)
        }
    }
}
