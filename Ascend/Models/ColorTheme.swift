import SwiftUI

struct ColorTheme: Codable, Identifiable {
    let id: UUID
    var name: String
    var colors: [String] // Hex color strings
    
    // Map colors to semantic roles
    // Expected order: [background, card, primary, accent, textPrimary, textSecondary]
    // Or we can use a more flexible approach with 5 colors from Coolors
    
    init(id: UUID = UUID(), name: String, colors: [String]) {
        self.id = id
        self.name = name
        self.colors = colors
    }
    
    // Default theme colors
    static let `default` = ColorTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
        name: "Default",
        colors: [
            "0d1b2a", // inkBlack - background
            "1b263b", // prussianBlue - card
            "415a77", // duskBlue - primary
            "778da9", // dustyDenim - accent
            "e0e1dd"  // alabasterGrey - text
        ]
    )
}

// MARK: - Coolors.co URL Parser
struct CoolorsURLParser {
    static func parse(urlString: String) -> [String]? {
        // Supported formats:
        // - https://coolors.co/0b132b-1c2541-3a506b-5bc0be-ffffff
        // - https://coolors.co/palette/606c38-283618-fefae0-dda15e-bc6c25
        // - coolors.co/0b132b-1c2541-3a506b-5bc0be-ffffff
        // - coolors.co/palette/606c38-283618-fefae0-dda15e-bc6c25
        // - 0b132b-1c2541-3a506b-5bc0be-ffffff (just the colors)
        
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If it's just colors separated by dashes, parse directly
        if !trimmed.contains("://") && !trimmed.contains("coolors.co") {
            // Check if it looks like color codes
            let parts = trimmed.components(separatedBy: "-")
            if parts.count >= 3 {
                let validParts = parts.filter { part in
                    let hex = part.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    return hex.count == 3 || hex.count == 6
                }
                if validParts.count >= 3 {
                    return validParts
                }
            }
        }
        
        // Try parsing as URL
        if let url = URL(string: trimmed) {
            if let host = url.host, host.contains("coolors.co") {
                var path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                
                // Handle /palette/ prefix
                if path.hasPrefix("palette/") {
                    path = String(path.dropFirst(8)) // Remove "palette/"
                }
                
                if !path.isEmpty {
                    return parseColorString(path)
                }
                
                // Try query or fragment
                if let fragment = url.fragment, !fragment.isEmpty {
                    return parseColorString(fragment)
                }
            }
        }
        
        // Try parsing without protocol
        if trimmed.contains("coolors.co/") {
            let components = trimmed.components(separatedBy: "coolors.co/")
            if components.count == 2 {
                var colorString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Handle /palette/ prefix
                if colorString.hasPrefix("palette/") {
                    colorString = String(colorString.dropFirst(8))
                }
                
                return parseColorString(colorString)
            }
        }
        
        return nil
    }
    
    private static func parseColorString(_ colorString: String) -> [String]? {
        // Remove any leading/trailing slashes or whitespace
        let cleaned = colorString.trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
        
        // Split by dash or hyphen
        let colors = cleaned.components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Validate hex colors (3 or 6 characters)
        let validColors = colors.filter { color in
            let hex = color.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            return hex.count == 3 || hex.count == 6
        }
        
        return validColors.isEmpty ? nil : validColors
    }
}

// MARK: - Color Brightness Utilities
extension ColorTheme {
    /// Calculate relative luminance (brightness) from a hex color string
    /// Uses the standard formula: 0.299*R + 0.587*G + 0.114*B
    /// Returns a value between 0 (darkest) and 255 (lightest)
    static func brightness(from hex: String) -> Double? {
        // Clean hex string - remove # and any non-hex characters
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        
        var hexValue: String
        if cleaned.count == 3 {
            // Expand 3-digit hex to 6-digit
            hexValue = cleaned.map { String($0) + String($0) }.joined()
        } else if cleaned.count == 6 {
            hexValue = cleaned
        } else {
            return nil
        }
        
        // Convert hex to RGB
        guard let rgb = Int(hexValue, radix: 16) else {
            return nil
        }
        
        let r = Double((rgb >> 16) & 0xFF)
        let g = Double((rgb >> 8) & 0xFF)
        let b = Double(rgb & 0xFF)
        
        // Calculate relative luminance using standard formula
        let brightness = 0.299 * r + 0.587 * g + 0.114 * b
        
        return brightness
    }
    
    /// Sort colors by brightness from darkest to lightest
    /// Preserves original order if sorting fails for any color
    static func sortColorsByBrightness(_ colors: [String]) -> [String] {
        // Create tuples of (color, brightness) and filter out invalid colors
        let colorBrightnessPairs = colors.compactMap { color -> (String, Double)? in
            guard let brightness = brightness(from: color) else {
                return nil
            }
            return (color, brightness)
        }
        
        // If we couldn't calculate brightness for any colors, return original
        guard colorBrightnessPairs.count == colors.count else {
            return colors
        }
        
        // Sort by brightness (darkest to lightest)
        let sorted = colorBrightnessPairs.sorted { $0.1 < $1.1 }
        
        // Return just the colors in sorted order
        return sorted.map { $0.0 }
    }
}

