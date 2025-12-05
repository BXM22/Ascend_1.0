import Foundation

// MARK: - Active Program Tracker
struct ActiveProgram: Codable, Identifiable {
    let id: UUID
    let programId: UUID
    var currentDayIndex: Int
    var startDate: Date
    var lastWorkoutDate: Date?
    var completedDays: Set<Int> // Track which day indices are completed
    
    init(id: UUID = UUID(), programId: UUID, currentDayIndex: Int = 0, startDate: Date = Date(), lastWorkoutDate: Date? = nil, completedDays: Set<Int> = []) {
        self.id = id
        self.programId = programId
        self.currentDayIndex = currentDayIndex
        self.startDate = startDate
        self.lastWorkoutDate = lastWorkoutDate
        self.completedDays = completedDays
    }
    
    // Calculate current day based on start date and days since start
    func getCurrentDayIndex(totalDays: Int) -> Int {
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart % totalDays
    }
    
    func isDayCompleted(_ dayIndex: Int) -> Bool {
        return completedDays.contains(dayIndex)
    }
}

