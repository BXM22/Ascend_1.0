import SwiftUI

struct WeeklyCalendarWidget: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    
    @State private var weekOffset: Int = 0 // 0 = current week, -1 = previous, +1 = next
    @State private var selectedDate: Date?
    @State private var showWorkoutDetail = false
    
    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Sunday)
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        // Apply week offset
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
            return []
        }
        
        // Generate all 7 days of the week
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    private func isWorkoutDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return progressViewModel.workoutDates.contains { 
            calendar.isDate($0, inSameDayAs: date)
        }
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func dayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter (M, T, W, etc.)
        return formatter.string(from: date)
    }
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        // Use the first day of the displayed week for month/year
        if let firstDay = currentWeekDays.first {
            return formatter.string(from: firstDay)
        }
        return formatter.string(from: Date())
    }
    
    private func getWorkoutDay(for date: Date) -> WorkoutDay? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == activeProgram.programId }) else {
            return nil
        }
        return programViewModel.getWorkoutDay(for: date, inProgram: program.id)
    }
    
    private func getIntensity(for date: Date) -> WorkoutIntensity? {
        guard let workoutDay = getWorkoutDay(for: date) else {
            return nil
        }
        return programViewModel.calculateIntensity(from: workoutDay)
    }
    
    private func getProgress(for date: Date) -> Double {
        guard let activeProgram = programViewModel.activeProgram else {
            // Check WorkoutHistoryManager for any completed workout on this date
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let workouts = WorkoutHistoryManager.shared.getWorkouts(
                in: DateInterval(start: dayStart, end: dayEnd)
            )
            return workouts.isEmpty ? 0.0 : 1.0
        }
        return programViewModel.getCompletionProgress(for: date, inProgram: activeProgram.programId)
    }
    
    private func handleDayTap(_ date: Date) {
        selectedDate = date
        showWorkoutDetail = true
    }
    
    private func navigateWeek(_ direction: Int) {
        withAnimation(AppAnimations.standard) {
            weekOffset += direction
            // Reset to current week if we go too far forward (optional: could allow unlimited navigation)
            if weekOffset > 4 {
                weekOffset = 0
            }
        }
        HapticManager.selection()
    }
    
    private var todayWorkoutInfo: (day: WorkoutDay, date: Date)? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { 
                  $0.id == activeProgram.programId 
              }) else {
            return nil
        }
        
        let today = Date()
        
        guard let workoutDay = programViewModel.getWorkoutDay(for: today, inProgram: program.id) else {
            return nil
        }
        
        return (workoutDay, today)
    }
    
    private var nextWorkoutInfo: (day: WorkoutDay, date: Date)? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { 
                  $0.id == activeProgram.programId 
              }) else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Start from tomorrow (dayOffset = 1) to get the next workout, not today's
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let daysSinceStart = calendar.dateComponents([.day], from: activeProgram.startDate, to: date).day,
                  daysSinceStart >= 0 else {
                continue
            }
            
            let dayIndex = daysSinceStart % program.days.count
            guard dayIndex < program.days.count else { continue }
            
            let workoutDay = program.days[dayIndex]
            // Skip rest days when looking for next workout
            if workoutDay.isRestDay {
                continue
            }
            
            return (workoutDay, date)
        }
        return nil
    }
    
    private func relativeDayName(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .day) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
    private func intensityColor(for intensity: WorkoutIntensity) -> Color {
        switch intensity {
        case .light:
            return AppColors.success
        case .moderate:
            return AppColors.primary
        case .intense:
            return AppColors.warning
        case .extreme:
            return AppColors.destructive
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month/Year display with week navigation
            HStack {
                Text(currentMonthYear)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
                
                // Week navigation buttons
                HStack(spacing: 12) {
                    Button(action: {
                        navigateWeek(-1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    if weekOffset != 0 {
                        Button(action: {
                            withAnimation(AppAnimations.standard) {
                                weekOffset = 0
                            }
                            HapticManager.selection()
                        }) {
                            Text("Today")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    Button(action: {
                        navigateWeek(1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            
            // Week days circles with swipe gesture
            HStack(spacing: 0) {
                ForEach(Array(currentWeekDays.enumerated()), id: \.element) { index, date in
                    DayCircle(
                        letter: dayLetter(date),
                        isToday: isToday(date),
                        hasWorkout: isWorkoutDay(date) || getWorkoutDay(for: date) != nil,
                        intensity: getIntensity(for: date),
                        progress: getProgress(for: date),
                        onTap: {
                            handleDayTap(date)
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Add spacing between circles (but not after the last one)
                    if index < currentWeekDays.count - 1 {
                        Spacer()
                            .frame(minWidth: 4, maxWidth: 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if abs(value.translation.width) > 50 {
                            if value.translation.width > 50 {
                                // Swipe right - previous week
                                navigateWeek(-1)
                            } else {
                                // Swipe left - next week
                                navigateWeek(1)
                            }
                        }
                    }
            )
            
            // Today's workout (if program active)
            if let todayWorkout = todayWorkoutInfo {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: todayWorkout.day.isRestDay ? "moon.zzz.fill" : "calendar.badge.checkmark")
                            .font(.system(size: 14))
                            .foregroundColor(todayWorkout.day.isRestDay ? AppColors.accent : AppColors.primary)
                        
                        Text("Today: \(todayWorkout.day.name)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        // Intensity indicator (only show if not rest day)
                        if !todayWorkout.day.isRestDay {
                            let intensity = programViewModel.calculateIntensity(from: todayWorkout.day)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(intensityColor(for: intensity))
                                    .frame(width: 6, height: 6)
                                
                                Text(intensity.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    
                    // Next workout indicator (if program active and different from today)
                    if let nextWorkout = nextWorkoutInfo {
                        let calendar = Calendar.current
                        if !calendar.isDate(nextWorkout.date, inSameDayAs: todayWorkout.date) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Text("Next: \(nextWorkout.day.name) - \(relativeDayName(nextWorkout.date))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Spacer()
                        }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let nextWorkout = nextWorkoutInfo {
                // Only show next workout if no today workout
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Next: \(nextWorkout.day.name) - \(relativeDayName(nextWorkout.date))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showWorkoutDetail) {
            if let date = selectedDate {
                if let workoutDay = getWorkoutDay(for: date) {
                    WorkoutDayDetailSheet(
                        workoutDay: workoutDay,
                        date: date,
                        intensity: getIntensity(for: date) ?? .moderate,
                        isCompleted: getProgress(for: date) >= 1.0
                    )
                } else {
                    // Show message for days without workouts
                    NavigationView {
                        VStack(spacing: AppSpacing.lg) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            Text("No Workout Scheduled")
                                .font(AppTypography.heading3)
                                .foregroundColor(AppColors.textPrimary)
                            
                            if programViewModel.activeProgram != nil {
                                Text("This day doesn't have a scheduled workout in your active program.")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppSpacing.lg)
                            } else {
                                Text("No active workout program. Start a program to see scheduled workouts.")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppSpacing.lg)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.background)
                        .navigationTitle("Workout Details")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showWorkoutDetail = false
                                }
                                .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Ensure workout dates are synced when calendar appears
            syncWorkoutDates()
        }
        .onChange(of: progressViewModel.workoutDates.count) { _, _ in
            // Refresh when workout dates change
            syncWorkoutDates()
        }
        .onChange(of: programViewModel.activeProgram?.programId) { _, _ in
            // Refresh when active program changes
            syncWorkoutDates()
        }
        .onChange(of: programViewModel.programs.count) { _, _ in
            // Refresh when programs are loaded
            syncWorkoutDates()
        }
    }
    
    private func syncWorkoutDates() {
        // Sync workout dates from WorkoutHistoryManager if needed
        let historyManager = WorkoutHistoryManager.shared
        let calendar = Calendar.current
        
        // Get all workout dates from completed workouts
        let workoutDatesFromHistory = historyManager.completedWorkouts.map { workout in
            calendar.startOfDay(for: workout.startDate)
        }
        
        // Update progressViewModel if dates are missing
        let existingDates = Set(progressViewModel.workoutDates.map { calendar.startOfDay(for: $0) })
        let newDates = workoutDatesFromHistory.filter { !existingDates.contains($0) }
        
        if !newDates.isEmpty {
            // Add missing dates
            for date in newDates {
                progressViewModel.addWorkoutDate(date)
            }
        }
    }
}


#Preview {
    WeeklyCalendarWidget(
        progressViewModel: ProgressViewModel(),
        programViewModel: WorkoutProgramViewModel()
    )
    .padding()
    .background(AppColors.background)
}

