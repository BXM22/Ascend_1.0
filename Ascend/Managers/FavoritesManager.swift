import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published private(set) var favoriteExercises: [String] = []
    
    private let favoritesKey = "favoriteExercises"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadFavorites()
        setupAutoSave()
    }
    
    /// Check if an exercise is favorited
    func isFavorite(_ exerciseName: String) -> Bool {
        return favoriteExercises.contains(exerciseName)
    }
    
    /// Toggle favorite status for an exercise
    func toggleFavorite(_ exerciseName: String) {
        if isFavorite(exerciseName) {
            favoriteExercises.removeAll { $0 == exerciseName }
        } else {
            favoriteExercises.append(exerciseName)
        }
    }
    
    /// Add exercise to favorites
    func addFavorite(_ exerciseName: String) {
        if !isFavorite(exerciseName) {
            favoriteExercises.append(exerciseName)
        }
    }
    
    /// Remove exercise from favorites
    func removeFavorite(_ exerciseName: String) {
        favoriteExercises.removeAll { $0 == exerciseName }
    }
    
    /// Clear all favorites
    func clearAllFavorites() {
        favoriteExercises.removeAll()
    }
    
    private func setupAutoSave() {
        $favoriteExercises
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveFavorites()
            }
            .store(in: &cancellables)
    }
    
    private func saveFavorites() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(self.favoriteExercises, forKey: self.favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let favorites = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteExercises = favorites
        } else {
            favoriteExercises = []
        }
    }
}

