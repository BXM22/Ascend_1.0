import Foundation

// MARK: - Workout Split Type
enum WorkoutSplitType: String, CaseIterable, Codable {
    case pushPullLegs = "Push/Pull/Legs"
    case chestBackLegsShouldersArms = "Chest & Back/Legs/Shoulders & Arms"
    case backBicepsChestTricepsLegsShoulders = "Back & Biceps/Chest & Triceps/Legs/Shoulders"
    case chestBackLegsShouldersArms4Day = "Chest/Back/Legs/Shoulders & Arms"
    case custom = "Custom"
    
    var dayNames: [String] {
        switch self {
        case .pushPullLegs:
            return ["Push", "Pull", "Legs", "Push", "Pull", "Legs", "Rest"]
        case .chestBackLegsShouldersArms:
            return ["Chest & Back", "Legs", "Shoulders & Arms", "Chest & Back", "Legs", "Shoulders & Arms", "Rest"]
        case .backBicepsChestTricepsLegsShoulders:
            return ["Back & Biceps", "Chest & Triceps", "Legs", "Shoulders", "Rest", "Rest", "Rest"]
        case .chestBackLegsShouldersArms4Day:
            return ["Chest", "Back", "Legs", "Shoulders & Arms", "Rest", "Rest", "Rest"]
        case .custom:
            return [] // Custom splits define their own days
        }
    }
    
    var numberOfWorkoutDays: Int {
        switch self {
        case .pushPullLegs:
            return 6
        case .chestBackLegsShouldersArms:
            return 6
        case .backBicepsChestTricepsLegsShoulders:
            return 4
        case .chestBackLegsShouldersArms4Day:
            return 4
        case .custom:
            return 0 // Custom splits define their own count
        }
    }
    
    var description: String {
        switch self {
        case .pushPullLegs:
            return "6-day split: Push, Pull, Legs, Push, Pull, Legs, Rest"
        case .chestBackLegsShouldersArms:
            return "3-1-3 split: Chest & Back, Legs, Shoulders & Arms (repeated)"
        case .backBicepsChestTricepsLegsShoulders:
            return "4-day split: Back & Biceps, Chest & Triceps, Legs, Shoulders"
        case .chestBackLegsShouldersArms4Day:
            return "4-day split: Chest, Back, Legs, Shoulders & Arms"
        case .custom:
            return "Custom split with your own day structure"
        }
    }
}

// MARK: - Workout Split Day
struct WorkoutSplitDay: Identifiable, Codable {
    let id: UUID
    let dayName: String
    var templateId: UUID?
    var isRestDay: Bool
    
    init(id: UUID = UUID(), dayName: String, templateId: UUID? = nil, isRestDay: Bool = false) {
        self.id = id
        self.dayName = dayName
        self.templateId = templateId
        self.isRestDay = isRestDay
    }
}

// MARK: - Workout Split
struct WorkoutSplit: Identifiable, Codable {
    let id: UUID
    var name: String
    var splitType: WorkoutSplitType
    var days: [WorkoutSplitDay]
    var startDate: Date?
    
    init(id: UUID = UUID(), name: String, splitType: WorkoutSplitType, startDate: Date? = nil, customDays: [String]? = nil) {
        self.id = id
        self.name = name
        self.splitType = splitType
        self.startDate = startDate
        
        // Initialize days based on split type
        if splitType == .custom, let customDays = customDays {
            // Use custom days if provided
            self.days = customDays.map { dayName in
                WorkoutSplitDay(
                    dayName: dayName,
                    isRestDay: dayName.lowercased().contains("rest")
                )
            }
        } else {
            // Use predefined days for standard splits
            self.days = splitType.dayNames.map { dayName in
                WorkoutSplitDay(
                    dayName: dayName,
                    isRestDay: dayName == "Rest"
                )
            }
        }
    }
    
    // Get template for a specific day
    func getTemplate(for dayIndex: Int) -> UUID? {
        guard dayIndex < days.count else { return nil }
        return days[dayIndex].templateId
    }
    
    // Set template for a specific day
    mutating func setTemplate(_ templateId: UUID?, for dayIndex: Int) {
        guard dayIndex < days.count else { return }
        days[dayIndex].templateId = templateId
    }
    
    // Get current day based on start date
    func getCurrentDayIndex() -> Int? {
        guard let startDate = startDate else { return nil }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart % days.count
    }
}


