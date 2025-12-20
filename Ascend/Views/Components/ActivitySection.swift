//
//  ActivitySection.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Activity section with week/month calendar toggle
struct ActivitySection: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @State private var showMonthView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header with Toggle
            HStack {
                Text("Activity")
                    .font(AppTypography.heading2)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                // Week/Month Toggle
                HStack(spacing: 0) {
                    Button(action: {
                        HapticManager.impact(style: .light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMonthView = false
                        }
                    }) {
                        Text("Week")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(showMonthView ? AppColors.foreground.opacity(0.7) : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(showMonthView ? Color.clear : AppColors.accent)
                            )
                    }
                    
                    Button(action: {
                        HapticManager.impact(style: .light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMonthView = true
                        }
                    }) {
                        Text("Month")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(showMonthView ? .white : AppColors.foreground.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(showMonthView ? AppColors.accent : Color.clear)
                            )
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.card)
                )
            }
            .padding(.horizontal, 20)
            
            // Calendar View
            if showMonthView {
                MonthCalendarView(
                    progressViewModel: progressViewModel,
                    programViewModel: programViewModel
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .padding(.horizontal, 20)
            } else {
                WeeklyCalendarWidget(
                    progressViewModel: progressViewModel,
                    programViewModel: programViewModel
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Collapsible Insights
            CollapsibleInsightsView(progressViewModel: progressViewModel)
        }
    }
}

/// Month calendar view showing workout completion for the current month
struct MonthCalendarView: View {
    @ObservedObject var progressViewModel: ProgressViewModel
    @ObservedObject var programViewModel: WorkoutProgramViewModel
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var monthDays: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDays = range.count
        
        // Create array with leading empty days + actual days
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasWorkout(on date: Date?) -> Bool {
        guard let date = date else { return false }
        let startOfDay = calendar.startOfDay(for: date)
        return progressViewModel.workoutDates.contains { calendar.isDate($0, inSameDayAs: startOfDay) }
    }
    
    private func isProgramDay(date: Date?) -> Bool {
        guard let date = date, programViewModel.activeProgram != nil else { return false }
        // For now, just check if it's not a weekend (simple heuristic)
        let dayOfWeek = calendar.component(.weekday, from: date)
        return dayOfWeek >= 2 && dayOfWeek <= 6 // Monday-Friday
    }
    
    private func isToday(date: Date?) -> Bool {
        guard let date = date else { return false }
        return calendar.isDateInToday(date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month Navigation
            HStack {
                Button(action: {
                    HapticManager.impact(style: .light)
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
                
                Spacer()
                
                Button(action: {
                    HapticManager.impact(style: .light)
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
            }
            
            // Days of Week Header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.foreground.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        MonthDayCell(
                            date: date,
                            hasWorkout: hasWorkout(on: date),
                            isProgramDay: isProgramDay(date: date),
                            isToday: isToday(date: date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
        )
    }
}

/// Individual day cell in the month calendar
struct MonthDayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isProgramDay: Bool
    let isToday: Bool
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(hasWorkout ? AppColors.accent : (isToday ? AppColors.card.opacity(0.5) : Color.clear))
                .frame(width: 36, height: 36)
            
            // Border for today
            if isToday && !hasWorkout {
                Circle()
                    .stroke(AppColors.accent, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
            
            // Day Number
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: hasWorkout ? .bold : .medium))
                .foregroundColor(hasWorkout ? .white : AppColors.foreground)
            
            // Program Indicator Dot
            if isProgramDay && !hasWorkout {
                Circle()
                    .fill(AppColors.accent.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .offset(y: 14)
            }
        }
        .frame(height: 40)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day())), \(hasWorkout ? "workout completed" : isProgramDay ? "program day" : "no workout")")
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        ActivitySection(
            progressViewModel: ProgressViewModel(),
            programViewModel: WorkoutProgramViewModel()
        )
    }
    .background(AppColors.background)
}
