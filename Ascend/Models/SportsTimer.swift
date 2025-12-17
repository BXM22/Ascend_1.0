import Foundation

// MARK: - Sports Timer Models

enum SportType: String, CaseIterable, Identifiable, Codable {
    case boxing = "Boxing"
    case mma = "MMA"
    case wrestling = "Wrestling"
    case muayThai = "Muay Thai"
    case brazilianJiuJitsu = "Brazilian Jiu-Jitsu"
    case kickboxing = "Kickboxing"
    case taekwondo = "Taekwondo"
    case karate = "Karate"
    case judo = "Judo"
    case mmaGrappling = "MMA Grappling"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .boxing: return "figure.boxing"
        case .mma: return "figure.mixed.cardio"
        case .wrestling: return "figure.wrestling"
        case .muayThai: return "figure.martial.arts"
        case .brazilianJiuJitsu: return "figure.yoga"
        case .kickboxing: return "figure.kickboxing"
        case .taekwondo: return "figure.martial.arts"
        case .karate: return "figure.martial.arts"
        case .judo: return "figure.yoga"
        case .mmaGrappling: return "figure.mixed.cardio"
        }
    }
    
    var defaultConfig: SportsTimerConfig {
        switch self {
        case .boxing:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 180, // 3 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 12,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .mma:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 300, // 5 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 5,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .wrestling:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 120, // 2 minutes
                restDuration: 30, // 30 seconds
                numberOfRounds: 3,
                roundLabel: "Period",
                restLabel: "Rest"
            )
        case .muayThai:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 180, // 3 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 5,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .brazilianJiuJitsu:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 300, // 5 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 1,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .kickboxing:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 180, // 3 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 5,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .taekwondo:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 120, // 2 minutes
                restDuration: 30, // 30 seconds
                numberOfRounds: 3,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .karate:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 120, // 2 minutes
                restDuration: 30, // 30 seconds
                numberOfRounds: 3,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        case .judo:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 240, // 4 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 1,
                roundLabel: "Match",
                restLabel: "Rest"
            )
        case .mmaGrappling:
            return SportsTimerConfig(
                sport: self,
                roundDuration: 300, // 5 minutes
                restDuration: 60, // 1 minute
                numberOfRounds: 1,
                roundLabel: "Round",
                restLabel: "Rest"
            )
        }
    }
}

struct SportsTimerConfig: Codable, Equatable {
    let sport: SportType
    var roundDuration: Int // in seconds
    var restDuration: Int // in seconds
    var numberOfRounds: Int
    var roundLabel: String
    var restLabel: String
    
    var totalDuration: Int {
        // Total = (roundDuration + restDuration) * numberOfRounds - restDuration (last round has no rest)
        return (roundDuration + restDuration) * numberOfRounds - restDuration
    }
}

enum TimerPhase: String {
    case round = "Round"
    case rest = "Rest"
    case completed = "Completed"
}

struct TimerState {
    var currentRound: Int
    var currentPhase: TimerPhase
    var timeRemaining: Int
    var totalRounds: Int
    var isActive: Bool
    var isPaused: Bool
    var startTime: Date?
    var config: SportsTimerConfig?
    
    var progress: Double {
        guard let startTime = startTime, let config = config else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        let currentPhaseDuration = currentPhase == .round ? 
            config.roundDuration : config.restDuration
        guard currentPhaseDuration > 0 else { return 0 }
        return min(1.0, elapsed / Double(currentPhaseDuration))
    }
}
