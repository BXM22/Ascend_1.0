//
//  ColorPaletteManager.swift
//  Ascend
//
//  Manager for custom color palette persistence and management
//

import Foundation
import SwiftUI
import Combine

class ColorPaletteManager: ObservableObject {
    static let shared = ColorPaletteManager()
    
    @Published var palettes: [ColorPalette] = [] {
        didSet {
            savePalettes()
        }
    }
    
    @Published var defaultPaletteId: UUID? {
        didSet {
            saveDefaultPaletteId()
        }
    }
    
    private let palettesKey = "savedColorPalettes"
    private let defaultPaletteKey = "defaultColorPaletteId"
    
    private init() {
        loadPalettes()
    }
    
    // MARK: - Public Methods
    
    /// Get the default palette for new templates
    var defaultPalette: ColorPalette? {
        if let id = defaultPaletteId,
           let palette = palettes.first(where: { $0.id == id }) {
            return palette
        }
        return nil
    }
    
    /// Add a new palette
    func addPalette(_ palette: ColorPalette) {
        palettes.append(palette)
    }
    
    /// Update an existing palette
    func updatePalette(_ palette: ColorPalette) {
        if let index = palettes.firstIndex(where: { $0.id == palette.id }) {
            palettes[index] = palette
        }
    }
    
    /// Delete a palette
    func deletePalette(_ palette: ColorPalette) {
        palettes.removeAll { $0.id == palette.id }
        // Clear default if it was the deleted palette
        if defaultPaletteId == palette.id {
            defaultPaletteId = nil
        }
    }
    
    /// Set a palette as default for new templates
    func setDefaultPalette(_ palette: ColorPalette) {
        defaultPaletteId = palette.id
        // Update isDefault flag
        for i in 0..<palettes.count {
            palettes[i].isDefault = (palettes[i].id == palette.id)
        }
    }
    
    /// Clear default palette
    func clearDefaultPalette() {
        defaultPaletteId = nil
        for i in 0..<palettes.count {
            palettes[i].isDefault = false
        }
    }
    
    /// Reorder palettes
    func movePalette(from source: IndexSet, to destination: Int) {
        palettes.move(fromOffsets: source, toOffset: destination)
    }
    
    // MARK: - Persistence
    
    private func loadPalettes() {
        guard let data = UserDefaults.standard.data(forKey: palettesKey) else {
            return
        }
        
        do {
            var decoded = try JSONDecoder().decode([ColorPalette].self, from: data)
            
            // Load default palette ID and sync isDefault flags
            if let uuidString = UserDefaults.standard.string(forKey: defaultPaletteKey),
               let uuid = UUID(uuidString: uuidString) {
                defaultPaletteId = uuid
                // Sync isDefault flags
                for i in 0..<decoded.count {
                    decoded[i].isDefault = (decoded[i].id == uuid)
                }
            }
            
            palettes = decoded
        } catch {
            Logger.error("Failed to load color palettes", error: error, category: .persistence)
        }
    }
    
    private func savePalettes() {
        do {
            let encoded = try JSONEncoder().encode(palettes)
            UserDefaults.standard.set(encoded, forKey: palettesKey)
        } catch {
            Logger.error("Failed to save color palettes", error: error, category: .persistence)
        }
    }
    
    private func saveDefaultPaletteId() {
        if let id = defaultPaletteId {
            UserDefaults.standard.set(id.uuidString, forKey: defaultPaletteKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultPaletteKey)
        }
    }
}

