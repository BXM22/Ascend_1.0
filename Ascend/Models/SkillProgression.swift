import Foundation
import Combine

// MARK: - Skill Progression Level
struct SkillProgressionLevel: Identifiable, Codable {
    let id: UUID
    let level: Int
    let name: String
    let description: String
    let targetHoldDuration: Int? // For hold exercises
    let targetReps: Int? // For rep-based exercises
    let isCompleted: Bool
    
    init(id: UUID = UUID(), level: Int, name: String, description: String, targetHoldDuration: Int? = nil, targetReps: Int? = nil, isCompleted: Bool = false) {
        self.id = id
        self.level = level
        self.name = name
        self.description = description
        self.targetHoldDuration = targetHoldDuration
        self.targetReps = targetReps
        self.isCompleted = isCompleted
    }
}

// MARK: - Calisthenics Skill
struct CalisthenicsSkill: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    let progressionLevels: [SkillProgressionLevel]
    let videoURL: String?
    let category: SkillCategory
    let isCustom: Bool
    
    enum SkillCategory: String, Codable {
        case push = "Push"
        case pull = "Pull"
        case core = "Core"
        case fullBody = "Full Body"
    }
    
    init(id: UUID = UUID(), name: String, icon: String, description: String, progressionLevels: [SkillProgressionLevel], videoURL: String? = nil, category: SkillCategory, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.progressionLevels = progressionLevels
        self.videoURL = videoURL
        self.category = category
        self.isCustom = isCustom
    }
}

// MARK: - Calisthenics Skill Manager
class CalisthenicsSkillManager: ObservableObject {
    static let shared = CalisthenicsSkillManager()
    
    @Published var skills: [CalisthenicsSkill] = []
    
    private let customSkillsKey = "customCalisthenicsSkills"
    
