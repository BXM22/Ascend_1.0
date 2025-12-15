import SwiftUI

struct WeeklyCalendarWidget: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    
    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the week (Sunday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
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
        return formatter.string(from: Date())
    }
    
    private var nextWorkoutInfo: (day: String, date: Date)? {
        guard let activeProgram = programViewModel.activeProgram,
              let program = WorkoutProgramManager.shared.programs.first(where: { 
                  $0.id == activeProgram.programId 
              }) else {
            return nil
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let daysSinceStart = calendar.dateComponents([.day], from: activeProgram.startDate, to: date).day,
                  daysSinceStart >= 0 else {
                continue
            }
            
            let dayIndex = daysSinceStart % program.days.count
            guard dayIndex < program.days.count else { continue }
            
            return (program.days[dayIndex].name, date)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month/Year display
            Text(currentMonthYear)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            // Week days circles
            HStack(spacing: 8) {
                ForEach(currentWeekDays, id: \.self) { date in
                    DayCircle(
                        letter: dayLetter(date),
                        isToday: isToday(date),
                        hasWorkout: isWorkoutDay(date)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Next workout indicator (if program active)
            if let nextWorkout = nextWorkoutInfo {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Next: \(nextWorkout.day) - \(relativeDayName(nextWorkout.date))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DayCircle: View {
    let letter: String
    let isToday: Bool
    let hasWorkout: Bool
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(fillColor)
                .frame(width: circleSize, height: circleSize)
            
            // Border for today
            if isToday {
                Circle()
                    .strokeBorder(LinearGradient.primaryGradient, lineWidth: 2)
                    .frame(width: circleSize, height: circleSize)
            }
            
            // Day letter
            Text(letter)
                .font(.system(size: fontSize, weight: isToday ? .bold : .medium))
                .foregroundColor(textColor)
        }
        .frame(width: circleSize, height: circleSize)
    }
    
    private var circleSize: CGFloat {
        isToday ? 44 : 40
    }
    
    private var fontSize: CGFloat {
        isToday ? 16 : 14
    }
    
    private var fillColor: Color {
        if hasWorkout {
            return AppColors.accent.opacity(0.9)
        } else {
            return AppColors.secondary.opacity(0.5)
        }
    }
    
    private var textColor: Color {
        if hasWorkout {
            return AppColors.onPrimary
        } else if isToday {
            return AppColors.textPrimary
        } else {
            return AppColors.mutedForeground
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

