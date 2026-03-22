import SwiftUI

/// Spacing & radius — **Kinetic Atelier** (DESIGN.md §2, §5).
struct AppSpacing {
    // Base scale
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    
    /// Doc “spacing-2” / list item gaps between rows (§5 Cards & Lists).
    static let spacing2: CGFloat = 8
    /// Doc “spacing-3” / slightly looser list separation.
    static let spacing3: CGFloat = 12
    /// Doc No-Line rule — logical groups (§2).
    static let spacing8: CGFloat = 32
    /// Doc No-Line rule — larger group separation (§2).
    static let spacing10: CGFloat = 40
    
    /// Do’s: padding when in doubt (§6).
    static let sectionSpacingLoose: CGFloat = spacing8
    
    // Extended
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let listItemSpacing: CGFloat = spacing3
    
    /// Card corner — `xl` = 1.5rem (24pt) (§5).
    static let cardRadiusXL: CGFloat = 24
    static let sectionGapXL: CGFloat = 32
    static let contentPadLG: CGFloat = 20
    
    /// Corner radius tokens (§5 Inputs vs Buttons).
    static let radiusMD: CGFloat = 12  // 0.75rem
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 24  // 1.5rem — cards
}
