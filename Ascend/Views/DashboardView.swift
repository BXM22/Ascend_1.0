import SwiftUI

struct DashboardView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                DashboardHeader()
                
                VStack(spacing: AppSpacing.lg) {
                    // Program Day Tracker
                    if programViewModel.activeProgram != nil {
                        ProgramDayTracker(
                            programViewModel: programViewModel,
                            templatesViewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            onStartWorkout: onStartWorkout
                        )
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                        
                        // Workout Calendar
                        WorkoutCalendarView(programViewModel: programViewModel)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    
                    // Quick Start Templates
                    QuickStartTemplatesSection(
                        templatesViewModel: templatesViewModel,
                        workoutViewModel: workoutViewModel,
                        onStartWorkout: onStartWorkout
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, programViewModel.activeProgram != nil ? 0 : AppSpacing.lg)
                    
                    // Quick Stats Grid
                    QuickStatsGrid(
                        currentStreak: progressViewModel.currentStreak,
                        totalVolume: progressViewModel.totalVolume,
                        workoutCount: progressViewModel.workoutCount
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Workout Streak Card
                    WorkoutStreakCard(
                        currentStreak: progressViewModel.currentStreak,
                        longestStreak: progressViewModel.longestStreak
                    )
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Recent Activity
                    RecentActivityCard(progressViewModel: progressViewModel)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Top Exercises
                    TopExercisesCard(progressViewModel: progressViewModel)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Weekly Summary
                    WeeklySummaryCard(progressViewModel: progressViewModel)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, 100)
                }
            }
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
    }
}

struct DashboardHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Dashboard")
                    .font(AppTypography.heading1)
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("Your fitness overview")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.card)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.border.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct QuickStatsGrid: View {
    let currentStreak: Int
    let totalVolume: Int
    let workoutCount: Int
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                IconStatCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: AppColors.primary
                )
                
                IconStatCard(
                    icon: "chart.bar.fill",
                    value: formatVolume(totalVolume),
                    label: "Total Volume",
                    color: AppColors.accent
                )
            }
            
            HStack(spacing: AppSpacing.md) {
                IconStatCard(
                    icon: "dumbbell.fill",
                    value: "\(workoutCount)",
                    label: "Workouts",
                    color: AppColors.primary
                )
                
                IconStatCard(
                    icon: "clock.fill",
                    value: "\(workoutCount * 45)",
                    label: "Minutes",
                    color: AppColors.accent
                )
            }
        }
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", Double(volume) / 1000.0)
        }
        return "\(volume)"
    }
}

struct IconStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(AppTypography.heading2)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}


