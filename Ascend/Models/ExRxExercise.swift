import Foundation

// MARK: - ExRx Exercise Directory Entry
struct ExRxExercise: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String
    let muscleGroup: String
    let equipment: String?
    let url: String?
    let alternatives: [String]?
    
    init(id: String, name: String, category: String, muscleGroup: String, equipment: String? = nil, url: String? = nil, alternatives: [String]? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.url = url
        self.alternatives = alternatives
    }
    
    static func == (lhs: ExRxExercise, rhs: ExRxExercise) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ExRx Exercise Category
enum ExRxCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case calisthenics = "Calisthenics"
    case stretching = "Stretching"
    case warmup = "Warmup"
}

// MARK: - ExRx Muscle Group
enum ExRxMuscleGroup: String, CaseIterable {
    case chest = "Chest"
    case lats = "Lats"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case abs = "Abs"
    case obliques = "Obliques"
    case lowerBack = "Lower Back"
    case traps = "Traps"
    case upperBack = "Upper Back"
    case forearms = "Forearms"
}

