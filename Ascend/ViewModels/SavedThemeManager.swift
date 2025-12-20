//
//  SavedThemeManager.swift
//  Ascend
//
//  Manager for saved color themes persistence and management
//

import Foundation
import SwiftUI
import Combine

class SavedThemeManager: ObservableObject {
    static let shared = SavedThemeManager()
    
    @Published var themes: [ColorTheme] = [] {
        didSet {
            saveThemes()
        }
    }
    
    private let themesKey = "savedColorThemes"
    
    private init() {
        loadThemes()
    }
    
    // MARK: - Public Methods
    
    /// Add a new theme
    func addTheme(_ theme: ColorTheme) {
        themes.append(theme)
    }
    
    /// Update an existing theme
    func updateTheme(_ theme: ColorTheme) {
        if let index = themes.firstIndex(where: { $0.id == theme.id }) {
            themes[index] = theme
        }
    }
    
    /// Delete a theme
    func deleteTheme(_ theme: ColorTheme) {
        themes.removeAll { $0.id == theme.id }
    }
    
    /// Delete theme by ID
    func deleteTheme(id: UUID) {
        themes.removeAll { $0.id == id }
    }
    
    // MARK: - Persistence
    
    private func loadThemes() {
        guard let data = UserDefaults.standard.data(forKey: themesKey) else {
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([ColorTheme].self, from: data)
            themes = decoded
        } catch {
            Logger.error("Failed to load saved themes", error: error, category: .persistence)
        }
    }
    
    private func saveThemes() {
        do {
            let encoded = try JSONEncoder().encode(themes)
            UserDefaults.standard.set(encoded, forKey: themesKey)
        } catch {
            Logger.error("Failed to save themes", error: error, category: .persistence)
        }
    }
}