struct RecentActivityCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var recentPRs: [PersonalRecord] {
        Array(progressViewModel.prs.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                Text("Recent PRs")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            if recentPRs.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No PRs yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Complete workouts to earn PRs!")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(recentPRs) { pr in
                        PRRow(pr: pr)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct PRRow: View {
    let pr: PersonalRecord
    
    private var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: pr.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(pr.exercise)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(Int(pr.weight)) lbs × \(pr.reps) reps")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(dateString)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TopExercisesCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var topExercises: [(String, Int)] {
        let exerciseCounts = Dictionary(grouping: progressViewModel.prs, by: { $0.exercise })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(exerciseCounts.prefix(5).map { ($0.key, $0.value) })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                Text("Top Exercises")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            if topExercises.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Text("No exercises yet")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Start tracking workouts!")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(topExercises.enumerated()), id: \.element.0) { index, exercise in
                        ExerciseRow(
                            rank: index + 1,
                            name: exercise.0,
                            count: exercise.1
                        )
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct ExerciseRow: View {
    let rank: Int
    let name: String
    let count: Int
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(AppTypography.bodyBold)
                .foregroundColor(AppColors.primary)
                .frame(width: 32, height: 32)
                .background(AppColors.primary.opacity(0.2))
                .clipShape(Circle())
            
            Text(name)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text("\(count) PRs")
                .font(AppTypography.captionMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WeeklySummaryCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    var weeklyWorkouts: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return progressViewModel.workoutDates.filter { $0 >= weekAgo }.count
    }
    
    var weeklyVolume: Int {
        // Estimate based on total volume and workout count
        let avgVolumePerWorkout = progressViewModel.totalVolume / max(progressViewModel.workoutCount, 1)
        return weeklyWorkouts * avgVolumePerWorkout
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                Text("This Week")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("\(weeklyWorkouts)")
                        .font(AppTypography.heading2)
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Workouts")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(formatVolume(weeklyVolume))
                        .font(AppTypography.heading2)
                        .foregroundStyle(LinearGradient.accentGradient)
                    
                    Text("Volume")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(AppSpacing.md)
            .background(LinearGradient.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", Double(volume) / 1000.0)
        }
        return "\(volume)"
    }
}

struct QuickStartTemplatesSection: View {
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onStartWorkout: () -> Void
    
    // Get featured templates (first 4 templates + first workout program)
    var featuredTemplates: [QuickStartItem] {
        var items: [QuickStartItem] = []
        
        // Add regular templates (limit to 3)
        let regularTemplates = templatesViewModel.templates
            .filter { !$0.name.contains("Progression") }
            .prefix(3)
        
        for template in regularTemplates {
            items.append(.template(template))
        }
        
        // Add first workout program if available
        if let program = WorkoutProgramManager.shared.programs.first {
            items.append(.program(program))
        }
        
        return items
    }
    
    enum QuickStartItem {
        case template(WorkoutTemplate)
        case program(WorkoutProgram)
        
        var name: String {
            switch self {
            case .template(let template):
                return template.name
            case .program(let program):
                return program.name
            }
        }
        
        var icon: String {
            switch self {
            case .template:
                return "dumbbell.fill"
            case .program:
                return "calendar"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                Text("Quick Start")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(Array(featuredTemplates.enumerated()), id: \.offset) { index, item in
                        QuickStartButton(
                            item: item,
                            onTap: {
                                startWorkout(for: item)
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func startWorkout(for item: QuickStartItem) {
        switch item {
        case .template(let template):
            templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
            onStartWorkout()
            
        case .program(let program):
            // Start with Day 1 of the program
            if let day1 = program.days.first {
                startProgramDay(day1, programName: program.name)
                onStartWorkout()
            }
        }
    }
    
    private func startProgramDay(_ day: WorkoutDay, programName: String) {
        let exercises = day.exercises.map { programExercise in
            let alternatives = ExerciseDataManager.shared.getAlternatives(for: programExercise.name)
            let videoURL = ExerciseDataManager.shared.getVideoURL(for: programExercise.name)
            
            return Exercise(
                name: programExercise.name,
                targetSets: programExercise.sets,
                exerciseType: programExercise.exerciseType,
                holdDuration: programExercise.targetHoldDuration,
                alternatives: alternatives,
                videoURL: videoURL
            )
        }
        
        workoutViewModel.currentWorkout = Workout(name: "\(programName) - \(day.name)", exercises: exercises)
        workoutViewModel.currentExerciseIndex = 0
        workoutViewModel.startTimer()
    }
}

struct QuickStartButton: View {
    let item: QuickStartTemplatesSection.QuickStartItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: item.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .frame(width: 50, height: 50)
                    .background(AppColors.primary.opacity(0.2))
                    .clipShape(Circle())
                
                Text(item.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 100)
            }
            .padding(AppSpacing.md)
            .frame(width: 120, height: 140)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    DashboardView(
        progressViewModel: ProgressViewModel(),
        workoutViewModel: WorkoutViewModel(),
        templatesViewModel: TemplatesViewModel(),
        programViewModel: WorkoutProgramViewModel(),
        onStartWorkout: {}
    )
}

