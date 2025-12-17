import Foundation

// MARK: - Custom Exercise
struct CustomExercise: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let primaryMuscleGroups: [String]
    let secondaryMuscleGroups: [String]
    let alternatives: [String]
    let videoURL: String?
    let category: String
    let equipment: String?
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscleGroups: [String],
        secondaryMuscleGroups: [String] = [],
        alternatives: [String] = [],
        videoURL: String? = nil,
        category: String,
        equipment: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleGroups = primaryMuscleGroups
        self.secondaryMuscleGroups = secondaryMuscleGroups
        self.alternatives = alternatives
        self.videoURL = videoURL
        self.category = category
        self.equipment = equipment
        self.dateCreated = dateCreated
    }
}

// MARK: - Muscle Group Options
enum MuscleGroup: String, CaseIterable, Identifiable {
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
    case fullBody = "Full Body"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .lats: return "figure.pull"
        case .shoulders: return "figure.stand"
        case .biceps: return "figure.arms.open"
        case .triceps: return "figure.arms.open"
        case .quads: return "figure.walk"
        case .hamstrings: return "figure.walk"
        case .glutes: return "figure.walk"
        case .calves: return "figure.walk"
        case .abs: return "figure.core.training"
        case .obliques: return "figure.core.training"
        case .lowerBack: return "figure.flexibility"
        case .traps: return "figure.stand"
        case .upperBack: return "figure.pull"
        case .forearms: return "hand.raised"
        case .fullBody: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Exercise Category Options
enum ExerciseCategory: String, CaseIterable, Identifiable {
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
    case other = "Other"
    
    var id: String { rawValue }
}

