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
            forName: AppConstants.Notification.colorThemeDidChange,
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
        if let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.customColorTheme),
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
            defaultDark: Color(hex: "000000") // True black for dark mode
        )
    }
    
    static var foreground: Color {
        adaptiveColor(
            lightIndex: 0, // Dark text on light background
            darkIndex: 4,  // Light text on dark background
            defaultLight: inkBlack,
            defaultDark: Color(hex: "ffffff") // White text for dark mode
        )
    }
    
    static var card: Color {
        adaptiveColor(
            lightIndex: 4, // Light card in light mode
            darkIndex: 1,  // Second color for card in dark mode
            defaultLight: .white,
            defaultDark: Color(hex: "1c1c1e") // iOS system dark gray for cards
        )
    }
    
    static var primary: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 2,
            defaultLight: prussianBlue,
            defaultDark: Color(hex: "5a9eff") // Bright blue for dark mode - ensures visibility
        )
    }
    
    static var secondary: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1f1f1f") // Dark gray for secondary elements
        )
    }
    
    static var muted: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f0f0f0"),
            defaultDark: Color(hex: "2c2c2e") // Slightly lighter gray for muted elements
        )
    }
    
    static var mutedForeground: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "c7c7cc") // Brighter gray for secondary text in dark mode
        )
    }
    
    static var border: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 2,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "3a3a3c") // Medium gray for borders
        )
    }
    
    static var input: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1c1c1e") // Dark gray for input fields
        )
    }
    
    static var accent: Color {
        adaptiveColor(
            lightIndex: 3,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "7ab8ff") // Lighter blue for dark mode - ensures visibility
        )
    }
    
    static var accentForeground: Color {
        adaptiveColor(
            lightIndex: 0,
            darkIndex: 4,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "ffffff") // White for dark mode - ensures visibility
        )
    }
    
    // Adaptive color for text on gradient/primary backgrounds
    static var onPrimary: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 4,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "ffffff") // White for dark mode - ensures visibility on dark gradients
        )
    }
    
    static let destructive = Color(hex: "dc2626")
    
    static var success: Color {
        adaptiveColor(
            lightIndex: 3,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "34c759") // iOS green for success in dark mode
        )
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
            defaultDark: Color(hex: "5a9eff") // Bright blue gradient start for dark mode
        )
    }
    
    static var primaryGradientEnd: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "7ab8ff") // Lighter blue gradient end for dark mode
        )
    }
    
    // MARK: - Category Gradient Colors
    
    // Chest/Push exercises - Purple/Pink
    static let chestGradientStart = Color(hex: "9333ea")
    static let chestGradientEnd = Color(hex: "ec4899")
    
    // Back/Pull exercises - Blue/Cyan
    static let backGradientStart = Color(hex: "2563eb")
    static let backGradientEnd = Color(hex: "06b6d4")
    
    // Legs exercises - Green/Emerald
    static let legsGradientStart = Color(hex: "16a34a")
    static let legsGradientEnd = Color(hex: "10b981")
    
    // Arms exercises - Orange/Amber
    static let armsGradientStart = Color(hex: "ea580c")
    static let armsGradientEnd = Color(hex: "f59e0b")
    
    // Core exercises - Red/Rose
    static let coreGradientStart = Color(hex: "dc2626")
    static let coreGradientEnd = Color(hex: "f43f5e")
    
    // Cardio/Conditioning - Teal/Sky
    static let cardioGradientStart = Color(hex: "0891b2")
    static let cardioGradientEnd = Color(hex: "0ea5e9")
    
    // Helper function to get gradient based on muscle group
    static func categoryGradient(for muscleGroup: String) -> LinearGradient {
        let lowercased = muscleGroup.lowercased()
        
        if lowercased.contains("chest") || lowercased.contains("push") || lowercased.contains("shoulder") {
            return LinearGradient(
                colors: [chestGradientStart, chestGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("back") || lowercased.contains("pull") || lowercased.contains("lat") || lowercased.contains("row") {
            return LinearGradient(
                colors: [backGradientStart, backGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("leg") || lowercased.contains("quad") || lowercased.contains("hamstring") || lowercased.contains("calf") || lowercased.contains("glute") || lowercased.contains("squat") {
            return LinearGradient(
                colors: [legsGradientStart, legsGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("curl") {
            return LinearGradient(
                colors: [armsGradientStart, armsGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("core") || lowercased.contains("ab") || lowercased.contains("plank") {
            return LinearGradient(
                colors: [coreGradientStart, coreGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if lowercased.contains("cardio") || lowercased.contains("run") || lowercased.contains("conditioning") {
            return LinearGradient(
                colors: [cardioGradientStart, cardioGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Default to primary gradient
            return LinearGradient.primaryGradient
        }
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
            colors: [
                Color(light: AppColors.duskBlue, dark: Color(hex: "2c2c2e")),
                Color(light: AppColors.dustyDenim, dark: Color(hex: "3a3a3c"))
            ],
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
    
    // Category gradients for easy access
    static var chestGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.chestGradientStart, AppColors.chestGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var backGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.backGradientStart, AppColors.backGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var legsGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.legsGradientStart, AppColors.legsGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var armsGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.armsGradientStart, AppColors.armsGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var coreGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.coreGradientStart, AppColors.coreGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardioGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.cardioGradientStart, AppColors.cardioGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

