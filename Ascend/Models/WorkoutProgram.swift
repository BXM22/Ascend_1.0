import Foundation

// MARK: - Workout Day
struct WorkoutDay: Identifiable, Codable {
    let id: UUID
    let dayNumber: Int
    let name: String
    var description: String
    var exercises: [ProgramExercise]
    var estimatedDuration: Int
    var templateId: UUID? // Reference to a WorkoutTemplate
    var isRestDay: Bool
    
    init(dayNumber: Int, name: String, description: String, exercises: [ProgramExercise] = [], estimatedDuration: Int = 0, templateId: UUID? = nil, isRestDay: Bool = false) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.name = name
        self.description = description
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.templateId = templateId
        self.isRestDay = isRestDay
    }
}

// MARK: - Program Exercise
struct ProgramExercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: String // Can be "6-8", "3-5", "10-12", etc.
    let notes: String?
    let exerciseType: ExerciseType
    let targetHoldDuration: Int?
    
    init(id: UUID = UUID(), name: String, sets: Int, reps: String, notes: String? = nil, exerciseType: ExerciseType = .weightReps, targetHoldDuration: Int? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.notes = notes
        self.exerciseType = exerciseType
        self.targetHoldDuration = targetHoldDuration
    }
}

// MARK: - Workout Program
struct WorkoutProgram: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var days: [WorkoutDay]
    var frequency: String // e.g., "2-3 cycles per week"
    var category: ProgramCategory
    var splitType: WorkoutSplitType?
    
    enum ProgramCategory: String, Codable {
        case calisthenics = "Calisthenics"
        case strength = "Strength"
        case hypertrophy = "Hypertrophy"
        case skill = "Skill Progression"
        case split = "Split"
    }
    
    init(id: UUID = UUID(), name: String, description: String, days: [WorkoutDay], frequency: String, category: ProgramCategory, splitType: WorkoutSplitType? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.days = days
        self.frequency = frequency
        self.category = category
        self.splitType = splitType
    }
}

// MARK: - Workout Program Manager
class WorkoutProgramManager {
    static let shared = WorkoutProgramManager()
    
