import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DESIGN.md §2 canonical pairs (single source of truth)
private enum BrandHex {
    static let primaryLit = "9cd0d3"
    static let primaryDeep = "3c6e71"
    static let secondaryLit = "a8cbe7"
    static let secondaryDeep = "284b63"
    static let surfaceBase = "131313"
    static let surfaceElevated = "353535"
    static let tertiaryNeutral = "d9d9d9"
    /// Body text on dark surfaces — high contrast on `#131313` / `#353535`.
    static let textOnDark = "f2f2f2"
    /// Secondary labels on dark surfaces (still above ~4.5:1 on base surface).
    static let textMutedOnDark = "c8c8c8"
}

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
    // Default Color Palette (aligned with DESIGN.md — deep masculine base + clinical accents)
    static let inkBlack = Color(hex: "0f2224")
    static let prussianBlue = Color(hex: BrandHex.secondaryDeep)
    static let duskBlue = Color(hex: BrandHex.primaryDeep)
    static let dustyDenim = Color(hex: "5a8a8e")
    static let alabasterGrey = Color(hex: "e8e8e8")
    
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
    /// - Note: Imported palettes are **sorted by brightness**, so array indices are **not** reliable for brand primary vs accent.
    /// Use theme indices only for **background / surface / text**; brand colors use `defaultLight`/`defaultDark` + optional `customKey` overrides.
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
    /// App canvas — deepest charcoal (DESIGN.md: avoid #000; use surface base).
    static var background: Color {
        adaptiveColor(
            lightIndex: 4,
            darkIndex: 0,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: BrandHex.surfaceBase),
            customKey: "background"
        )
    }

    /// Same palette as `background`, but chosen from SwiftUI `ColorScheme`.
    /// Use for chrome (e.g. bottom tab bar in `safeAreaInset`) where dynamic `UIColor`–backed colors can resolve to the wrong variant and read as white.
    static func appBackground(for colorScheme: ColorScheme) -> Color {
        if let custom = getCustomColor(for: "background") {
            return custom
        }
        guard let theme = customTheme else {
            switch colorScheme {
            case .dark: return Color(hex: BrandHex.surfaceBase)
            case .light: return alabasterGrey
            @unknown default: return alabasterGrey
            }
        }
        if colorScheme == .dark {
            if 0 < theme.colors.count {
                return Color(hex: theme.colors[0])
            }
            return Color(hex: BrandHex.surfaceBase)
        }
        if 4 < theme.colors.count {
            return Color(hex: theme.colors[4])
        }
        return alabasterGrey
    }
    
    /// Main text — theme slots skipped by default so imported palettes can’t replace body text with low-contrast hues.
    static var foreground: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: inkBlack,
            defaultDark: Color(hex: BrandHex.textOnDark),
            customKey: "foreground"
        )
    }
    
    /// Elevated surface — fixed defaults; theme indices were unreliable (same slot as bg or random hues when sorted).
    static var card: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: .white,
            defaultDark: Color(hex: BrandHex.surfaceElevated),
            customKey: "card"
        )
    }
    
    /// Brand primary — deep on light UI, **lit** on dark UI so labels stay visible on charcoal surfaces.
    static var primary: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: BrandHex.primaryDeep),
            defaultDark: Color(hex: BrandHex.primaryLit),
            customKey: "primary"
        )
    }
    
    /// Neutral chrome (tabs, etc.) — not a “secondary brand” swatch.
    static var secondary: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "252525"),
            customKey: "secondary"
        )
    }
    
    static var muted: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: "f0f0f0"),
            defaultDark: Color(hex: "2a2a2a"),
            customKey: "muted"
        )
    }
    
    static var mutedForeground: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: BrandHex.textMutedOnDark),
            customKey: "mutedForeground"
        )
    }
    
    static var border: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: dustyDenim,
            defaultDark: Color(hex: "5c5c5c"),
            customKey: "border"
        )
    }
    
    static var input: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: "f5f5f5"),
            defaultDark: Color(hex: "2c2c2e"),
            customKey: "input"
        )
    }
    
    /// Design system **Secondary** — analytical data, progress, subtle focus (`#a8cbe7` / `#284b63`). Not `secondary` (neutral chrome).
    static var accent: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: BrandHex.secondaryDeep),
            defaultDark: Color(hex: BrandHex.secondaryLit),
            customKey: "accent"
        )
    }
    
    /// Alias for design-language “Secondary” (same as `accent`). `AppColors.secondary` remains neutral UI chrome.
    static var brandSecondary: Color { accent }
    
    /// Text on accent-colored controls: light text on dark accent (light mode), dark text on light accent (dark mode).
    static var accentForeground: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: alabasterGrey,
            defaultDark: Color(hex: BrandHex.secondaryDeep),
            customKey: "accentForeground"
        )
    }
    
    // Adaptive color for text on gradient/primary backgrounds (dark mode: light text on deep teal end of gradient)
    static var onPrimary: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: "0f2224"),
            defaultDark: alabasterGrey,
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
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: "16a34a"),
            defaultDark: Color(hex: "34c759"),
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
    static var onSurface: Color { foreground }
    static var onSurfaceVariant: Color { mutedForeground }
    /// Foundation — recessed base.
    static var surface: Color { Color(hex: BrandHex.surfaceBase) }
    /// Sectioning between base and cards (visible step from `surface`).
    static var surfaceContainerLow: Color { Color(hex: "1c1c1c") }
    /// Interactive cards — toward the elevated surface tone.
    static var surfaceContainerHigh: Color { Color(hex: "303030") }
    /// Elevated surface — content lifts from the base.
    static var surfaceContainerHighest: Color { Color(hex: BrandHex.surfaceElevated) }
    /// Primary lit fill — pairs with `primaryDim` for gradients.
    static var primaryContainer: Color { Color(hex: BrandHex.primaryLit) }
    static var primaryDim: Color { Color(hex: BrandHex.primaryDeep) }
    static var onPrimaryContainer: Color { Color(hex: "0f2224") }
    static var secondaryContainer: Color { Color(hex: BrandHex.secondaryDeep) }
    static var onSecondaryContainer: Color { Color(hex: "d9e7f2") }
    static var outlineVariant: Color { Color(hex: "484848").opacity(0.15) }
    /// Tertiary / neutral — body tone; dark mode uses boosted contrast vs spec `#d9d9d9`.
    static var tertiary: Color {
        Color(light: inkBlack, dark: Color(hex: BrandHex.textOnDark))
    }
    static var tertiaryContainer: Color {
        Color(light: dustyDenim, dark: Color(hex: BrandHex.textMutedOnDark))
    }
    
    // Brand gradient — not driven by theme indices (was duplicating slot 3 for start/end).
    static var primaryGradientStart: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: BrandHex.primaryDeep),
            defaultDark: Color(hex: BrandHex.primaryLit),
            customKey: "primaryGradientStart"
        )
    }
    
    static var primaryGradientEnd: Color {
        adaptiveColor(
            lightIndex: nil,
            darkIndex: nil,
            defaultLight: Color(hex: BrandHex.secondaryDeep),
            defaultDark: Color(hex: BrandHex.primaryDeep),
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
        ("Primary deep", BrandHex.primaryDeep),
        ("Secondary deep", BrandHex.secondaryDeep)
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
                Color(light: Color(hex: BrandHex.secondaryDeep), dark: Color(hex: BrandHex.secondaryLit)),
                Color(light: Color(hex: BrandHex.primaryDeep), dark: Color(hex: BrandHex.secondaryDeep))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Kinetic Atelier hero CTA — `secondary_container` → `primary_container`, ~45° (DESIGN.md §2).
    static var heroCTA: LinearGradient {
        LinearGradient(
            colors: [AppColors.secondaryContainer, AppColors.primaryContainer],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
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

