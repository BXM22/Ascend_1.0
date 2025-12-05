import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme Provider
class ColorThemeProvider: ObservableObject {
    @Published var themeID = UUID()
    
    static let shared = ColorThemeProvider()
    
    private init() {
        // Listen for theme changes
        NotificationCenter.default.addObserver(
            forName: .colorThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.themeID = UUID()
        }
    }
}

struct AppColors {
    // Default Color Palette
    static let inkBlack = Color(hex: "0d1b2a")
    static let prussianBlue = Color(hex: "1b263b")
    static let duskBlue = Color(hex: "415a77")
    static let dustyDenim = Color(hex: "778da9")
    static let alabasterGrey = Color(hex: "e0e1dd")
    
    // MARK: - Custom Theme Support
    
    private static var customTheme: ColorTheme? {
        if let data = UserDefaults.standard.data(forKey: "customColorTheme"),
           let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
            return theme
        }
        return nil
    }
    
    // Theme ID to force view updates
    static var themeID: UUID {
        ColorThemeProvider.shared.themeID
    }
    
    // Helper to get color from custom theme or default
    private static func colorFromTheme(index: Int, defaultColor: Color) -> Color {
        guard let theme = customTheme,
              index < theme.colors.count else {
            return defaultColor
        }
        return Color(hex: theme.colors[index])
    }
    
    // Helper to get color with light/dark variants
    private static func adaptiveColor(
        lightIndex: Int? = nil,
        darkIndex: Int? = nil,
        defaultLight: Color,
        defaultDark: Color
    ) -> Color {
        guard let theme = customTheme else {
            return Color(light: defaultLight, dark: defaultDark)
        }
        
        let lightColor: Color
        let darkColor: Color
        
        if let lightIdx = lightIndex, lightIdx < theme.colors.count {
            lightColor = Color(hex: theme.colors[lightIdx])
        } else {
            lightColor = defaultLight
        }
        
        if let darkIdx = darkIndex, darkIdx < theme.colors.count {
            darkColor = Color(hex: theme.colors[darkIdx])
        } else {
            darkColor = defaultDark
        }
        
        return Color(light: lightColor, dark: darkColor)
    }
    
    // Semantic Colors - Now with dark mode support and custom theme support
    static var background: Color {
        adaptiveColor(
            lightIndex: 4, // Use last color (usually lightest) for light mode
            darkIndex: 0,  // Use first color (usually darkest) for dark mode
            defaultLight: alabasterGrey,
            defaultDark: inkBlack
        )
    }
    
    static var foreground: Color {
        adaptiveColor(
            lightIndex: 0, // Dark text on light background
            darkIndex: 4,  // Light text on dark background
            defaultLight: inkBlack,
            defaultDark: Color(hex: "e8eaed")
        )
    }
    
    static var card: Color {
        adaptiveColor(
            lightIndex: 4, // Light card in light mode
            darkIndex: 1,  // Second color for card in dark mode
            defaultLight: .white,
            defaultDark: prussianBlue
        )
    }
    
    static var primary: Color {
        colorFromTheme(index: 2, defaultColor: prussianBlue)
    }
    
    static var secondary: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1e2936")
        )
    }
    
    static var muted: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f0f0f0"),
            defaultDark: Color(hex: "2a3847")
        )
    }
    
    static var mutedForeground: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "a8b8cc")
        )
    }
    
    static var border: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 2,
            defaultLight: dustyDenim,
            defaultDark: duskBlue
        )
    }
    
    static var input: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1e2936")
        )
    }
    
    static var accent: Color {
        colorFromTheme(index: 3, defaultColor: duskBlue)
    }
    
    static var accentForeground: Color {
        adaptiveColor(
            lightIndex: 0,
            darkIndex: 4,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "f0f2f5")
        )
    }
    
    static let destructive = Color(hex: "dc2626")
    
    static var success: Color {
        colorFromTheme(index: 3, defaultColor: duskBlue)
    }
    
    static let warning = Color(hex: "d97706")
    
    // Design system aliases for DashboardView compatibility
    static var textPrimary: Color { foreground }
    static var textSecondary: Color { mutedForeground }
    
    // Adaptive gradient colors for headers
    static var primaryGradientStart: Color {
        adaptiveColor(
            lightIndex: 1,
            darkIndex: 3,
            defaultLight: prussianBlue,
            defaultDark: dustyDenim
        )
    }
    
    static var primaryGradientEnd: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "9fb5d1")
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        self = light
        #endif
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        }
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.duskBlue, AppColors.dustyDenim],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.secondary, AppColors.card],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

