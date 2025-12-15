import SwiftUI

struct DashboardView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    let onStartWorkout: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                YourActivityHeader(onSettings: onSettings)
                
                VStack(spacing: 20) {
                    // Weekly Calendar (with program indicator if active)
                    WeeklyCalendarWidget(
                        progressViewModel: progressViewModel,
                        programViewModel: programViewModel
                    )
                    
                    // Next Workout Day Card (only shows when program is active)
                    if programViewModel.activeProgram != nil {
                        NextWorkoutDayCard(
                            programViewModel: programViewModel,
                            templatesViewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            onStartWorkout: onStartWorkout
                        )
                    }
                    
                    // Suggested Workout Card (only show if no active program)
                    if programViewModel.activeProgram == nil {
                        SuggestedWorkoutCard(
                            workoutViewModel: workoutViewModel,
                            templatesViewModel: templatesViewModel,
                            programViewModel: programViewModel,
                            onStartWorkout: onStartWorkout
                        )
                        
                        RandomWorkoutGeneratorCard(
                            templatesViewModel: templatesViewModel,
                            workoutViewModel: workoutViewModel,
                            progressViewModel: progressViewModel,
                            onStartWorkout: onStartWorkout
                        )
                    }
                    
                    // Stat Cards (Recent PRs + Top Exercise)
                    HStack(spacing: 12) {
                        RecentPRsStatCard(progressViewModel: progressViewModel)
                        TopExerciseStatCard(progressViewModel: progressViewModel)
                    }
                    
                    // Rest Day Button
                    RestDayButton(progressViewModel: progressViewModel)
                    
                    // Muscle Group Chart
                    MuscleGroupChart(progressViewModel: progressViewModel)
                        .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(AppColors.background)
        .id(AppColors.themeID)
    }
}

// MARK: - Header

struct YourActivityHeader: View {
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Your Activity")
                .font(AppTypography.largeTitleBold)
                .foregroundStyle(LinearGradient.primaryGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            HStack(spacing: 12) {
                HelpButton(pageType: .dashboard)
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    onSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
}

// MARK: - Stat Cards

struct RecentPRsStatCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private var recentPRsCount: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return progressViewModel.prs.filter { $0.date >= weekAgo }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.chestGradientEnd.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.chestGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(recentPRsCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(LinearGradient.chestGradient)
                
                Text("PRs This Week")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.chestGradient.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct TopExerciseStatCard: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    
    private var topExercise: (name: String, count: Int)? {
        let exerciseCounts = Dictionary(grouping: progressViewModel.prs, by: { $0.exercise })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return exerciseCounts.first.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.backGradientEnd.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.backGradient)
            }
            
            if let exercise = topExercise {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LinearGradient.backGradient)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    Text("\(exercise.count) PRs")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Data")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Text("Start tracking")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient.backGradient.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Random Workout Generator Card
struct RandomWorkoutGeneratorCard: View {
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @ObservedObject var progressViewModel: ProgressViewModel
    let onStartWorkout: () -> Void
    
    @State private var selectedSplit: SplitOption = .push
    
    enum SplitOption: String, CaseIterable, Identifiable {
        case push = "Push"
        case pull = "Pull"
        case legs = "Legs"
        case upper = "Upper"
        case lower = "Lower"
        var id: String { rawValue }
    }
    
    private func generateTemplate(for split: SplitOption) -> WorkoutTemplate {
        switch split {
        case .push: return templatesViewModel.generatePushWorkout()
        case .pull: return templatesViewModel.generatePullWorkout()
        case .legs: return templatesViewModel.generateLegWorkout()
        case .upper: return templatesViewModel.generateWorkout(name: "Upper Body")
        case .lower: return templatesViewModel.generateWorkout(name: "Lower Body")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quick Generate")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                Spacer()
            }
            
            Text("Generate a random workout by split")
                .font(.system(size: 13))
                .foregroundColor(AppColors.mutedForeground)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose split")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Menu {
                    ForEach(SplitOption.allCases) { option in
                        Button(option.rawValue) {
                            selectedSplit = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSplit.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.foreground)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(AppColors.secondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Button(action: {
                let template = generateTemplate(for: selectedSplit)
                templatesViewModel.startTemplate(template, workoutViewModel: workoutViewModel)
                onStartWorkout()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generate")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppColors.alabasterGrey)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(LinearGradient.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.foreground.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Rest Day Button

struct RestDayButton: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @State private var showConfirmation = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            showConfirmation = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Day")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text("Mark today as rest day")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColors.foreground.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Mark Rest Day", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Rest Day") {
                progressViewModel.markRestDay()
                HapticManager.success()
            }
        } message: {
            Text("This will mark today as a rest day and increment your streak. You can still work out later today if needed.")
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView(
        progressViewModel: ProgressViewModel(),
        workoutViewModel: WorkoutViewModel(settingsManager: SettingsManager()),
        templatesViewModel: TemplatesViewModel(),
        programViewModel: WorkoutProgramViewModel(),
        onStartWorkout: {},
        onSettings: {}
    )
}
