import SwiftUI

struct AppTypography {
    // Design System Typography from JSON
    static let heading1 = Font.system(size: 32, weight: .bold)
    static let heading2 = Font.system(size: 24, weight: .bold)
    static let body = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 12, weight: .light)
    
    // Additional typography variants for flexibility
    static let heading3 = Font.system(size: 20, weight: .semibold)
    static let heading4 = Font.system(size: 18, weight: .semibold)
    static let bodyBold = Font.system(size: 16, weight: .semibold)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let captionMedium = Font.system(size: 12, weight: .medium)
}
