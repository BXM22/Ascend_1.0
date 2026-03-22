import SwiftUI

/// Kinetic Atelier typography — **Manrope** (DESIGN.md §3). PostScript names match bundled TTF files in `Resources/Fonts/`.
struct AppTypography {
    // MARK: - Manrope (bundled)
    private static let regular = "Manrope-Regular"
    private static let medium = "Manrope-Medium"
    private static let semiBold = "Manrope-SemiBold"
    private static let bold = "Manrope-Bold"
    private static let extraBold = "Manrope-ExtraBold"
    
    private static func manrope(_ name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        Font.custom(name, size: size, relativeTo: textStyle)
    }
    
    // MARK: - Scale (doc: Display / Headline / Title / Body / Labels)
    
    /// Display — large metrics; doc: −2% tracking (use `kineticDisplayTracking` modifier).
    static let displayLarge = manrope(extraBold, size: 40, relativeTo: .largeTitle)
    static let displayMedium = manrope(extraBold, size: 32, relativeTo: .largeTitle)
    
    /// Headline — section titles; Semi-Bold.
    static let headlineLarge = manrope(semiBold, size: 28, relativeTo: .title)
    static let headlineMedium = manrope(semiBold, size: 22, relativeTo: .title2)
    
    /// Title — card headings.
    static let titleLarge = manrope(bold, size: 22, relativeTo: .title2)
    static let titleMedium = manrope(bold, size: 19, relativeTo: .title3)
    
    /// Body — `tertiary` color + ~1.5× line height (use `kineticBodyLineHeight`).
    static let body = manrope(regular, size: 17, relativeTo: .body)
    static let bodyMedium = manrope(medium, size: 17, relativeTo: .body)
    static let bodyBold = manrope(bold, size: 17, relativeTo: .body)
    
    static let subheadlineMedium = manrope(medium, size: 15, relativeTo: .subheadline)
    
    /// Labels — metadata; doc: all-caps +5% tracking (`kineticLabelTracking`).
    static let labelSmallUppercase = manrope(semiBold, size: 11, relativeTo: .caption)
    static let caption = manrope(regular, size: 13, relativeTo: .caption)
    static let captionMedium = manrope(medium, size: 13, relativeTo: .caption)
    static let captionBold = manrope(bold, size: 13, relativeTo: .caption)
    
    // MARK: - Legacy aliases (same scale; existing screens keep compiling)
    static let heading1 = manrope(bold, size: 34, relativeTo: .largeTitle)
    static let heading2 = manrope(bold, size: 26, relativeTo: .title)
    static let heading3 = manrope(bold, size: 22, relativeTo: .title2)
    static let heading4 = manrope(medium, size: 19, relativeTo: .title3)
    static let largeTitleBold = manrope(extraBold, size: 36, relativeTo: .largeTitle)
    static let footnote = manrope(regular, size: 12, relativeTo: .footnote)
    static let footnoteMedium = manrope(medium, size: 12, relativeTo: .footnote)
    static let bodySmall = manrope(regular, size: 14, relativeTo: .subheadline)
    static let bodySmallMedium = manrope(medium, size: 14, relativeTo: .subheadline)
    static let bodySmallBold = manrope(bold, size: 14, relativeTo: .subheadline)
    static let bodyMediumEditorial = manrope(regular, size: 14, relativeTo: .body)
    static let numberInput = manrope(bold, size: 24, relativeTo: .title2)
    static let numberInputLarge = manrope(bold, size: 32, relativeTo: .title)
    static let button = manrope(medium, size: 16, relativeTo: .body)
    static let buttonBold = manrope(bold, size: 16, relativeTo: .body)
    static let buttonLarge = manrope(bold, size: 20, relativeTo: .title3)
    static let exerciseTitle = manrope(bold, size: 28, relativeTo: .title)
}

// MARK: - Kinetic typography modifiers (DESIGN.md §3)
extension View {
    /// Display: −2% letter spacing (tight, “machined”).
    func kineticDisplayTracking(for fontSize: CGFloat) -> some View {
        kerning(-0.02 * fontSize)
    }
    
    /// Labels: +5% letter spacing; combine with `.textCase(.uppercase)` for metadata.
    func kineticLabelTracking(for fontSize: CGFloat) -> some View {
        kerning(0.05 * fontSize)
    }
    
    /// Body: editorial line height ~1.5× for typical 17pt body.
    func kineticBodyLineHeight() -> some View {
        lineSpacing(6)
    }
}
