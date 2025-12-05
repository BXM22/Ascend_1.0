import SwiftUI

struct ColorTheme: Codable {
    var name: String
    var colors: [String] // Hex color strings
    
    // Map colors to semantic roles
    // Expected order: [background, card, primary, accent, textPrimary, textSecondary]
    // Or we can use a more flexible approach with 5 colors from Coolors
    
    init(name: String, colors: [String]) {
        self.name = name
        self.colors = colors
    }
    
    // Default theme colors
    static let `default` = ColorTheme(
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
        // Format: https://coolors.co/0b132b-1c2541-3a506b-5bc0be-ffffff
        // Or: coolors.co/0b132b-1c2541-3a506b-5bc0be-ffffff
        // Or: 0b132b-1c2541-3a506b-5bc0be-ffffff (just the colors)
        
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
                // Extract path after /coolors.co/
                let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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
                let colorString = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
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

