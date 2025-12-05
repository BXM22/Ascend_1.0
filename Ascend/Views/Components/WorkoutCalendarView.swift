import SwiftUI

struct WorkoutCalendarView: View {
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    var activeProgramInfo: (program: WorkoutProgram, activeProgram: ActiveProgram)? {
        guard let active = programViewModel.activeProgram,
              let program = programViewModel.programs.first(where: { $0.id == active.programId }) else {
            return nil
        }
        return (program, active)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                Text("Workout Calendar")
                    .font(AppTypography.heading3)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                
                // Month Navigation
                HStack(spacing: AppSpacing.md) {
                    Button(action: {
                        withAnimation(AppAnimations.standard) {
                            currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text(monthYearString)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(minWidth: 120)
                    
                    Button(action: {
                        withAnimation(AppAnimations.standard) {
                            currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            
            if let info = activeProgramInfo {
                // Calendar Grid
                VStack(spacing: 0) {
                    // Day Headers
                    HStack(spacing: 0) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(AppTypography.captionMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, AppSpacing.sm)
                    
                    // Calendar Days
                    let calendar = Calendar.current
                    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
                    let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
                    let startDate = calendar.date(byAdding: .day, value: -calendar.component(.weekday, from: monthStart) + 1, to: monthStart)!
                    let endDate = calendar.date(byAdding: .day, value: 6 - calendar.component(.weekday, from: monthEnd) + calendar.component(.day, from: monthEnd), to: monthStart)!
                    
                    let days = generateDays(from: startDate, to: endDate)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                        ForEach(days, id: \.self) { date in
                            CalendarDayCell(
                                date: date,
                                workoutDay: getWorkoutDay(for: date, program: info.program, activeProgram: info.activeProgram),
                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                isToday: calendar.isDateInToday(date),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isCompleted: programViewModel.isDateCompleted(date, inProgram: info.program.id)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        }
                    }
                }
                
                // Selected Date Info
                if let workoutDay = getWorkoutDay(for: selectedDate, program: info.program, activeProgram: info.activeProgram) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(selectedDateString)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack {
                            if workoutDay.isRestDay {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.zzz.fill")
                                    Text("Rest Day")
                                }
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text(workoutDay.name)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Spacer()
                            
                            if programViewModel.isDateCompleted(selectedDate, inProgram: info.program.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                }
            } else {
                Text("No active program")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.lg)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    private func generateDays(from start: Date, to end: Date) -> [Date] {
        var days: [Date] = []
        var current = start
        let calendar = Calendar.current
        
        while current <= end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return days
    }
    
    private func getDayIndex(for date: Date, program: WorkoutProgram, activeProgram: ActiveProgram) -> Int? {
        return programViewModel.getDayIndex(for: date, inProgram: program.id)
    }
    
    private func getWorkoutDay(for date: Date, program: WorkoutProgram, activeProgram: ActiveProgram) -> WorkoutDay? {
        return programViewModel.getWorkoutDay(for: date, inProgram: program.id)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let workoutDay: WorkoutDay?
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isCompleted: Bool
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(
                        isCurrentMonth
                            ? (isToday ? AppColors.alabasterGrey : AppColors.textPrimary)
                            : AppColors.textSecondary.opacity(0.5)
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            if let workoutDay = workoutDay {
                if workoutDay.isRestDay {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                } else {
                    Text(workoutDay.name.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 8))
                        .foregroundColor(
                            isCurrentMonth
                                ? (isToday ? AppColors.alabasterGrey.opacity(0.9) : AppColors.textSecondary)
                                : AppColors.textSecondary.opacity(0.3)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .frame(width: 44, height: 60)
        .background(
            Group {
                if isSelected {
                    LinearGradient.primaryGradient.opacity(0.2)
                } else if isToday {
                    LinearGradient.primaryGradient
                } else if isCompleted && workoutDay != nil && !workoutDay!.isRestDay {
                    AppColors.accent.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected && !isToday
                        ? AppColors.primary
                        : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

