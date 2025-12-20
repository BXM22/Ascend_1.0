//
//  ColorPalette.swift
//  Ascend
//
//  Model for custom color palettes that can be saved and reused
//

import Foundation

struct ColorPalette: Identifiable, Codable {
    let id: UUID
    var name: String
    var colors: [String] // Hex color strings
    var createdAt: Date
    var isDefault: Bool // True if this is the default palette for new templates
    
    // Custom coding keys to handle isDefault properly
    enum CodingKeys: String, CodingKey {
        case id, name, colors, createdAt, isDefault
    }
    
    init(id: UUID = UUID(), name: String, colors: [String], createdAt: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.colors = colors
        self.createdAt = createdAt
        self.isDefault = isDefault
    }
    
    /// Validate that all colors are valid hex strings
    func isValid() -> Bool {
        guard !colors.isEmpty else { return false }
        return colors.allSatisfy { hex in
            let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
            return cleaned.count == 6 && cleaned.allSatisfy { "0123456789ABCDEF".contains($0) }
        }
    }
}

