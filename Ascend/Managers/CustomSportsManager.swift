import Foundation
import Combine

/// Manager for custom sports timer configurations
class CustomSportsManager: ObservableObject {
    static let shared = CustomSportsManager()
    
    @Published var customSports: [CustomSport] = []
    
    private let customSportsKey = "customSportsTimerConfigs"
    
    private init() {
        loadCustomSports()
    }
    
    // MARK: - Persistence
    
    func saveCustomSports() {
        do {
            let encoded = try JSONEncoder().encode(customSports)
            UserDefaults.standard.set(encoded, forKey: customSportsKey)
        } catch {
            Logger.error("Failed to save custom sports", error: error, category: .persistence)
        }
    }
    
    private func loadCustomSports() {
        guard let data = UserDefaults.standard.data(forKey: customSportsKey) else {
            customSports = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([CustomSport].self, from: data)
            customSports = decoded
        } catch {
            Logger.error("Failed to load custom sports", error: error, category: .persistence)
            customSports = []
        }
    }
    
    // MARK: - CRUD Operations
    
    func addCustomSport(_ sport: CustomSport) {
        customSports.append(sport)
        saveCustomSports()
    }
    
    func updateCustomSport(_ sport: CustomSport) {
        if let index = customSports.firstIndex(where: { $0.id == sport.id }) {
            customSports[index] = sport
            saveCustomSports()
        }
    }
    
    func deleteCustomSport(_ sport: CustomSport) {
        customSports.removeAll { $0.id == sport.id }
        saveCustomSports()
    }
    
    func getCustomSport(byId id: UUID) -> CustomSport? {
        return customSports.first { $0.id == id }
    }
}

// MARK: - Custom Sport Model

struct CustomSport: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var roundDuration: Int // in seconds
    var restDuration: Int // in seconds
    var numberOfRounds: Int
    var roundLabel: String
    var restLabel: String
    var icon: String
    
    init(
        id: UUID = UUID(),
        name: String,
        roundDuration: Int,
        restDuration: Int,
        numberOfRounds: Int,
        roundLabel: String = "Round",
        restLabel: String = "Rest",
        icon: String = "figure.martial.arts"
    ) {
        self.id = id
        self.name = name
        self.roundDuration = roundDuration
        self.restDuration = restDuration
        self.numberOfRounds = numberOfRounds
        self.roundLabel = roundLabel
        self.restLabel = restLabel
        self.icon = icon
    }
    
    func toSportsTimerConfig() -> SportsTimerConfig {
        // Create config with placeholder sport - the view model will use custom sport data
        return SportsTimerConfig(
            sport: .boxing, // Placeholder - actual sport data comes from CustomSport
            roundDuration: roundDuration,
            restDuration: restDuration,
            numberOfRounds: numberOfRounds,
            roundLabel: roundLabel,
            restLabel: restLabel
        )
    }
    
    var displayName: String {
        return name
    }
    
    var displayIcon: String {
        return icon
    }
}