    private let builtInSkills: [CalisthenicsSkill] = [
        CalisthenicsSkill(
            name: "Planche",
            icon: "figure.strengthtraining.traditional",
            description: "Master the ultimate pushing strength skill",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Frog Stand", description: "Hold for 30+ seconds", targetHoldDuration: 30),
                SkillProgressionLevel(level: 2, name: "Tuck Planche", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 3, name: "Advanced Tuck Planche", description: "Hold for 8+ seconds", targetHoldDuration: 8),
                SkillProgressionLevel(level: 4, name: "Straddle Planche", description: "Hold for 5+ seconds", targetHoldDuration: 5),
                SkillProgressionLevel(level: 5, name: "Full Planche", description: "Hold for 3+ seconds", targetHoldDuration: 3)
            ],
            videoURL: "https://www.youtube.com/watch?v=w6x_GdS1XRs",
            category: .push
        ),
        CalisthenicsSkill(
            name: "Handstand Push-up",
            icon: "figure.handpush",
            description: "Build overhead pressing strength",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Wall Handstand Hold", description: "Hold for 30+ seconds", targetHoldDuration: 30),
                SkillProgressionLevel(level: 2, name: "Pike Push-ups", description: "3 sets of 8-12 reps", targetReps: 10),
                SkillProgressionLevel(level: 3, name: "Wall Handstand Push-ups", description: "3 sets of 3-5 reps", targetReps: 4),
                SkillProgressionLevel(level: 4, name: "Freestanding Handstand Push-ups", description: "3 sets of 1-3 reps", targetReps: 2),
                SkillProgressionLevel(level: 5, name: "One-Arm Handstand Push-up", description: "Master level", targetReps: 1)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .push
        ),
        CalisthenicsSkill(
            name: "Muscle Up",
            icon: "figure.climbing",
            description: "Combine pull and push strength",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Pull-ups", description: "3 sets of 8-12 reps", targetReps: 10),
                SkillProgressionLevel(level: 2, name: "Chin-ups", description: "3 sets of 8-12 reps", targetReps: 10),
                SkillProgressionLevel(level: 3, name: "Negative Muscle Ups", description: "3 sets of 3-5 reps", targetReps: 4),
                SkillProgressionLevel(level: 4, name: "Assisted Muscle Ups", description: "3 sets of 2-3 reps", targetReps: 2),
                SkillProgressionLevel(level: 5, name: "Full Muscle Up", description: "3 sets of 1-3 reps", targetReps: 2)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .pull
        ),
        CalisthenicsSkill(
            name: "Front Lever",
            icon: "figure.flexibility",
            description: "Develop exceptional core and pulling strength",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Tuck Front Lever", description: "Hold for 15+ seconds", targetHoldDuration: 15),
                SkillProgressionLevel(level: 2, name: "Advanced Tuck Front Lever", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 3, name: "One-Leg Front Lever", description: "Hold for 8+ seconds", targetHoldDuration: 8),
                SkillProgressionLevel(level: 4, name: "Straddle Front Lever", description: "Hold for 5+ seconds", targetHoldDuration: 5),
                SkillProgressionLevel(level: 5, name: "Full Front Lever", description: "Hold for 3+ seconds", targetHoldDuration: 3)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .pull
        ),
        CalisthenicsSkill(
            name: "Back Lever",
            icon: "figure.balance",
            description: "Master the back lever position",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Tuck Back Lever", description: "Hold for 15+ seconds", targetHoldDuration: 15),
                SkillProgressionLevel(level: 2, name: "Advanced Tuck Back Lever", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 3, name: "One-Leg Back Lever", description: "Hold for 8+ seconds", targetHoldDuration: 8),
                SkillProgressionLevel(level: 4, name: "Straddle Back Lever", description: "Hold for 5+ seconds", targetHoldDuration: 5),
                SkillProgressionLevel(level: 5, name: "Full Back Lever", description: "Hold for 3+ seconds", targetHoldDuration: 3)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .pull
        ),
        CalisthenicsSkill(
            name: "Human Flag",
            icon: "flag.fill",
            description: "Ultimate core and shoulder strength",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Side Plank", description: "Hold for 30+ seconds each side", targetHoldDuration: 30),
                SkillProgressionLevel(level: 2, name: "Elevated Side Plank", description: "Hold for 20+ seconds", targetHoldDuration: 20),
                SkillProgressionLevel(level: 3, name: "Tucked Human Flag", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 4, name: "One-Leg Human Flag", description: "Hold for 5+ seconds", targetHoldDuration: 5),
                SkillProgressionLevel(level: 5, name: "Full Human Flag", description: "Hold for 3+ seconds", targetHoldDuration: 3)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .core
        ),
        CalisthenicsSkill(
            name: "L-Sit",
            icon: "figure.seated.side",
            description: "Build core and hip flexor strength",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Tucked L-Sit", description: "Hold for 20+ seconds", targetHoldDuration: 20),
                SkillProgressionLevel(level: 2, name: "One-Leg L-Sit", description: "Hold for 15+ seconds", targetHoldDuration: 15),
                SkillProgressionLevel(level: 3, name: "L-Sit", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 4, name: "V-Sit", description: "Hold for 5+ seconds", targetHoldDuration: 5),
                SkillProgressionLevel(level: 5, name: "Manna", description: "Advanced L-sit variation", targetHoldDuration: 3)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .core
        ),
        CalisthenicsSkill(
            name: "Handstand",
            icon: "figure.handstand",
            description: "Master balance and body control",
            progressionLevels: [
                SkillProgressionLevel(level: 1, name: "Wall Handstand", description: "Hold for 30+ seconds", targetHoldDuration: 30),
                SkillProgressionLevel(level: 2, name: "Chest-to-Wall Handstand", description: "Hold for 20+ seconds", targetHoldDuration: 20),
                SkillProgressionLevel(level: 3, name: "Kick-up Practice", description: "Practice balance", targetHoldDuration: 10),
                SkillProgressionLevel(level: 4, name: "Freestanding Handstand", description: "Hold for 10+ seconds", targetHoldDuration: 10),
                SkillProgressionLevel(level: 5, name: "One-Arm Handstand", description: "Master level", targetHoldDuration: 5)
            ],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs",
            category: .fullBody
        )
    ]
    
    private init() {
        loadCustomSkills()
    }
    
    // MARK: - Persistence
    private func loadCustomSkills() {
        var allSkills = builtInSkills
        
        if let data = UserDefaults.standard.data(forKey: customSkillsKey),
           let customSkills = try? JSONDecoder().decode([CalisthenicsSkill].self, from: data) {
            allSkills.append(contentsOf: customSkills)
        }
        
        skills = allSkills
    }
    
    private func saveCustomSkills() {
        let customSkills = skills.filter { $0.isCustom }
        if let data = try? JSONEncoder().encode(customSkills) {
            UserDefaults.standard.set(data, forKey: customSkillsKey)
        }
    }
    
    // MARK: - Public Methods
    func addCustomSkill(_ skill: CalisthenicsSkill) {
        var customSkill = skill
        // Ensure the skill is marked as custom
        if !customSkill.isCustom {
            customSkill = CalisthenicsSkill(
                id: skill.id,
                name: skill.name,
                icon: skill.icon,
                description: skill.description,
                progressionLevels: skill.progressionLevels,
                videoURL: skill.videoURL,
                category: skill.category,
                isCustom: true
            )
        }
        skills.append(customSkill)
        saveCustomSkills()
    }
    
    func deleteCustomSkill(_ skill: CalisthenicsSkill) {
        guard skill.isCustom else { return }
        skills.removeAll { $0.id == skill.id }
        saveCustomSkills()
    }
    
    func getSkill(named name: String) -> CalisthenicsSkill? {
        return skills.first { $0.name == name }
    }
    
    func getSkillsByCategory(_ category: CalisthenicsSkill.SkillCategory) -> [CalisthenicsSkill] {
        return skills.filter { $0.category == category }
    }
}

