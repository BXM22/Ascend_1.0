import Foundation

class ExerciseDataManager {
    static let shared = ExerciseDataManager()
    
    // Exercise database with alternatives and video URLs
    private let exerciseDatabase: [String: ExerciseInfo] = [
        "Bench Press": ExerciseInfo(
            alternatives: ["Push-ups", "Dumbbell Press", "Incline Push-ups"],
            videoURL: "https://www.youtube.com/watch?v=rT7DgCr-3pg"
        ),
        "Squat": ExerciseInfo(
            alternatives: ["Bodyweight Squat", "Jump Squats", "Lunges"],
            videoURL: "https://www.youtube.com/watch?v=YaXPRqUwItQ"
        ),
        "Deadlift": ExerciseInfo(
            alternatives: ["Romanian Deadlift", "Good Mornings", "Hip Thrusts"],
            videoURL: "https://www.youtube.com/watch?v=op9kVnSso6Q"
        ),
        "Shoulder Press": ExerciseInfo(
            alternatives: ["Pike Push-ups", "Handstand Push-ups", "Dumbbell Press"],
            videoURL: "https://www.youtube.com/watch?v=qEwKCR5JCog"
        ),
        "Barbell Row": ExerciseInfo(
            alternatives: ["Inverted Rows", "Dumbbell Rows", "Pull-ups"],
            videoURL: "https://www.youtube.com/watch?v=9efgcAjQe7E"
        ),
        "Pull-ups": ExerciseInfo(
            alternatives: ["Inverted Rows", "Assisted Pull-ups", "Lat Pulldowns"],
            videoURL: "https://www.youtube.com/watch?v=eGo4IYlbE5g"
        ),
        "Plank": ExerciseInfo(
            alternatives: ["Side Plank", "Mountain Climbers", "Hollow Hold"],
            videoURL: "https://www.youtube.com/watch?v=pSHjTRCQxIw"
        ),
        "Bicep Curl": ExerciseInfo(
            alternatives: ["Resistance Band Curls", "Bodyweight Curls", "Chin-ups"],
            videoURL: "https://www.youtube.com/watch?v=ykJmrZ5v0Oo"
        ),
        "Tricep Extension": ExerciseInfo(
            alternatives: ["Diamond Push-ups", "Overhead Extension", "Dips"],
            videoURL: "https://www.youtube.com/watch?v=6kALZikXxLc"
        ),
        "Leg Press": ExerciseInfo(
            alternatives: ["Squats", "Lunges", "Step-ups"],
            videoURL: "https://www.youtube.com/watch?v=IZxyjW7MPJQ"
        ),
        
        // Calisthenics Skills
        "Planche": ExerciseInfo(
            alternatives: ["Frog Stand", "Tuck Planche", "Push-ups"],
            videoURL: "https://www.youtube.com/watch?v=w6x_GdS1XRs"
        ),
        "Handstand Push-up": ExerciseInfo(
            alternatives: ["Pike Push-ups", "Wall Handstand", "Dips"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "Muscle Up": ExerciseInfo(
            alternatives: ["Pull-ups", "Chin-ups", "Dips"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "Front Lever": ExerciseInfo(
            alternatives: ["Tuck Front Lever", "Hanging Leg Raises", "Pull-ups"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "Back Lever": ExerciseInfo(
            alternatives: ["Tuck Back Lever", "Skin the Cat", "Pull-ups"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "Human Flag": ExerciseInfo(
            alternatives: ["Side Plank", "Tucked Human Flag", "Core Work"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "L-Sit": ExerciseInfo(
            alternatives: ["Tucked L-Sit", "V-Sit", "Hanging Leg Raises"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        ),
        "Handstand": ExerciseInfo(
            alternatives: ["Wall Handstand", "Chest-to-Wall", "Balance Practice"],
            videoURL: "https://www.youtube.com/watch?v=4-B2X3dN3zs"
        )
    ]
    
    private init() {}
    
    func getAlternatives(for exerciseName: String) -> [String] {
        var alternatives: [String] = []
        
        // Check exact match first in local database
        if let info = exerciseDatabase[exerciseName] {
            alternatives.append(contentsOf: info.alternatives)
        }
        
        // Check if it's a skill progression exercise (e.g., "Planche - Tuck Planche")
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                alternatives.append(contentsOf: info.alternatives)
            }
        }
        
        // If no alternatives found, check ExRx directory
        if alternatives.isEmpty {
            let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
            alternatives.append(contentsOf: exRxAlternatives)
        } else {
            // Merge with ExRx alternatives, avoiding duplicates
            let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
            for alt in exRxAlternatives {
                if !alternatives.contains(alt) {
                    alternatives.append(alt)
                }
            }
        }
        
        return alternatives
    }
    
    func getVideoURL(for exerciseName: String) -> String? {
        // Check exact match first
        if let info = exerciseDatabase[exerciseName] {
            return info.videoURL
        }
        
        // Check if it's a skill progression exercise
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                return info.videoURL
            }
        }
        
        // Check calisthenics skills
        for skill in CalisthenicsSkillManager.shared.skills {
            if exerciseName.contains(skill.name) {
                return skill.videoURL
            }
        }
        
        return nil
    }
    
    func hasAlternatives(for exerciseName: String) -> Bool {
        // Check local database first
        if let info = exerciseDatabase[exerciseName] {
            return !info.alternatives.isEmpty
        }
        
        // Check skill progression
        for (skillName, info) in exerciseDatabase {
            if exerciseName.contains(skillName) {
                return !info.alternatives.isEmpty
            }
        }
        
        // Check ExRx directory
        let exRxAlternatives = ExRxDirectoryManager.shared.getAlternatives(for: exerciseName)
        return !exRxAlternatives.isEmpty
    }
    
    // Get ExRx URL for an exercise
    func getExRxURL(for exerciseName: String) -> String? {
        return ExRxDirectoryManager.shared.getExRxURL(for: exerciseName)
    }
    
    // Search ExRx directory
    func searchExRxDirectory(query: String) -> [ExRxExercise] {
        return ExRxDirectoryManager.shared.searchExercises(query: query)
    }
    
    func hasVideo(for exerciseName: String) -> Bool {
        return getVideoURL(for: exerciseName) != nil
    }
}

struct ExerciseInfo {
    let alternatives: [String]
    let videoURL: String?
}


