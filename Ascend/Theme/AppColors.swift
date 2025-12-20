import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme Provider
class ColorThemeProvider: ObservableObject {
    @Published var themeID = UUID()
    
    // Cache the custom theme to avoid repeated UserDefaults reads
    @Published private(set) var cachedTheme: ColorTheme?
    
    static let shared: ColorThemeProvider = {
        // Initialize provider - init() will automatically load the theme
        let provider = ColorThemeProvider()
        return provider
    }()
    
    private init() {
        // Load theme immediately
        loadTheme()
        
        // Listen for theme changes
        NotificationCenter.default.addObserver(
            forName: AppConstants.Notification.colorThemeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.loadTheme()
                self?.themeID = UUID()
            }
        }
    }
    
    private func loadTheme() {
        if let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.customColorTheme),
           let theme = try? JSONDecoder().decode(ColorTheme.self, from: data) {
            cachedTheme = theme
        } else {
            cachedTheme = nil
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
        // Use cached theme from ColorThemeProvider for faster access
        return ColorThemeProvider.shared.cachedTheme
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
    
    // Helper to get custom color if it exists
    private static func getCustomColor(for key: String) -> Color? {
        if let hex = UIColorCustomizationManager.shared.getCustomColor(for: UIColorCustomization.ColorKey(rawValue: key) ?? .background) {
            return Color(hex: hex)
        }
        return nil
    }
    
    // Helper to get color with light/dark variants
    private static func adaptiveColor(
        lightIndex: Int? = nil,
        darkIndex: Int? = nil,
        defaultLight: Color,
        defaultDark: Color,
        customKey: String? = nil
    ) -> Color {
        // Check for custom color first
        if let key = customKey, let customColor = getCustomColor(for: key) {
            return customColor
        }
        
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
    
    // Semantic Colors - Now with dark mode support, custom theme support, and custom color overrides
    static var background: Color {
        adaptiveColor(
            lightIndex: 4, // Use last color (usually lightest) for light mode
            darkIndex: 0,  // Use first color (usually darkest) for dark mode
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "000000"), // True black for dark mode
            customKey: "background"
        )
    }
    
    static var foreground: Color {
        adaptiveColor(
            lightIndex: 0, // Dark text on light background
            darkIndex: 4,  // Light text on dark background
            defaultLight: inkBlack,
            defaultDark: Color(hex: "ffffff"), // White text for dark mode
            customKey: "foreground"
        )
    }
    
    static var card: Color {
        adaptiveColor(
            lightIndex: 4, // Light card in light mode
            darkIndex: 1,  // Second color for card in dark mode
            defaultLight: .white,
            defaultDark: Color(hex: "1c1c1e"), // iOS system dark gray for cards
            customKey: "card"
        )
    }
    
    static var primary: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 2,
            defaultLight: prussianBlue,
            defaultDark: Color(hex: "5a9eff"), // Bright blue for dark mode - ensures visibility
            customKey: "primary"
        )
    }
    
    static var secondary: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1f1f1f"), // Dark gray for secondary elements
            customKey: "secondary"
        )
    }
    
    static var muted: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f0f0f0"),
            defaultDark: Color(hex: "2c2c2e"), // Slightly lighter gray for muted elements
            customKey: "muted"
        )
    }
    
    static var mutedForeground: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "c7c7cc"), // Brighter gray for secondary text in dark mode
            customKey: "mutedForeground"
        )
    }
    
    static var border: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 2,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "3a3a3c"), // Medium gray for borders
            customKey: "border"
        )
    }
    
    static var input: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 1,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "1c1c1e"), // Dark gray for input fields
            customKey: "input"
        )
    }
    
    static var accent: Color {
        adaptiveColor(
            lightIndex: 3,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "7ab8ff"), // Lighter blue for dark mode - ensures visibility
            customKey: "accent"
        )
    }
    
    static var accentForeground: Color {
        adaptiveColor(
            lightIndex: 0,
            darkIndex: 4,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "ffffff"), // White for dark mode - ensures visibility
            customKey: "accentForeground"
        )
    }
    
    // Adaptive color for text on gradient/primary backgrounds
    static var onPrimary: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 4,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: "ffffff"), // White for dark mode - ensures visibility on dark gradients
            customKey: "onPrimary"
        )
    }
    
    static var destructive: Color {
        if let custom = getCustomColor(for: "destructive") {
            return custom
        }
        return Color(hex: "dc2626")
    }
    
    static var success: Color {
        adaptiveColor(
            lightIndex: 3,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "34c759"), // iOS green for success in dark mode
            customKey: "success"
        )
    }
    
    static var warning: Color {
        if let custom = getCustomColor(for: "warning") {
            return custom
        }
        return Color(hex: "d97706")
    }
    
    // Design system aliases for DashboardView compatibility
    static var textPrimary: Color { foreground }
    static var textSecondary: Color { mutedForeground }
    
    // Adaptive gradient colors for headers
    static var primaryGradientStart: Color {
        adaptiveColor(
            lightIndex: 1,
            darkIndex: 3,
            defaultLight: prussianBlue,
            defaultDark: Color(hex: "5a9eff"), // Bright blue gradient start for dark mode
            customKey: "primaryGradientStart"
        )
    }
    
    static var primaryGradientEnd: Color {
        adaptiveColor(
            lightIndex: 2,
            darkIndex: 3,
            defaultLight: duskBlue,
            defaultDark: Color(hex: "7ab8ff"), // Lighter blue gradient end for dark mode
            customKey: "primaryGradientEnd"
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
    
    // Template color palette - restrained colors that align with app design
    static let templateColorPalette: [(name: String, hex: String)] = [
        ("Purple", "9333ea"),
        ("Pink", "ec4899"),
        ("Blue", "2563eb"),
        ("Cyan", "06b6d4"),
        ("Green", "16a34a"),
        ("Emerald", "10b981"),
        ("Orange", "ea580c"),
        ("Amber", "f59e0b"),
        ("Red", "dc2626"),
        ("Rose", "f43f5e"),
        ("Teal", "0891b2"),
        ("Sky", "0ea5e9"),
        ("Primary", "415a77"),
        ("Dusty Denim", "778da9")
    ]
    
    // MARK: - Color Grid Generation
    
    /// Generate a color grid organized by hue and saturation
    /// - Parameters:
    ///   - hueSteps: Number of hue steps (default 12 for full spectrum)
    ///   - saturationSteps: Number of saturation levels (default 5)
    ///   - lightness: Fixed lightness value 0.0-1.0 (default 0.65 for vibrant colors)
    /// - Returns: Array of hex color strings organized by hue rows
    static func generateColorGrid(hueSteps: Int = 12, saturationSteps: Int = 5, lightness: Double = 0.65) -> [[String]] {
        var grid: [[String]] = []
        
        for hueIndex in 0..<hueSteps {
            var row: [String] = []
            let hue = Double(hueIndex) * 360.0 / Double(hueSteps)
            
            for satIndex in 0..<saturationSteps {
                // Saturation from 0.3 to 1.0 for vibrant colors
                let saturation = 0.3 + (Double(satIndex) * 0.7 / Double(saturationSteps - 1))
                
                let hex = hslToHex(h: hue, s: saturation, l: lightness)
                row.append(hex)
            }
            
            grid.append(row)
        }
        
        return grid
    }
    
    /// Convert HSL to hex color string
    private static func hslToHex(h: Double, s: Double, l: Double) -> String {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        
        if h < 60 {
            r = c
            g = x
            b = 0
        } else if h < 120 {
            r = x
            g = c
            b = 0
        } else if h < 180 {
            r = 0
            g = c
            b = x
        } else if h < 240 {
            r = 0
            g = x
            b = c
        } else if h < 300 {
            r = x
            g = 0
            b = c
        } else {
            r = c
            g = 0
            b = x
        }
        
        let red = Int((r + m) * 255)
        let green = Int((g + m) * 255)
        let blue = Int((b + m) * 255)
        
        return String(format: "%02X%02X%02X", red, green, blue)
    }
    
    // Helper to get template gradient - uses custom color if available, otherwise falls back to muscle group
    static func templateGradient(for template: WorkoutTemplate) -> LinearGradient {
        if let colorHex = template.colorHex {
            let color = Color(hex: colorHex)
            // Create a subtle gradient from the color
            return LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Fall back to muscle group detection
            let muscleGroup = template.exercises.first?.name ?? "General"
            return categoryGradient(for: muscleGroup)
        }
    }
    
    // Helper to get template color - returns the base color for the template
    static func templateColor(for template: WorkoutTemplate) -> Color {
        if let colorHex = template.colorHex {
            return Color(hex: colorHex)
        } else {
            // Fall back to muscle group detection - use start color of gradient
            let muscleGroup = template.exercises.first?.name ?? "General"
            let lowercased = muscleGroup.lowercased()
            
            if lowercased.contains("chest") || lowercased.contains("push") || lowercased.contains("shoulder") {
                return chestGradientStart
            } else if lowercased.contains("back") || lowercased.contains("pull") || lowercased.contains("lat") || lowercased.contains("row") {
                return backGradientStart
            } else if lowercased.contains("leg") || lowercased.contains("quad") || lowercased.contains("hamstring") || lowercased.contains("calf") || lowercased.contains("glute") || lowercased.contains("squat") {
                return legsGradientStart
            } else if lowercased.contains("arm") || lowercased.contains("bicep") || lowercased.contains("tricep") || lowercased.contains("curl") {
                return armsGradientStart
            } else if lowercased.contains("core") || lowercased.contains("ab") || lowercased.contains("plank") {
                return coreGradientStart
            } else if lowercased.contains("cardio") || lowercased.contains("run") || lowercased.contains("conditioning") {
                return cardioGradientStart
            } else {
                return primaryGradientStart
            }
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