    let programs: [WorkoutProgram] = [
        WorkoutProgram(
            name: "2-Day Muscle-Up Progression Split",
            description: "Build explosive pull power and master the muscle-up transition",
            days: [
                // DAY 1
                WorkoutDay(
                    dayNumber: 1,
                    name: "Pull Power + Transition Prep",
                    description: "Build pull power, transition familiarity, and dip lockout strength",
                    exercises: [
                        // Warm-Up
                        ProgramExercise(name: "Scapular Pull-Ups", sets: 2, reps: "10", notes: "Warm-up"),
                        ProgramExercise(name: "Band Shoulder Rotations", sets: 2, reps: "15 each", notes: "Warm-up"),
                        ProgramExercise(name: "Light Explosive Dead Hang Pulls", sets: 2, reps: "5", notes: "Warm-up"),
                        
                        // A. Pull Strength Foundation
                        ProgramExercise(name: "Strict Pull-Ups", sets: 4, reps: "6-8", notes: "Full range, chest lifted, clean tempo. Progress when 8 reps feel easy."),
                        ProgramExercise(name: "High Pull-Ups (Chest-To-Bar)", sets: 4, reps: "3-5", notes: "Pull as high as possible. Builds explosive 'clear the bar' height."),
                        
                        // B. Pull Explosiveness
                        ProgramExercise(name: "Explosive Pull-Ups", sets: 3, reps: "3-5", notes: "Try to get lower chest up. Use bands if needed."),
                        
                        // C. Transition Training
                        ProgramExercise(name: "Jump-Assisted Muscle-Ups", sets: 4, reps: "3-5", notes: "Use low bar, jump lightly, focus on smooth transition."),
                        ProgramExercise(name: "Muscle-Up Negatives", sets: 3, reps: "2-3", notes: "Slowly lower through transition (3-5 seconds)."),
                        
                        // D. Accessory Strength
                        ProgramExercise(name: "Straight Bar Dips", sets: 4, reps: "5-8", notes: "Build the press-out portion."),
                        ProgramExercise(name: "Hanging Knee or L-Raises", sets: 3, reps: "10-12", notes: "Core work", exerciseType: .weightReps)
                    ],
                    estimatedDuration: 60
                ),
                
                // DAY 2
                WorkoutDay(
                    dayNumber: 2,
                    name: "Technique + Strength Volume",
                    description: "Focus on technique refinement and building strength volume",
                    exercises: [
                        // Warm-Up
                        ProgramExercise(name: "False Grip Hangs", sets: 2, reps: "20s", notes: "Warm-up (optional)", exerciseType: .hold, targetHoldDuration: 20),
                        ProgramExercise(name: "Shoulder Band Warm-up", sets: 2, reps: "15", notes: "Warm-up"),
                        
                        // A. Technical Work
                        ProgramExercise(name: "Slow Pull-Up Negatives", sets: 3, reps: "3", notes: "8-10 second descent. Great for tendon + transition strength."),
                        ProgramExercise(name: "Transition Rows (Bar at Chest Height)", sets: 3, reps: "6-8", notes: "Feet in front, row into transition. Mimics pull → turn over → dip."),
                        
                        // B. Strength Volume
                        ProgramExercise(name: "Pull-Ups (Volume Work)", sets: 5, reps: "5", notes: "Controlled reps. Builds strength base."),
                        ProgramExercise(name: "Bar Dips", sets: 4, reps: "8-10", notes: "More volume → better lockout strength."),
                        
                        // C. Advanced Progression (user selects level)
                        ProgramExercise(name: "Band-Assisted Muscle-Ups", sets: 3, reps: "3-5", notes: "Level 1: Beginner - Focus on clean technique."),
                        ProgramExercise(name: "Explosive Chest-to-Bar Pull-Ups", sets: 4, reps: "3", notes: "Level 2: Intermediate - Pull higher than Day 1."),
                        ProgramExercise(name: "Single Rep Muscle-Up Attempts", sets: 6, reps: "1", notes: "Level 3: Close to Muscle-Up - Rest 60-90s between. Keep attempts clean."),
                        
                        // D. Accessory
                        ProgramExercise(name: "Front Lever Tuck Raises", sets: 3, reps: "5-8", notes: "Optional but helps pull explosiveness + lat control."),
                        ProgramExercise(name: "Toes-to-Bar or Knee Raises", sets: 3, reps: "8-12", notes: "Core work", exerciseType: .weightReps)
                    ],
                    estimatedDuration: 60
                )
            ],
            frequency: "2-3 cycles per week (e.g., Mon = Day 1, Thu = Day 2)",
            category: .skill
        ),
        
        WorkoutProgram(
            name: "Example PPL Split",
            description: "Classic push / pull / legs rotation for balanced hypertrophy. Run once per week (3 days) or repeat for 6 training days.",
            days: [
                WorkoutDay(
                    dayNumber: 1,
                    name: "Push",
                    description: "Chest, shoulders, triceps — horizontal and vertical pressing",
                    exercises: [
                        ProgramExercise(name: "Barbell Bench Press", sets: 4, reps: "6-8", notes: "Primary press; add weight when you clear top of range."),
                        ProgramExercise(name: "Overhead Press", sets: 3, reps: "8-10", notes: "Standing or seated; full lockout."),
                        ProgramExercise(name: "Incline Dumbbell Press", sets: 3, reps: "10-12", notes: "30–45° bench."),
                        ProgramExercise(name: "Lateral Raise", sets: 3, reps: "12-15", notes: "Control the negative."),
                        ProgramExercise(name: "Tricep Pushdown", sets: 3, reps: "10-12", notes: "Rope or bar; elbows fixed."),
                        ProgramExercise(name: "Cable Fly", sets: 2, reps: "12-15", notes: "Optional finisher", exerciseType: .weightReps)
                    ],
                    estimatedDuration: 70
                ),
                WorkoutDay(
                    dayNumber: 2,
                    name: "Pull",
                    description: "Back and biceps — rows, vertical pulls, arms",
                    exercises: [
                        ProgramExercise(name: "Barbell Row", sets: 4, reps: "6-8", notes: "Hip hinge; torso ~45°."),
                        ProgramExercise(name: "Lat Pulldown", sets: 3, reps: "10-12", notes: "Chest up; full stretch at top."),
                        ProgramExercise(name: "Seated Cable Row", sets: 3, reps: "10-12", notes: "Squeeze shoulder blades."),
                        ProgramExercise(name: "Face Pull", sets: 3, reps: "15-20", notes: "Rear delts + external rotation."),
                        ProgramExercise(name: "Barbell Curl", sets: 3, reps: "8-10", notes: "No swing."),
                        ProgramExercise(name: "Hammer Curl", sets: 3, reps: "10-12", notes: "Neutral grip.", exerciseType: .weightReps)
                    ],
                    estimatedDuration: 65
                ),
                WorkoutDay(
                    dayNumber: 3,
                    name: "Legs",
                    description: "Quads, hamstrings, glutes, calves",
                    exercises: [
                        ProgramExercise(name: "Back Squat", sets: 4, reps: "6-8", notes: "Depth you own; brace hard."),
                        ProgramExercise(name: "Romanian Deadlift", sets: 3, reps: "8-10", notes: "Hamstrings; soft knee bend."),
                        ProgramExercise(name: "Leg Press", sets: 3, reps: "12-15", notes: "Full foot contact."),
                        ProgramExercise(name: "Leg Curl", sets: 3, reps: "10-12", notes: "Lying or seated."),
                        ProgramExercise(name: "Standing Calf Raise", sets: 4, reps: "10-12", notes: "Pause at bottom.", exerciseType: .weightReps)
                    ],
                    estimatedDuration: 70
                )
            ],
            frequency: "3–6× per week (one P–P–L cycle, or run twice)",
            category: .hypertrophy,
            splitType: .pushPullLegs
        ),
        
        WorkoutProgram(
            name: "Example Upper / Lower Split",
            description: "Four-day upper–lower block: two upper and two lower sessions with slightly different emphasis for balanced weekly volume.",
            days: [
                WorkoutDay(
                    dayNumber: 1,
                    name: "Upper A",
                    description: "Heavy horizontal push & pull",
                    exercises: [
                        ProgramExercise(name: "Barbell Bench Press", sets: 4, reps: "6-8", notes: "Primary strength work."),
                        ProgramExercise(name: "Barbell Row", sets: 4, reps: "6-8", notes: "Match bench effort."),
                        ProgramExercise(name: "Lat Pulldown", sets: 3, reps: "10-12", notes: nil),
                        ProgramExercise(name: "Lateral Raise", sets: 3, reps: "12-15", notes: nil),
                        ProgramExercise(name: "Tricep Rope Pushdown", sets: 3, reps: "10-12", notes: nil, exerciseType: .weightReps)
                    ],
                    estimatedDuration: 65
                ),
                WorkoutDay(
                    dayNumber: 2,
                    name: "Lower A",
                    description: "Squat-biased leg day",
                    exercises: [
                        ProgramExercise(name: "Back Squat", sets: 4, reps: "6-8", notes: "Primary lower lift."),
                        ProgramExercise(name: "Romanian Deadlift", sets: 3, reps: "8-10", notes: "Posterior chain."),
                        ProgramExercise(name: "Leg Curl", sets: 3, reps: "10-12", notes: nil),
                        ProgramExercise(name: "Standing Calf Raise", sets: 4, reps: "10-12", notes: nil, exerciseType: .weightReps)
                    ],
                    estimatedDuration: 60
                ),
                WorkoutDay(
                    dayNumber: 3,
                    name: "Upper B",
                    description: "Incline & vertical pull + arms",
                    exercises: [
                        ProgramExercise(name: "Incline Dumbbell Press", sets: 4, reps: "8-10", notes: "30–45° bench."),
                        ProgramExercise(name: "Pull-Ups", sets: 4, reps: "AMRAP", notes: "Band-assisted if needed."),
                        ProgramExercise(name: "Seated Cable Row", sets: 3, reps: "10-12", notes: nil),
                        ProgramExercise(name: "Face Pull", sets: 3, reps: "15-20", notes: nil),
                        ProgramExercise(name: "Hammer Curl", sets: 3, reps: "10-12", notes: nil, exerciseType: .weightReps)
                    ],
                    estimatedDuration: 60
                ),
                WorkoutDay(
                    dayNumber: 4,
                    name: "Lower B",
                    description: "Hinge & machine volume",
                    exercises: [
                        ProgramExercise(name: "Leg Press", sets: 4, reps: "12-15", notes: "High foot placement optional for glutes."),
                        ProgramExercise(name: "Walking Lunge", sets: 3, reps: "10 each", notes: "Bodyweight or DB."),
                        ProgramExercise(name: "Leg Extension", sets: 3, reps: "12-15", notes: nil),
                        ProgramExercise(name: "Seated Calf Raise", sets: 4, reps: "12-15", notes: nil, exerciseType: .weightReps)
                    ],
                    estimatedDuration: 55
                )
            ],
            frequency: "4× per week (e.g. Mon Tue Thu Fri)",
            category: .hypertrophy,
            splitType: .upperLower
        )
    ]
    
    private init() {}
    
    func getProgram(named name: String) -> WorkoutProgram? {
        return programs.first { $0.name == name }
    }
    
    func getProgramsByCategory(_ category: WorkoutProgram.ProgramCategory) -> [WorkoutProgram] {
        return programs.filter { $0.category == category }
    }
}



