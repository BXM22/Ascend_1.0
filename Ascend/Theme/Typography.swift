import SwiftUI

struct AppTypography {
    // MARK: - Custom Fonts Configuration
    // Avenir font (currently using Avenir-Regular from "Avenir Regular.ttf")
    // Note: Avenir typically has these PostScript names:
    // - Avenir-Book, Avenir-Roman, Avenir-Medium, Avenir-Heavy, Avenir-Black
    // Using system weights as fallback until you add more Avenir weights
    
    private static let avenirRegular = "Avenir-Book"  // Avenir Regular
    private static let avenirMedium = "Avenir-Medium"  // You'll need to add this file
    private static let avenirBold = "Avenir-Heavy"     // You'll need to add this file
    
    // MARK: - Avenir Fonts (Active)
    // Using Avenir for main typography - mixing with system weights where Avenir weights not available
    static let heading1 = Font.custom(avenirBold, size: 34, relativeTo: .largeTitle)
    static let heading2 = Font.custom(avenirBold, size: 26, relativeTo: .title)
    static let body = Font.custom(avenirRegular, size: 17, relativeTo: .body)
    static let caption = Font.custom(avenirRegular, size: 13, relativeTo: .caption)
    
    // Additional typography variants
    static let heading3 = Font.custom(avenirBold, size: 22, relativeTo: .title2)
    static let heading4 = Font.custom(avenirMedium, size: 19, relativeTo: .title3)
    static let bodyBold = Font.custom(avenirBold, size: 17, relativeTo: .body)
    static let bodyMedium = Font.custom(avenirMedium, size: 17, relativeTo: .body)
    static let subheadlineMedium = Font.custom(avenirMedium, size: 15, relativeTo: .subheadline)
    static let captionMedium = Font.custom(avenirMedium, size: 13, relativeTo: .caption)
    static let captionBold = Font.custom(avenirBold, size: 13, relativeTo: .caption)
    static let largeTitleBold = Font.custom(avenirBold, size: 36, relativeTo: .largeTitle)
    
    // MARK: - Extended Typography for Exercise Cards
    // Footnote size (12pt) - labels above inputs
    static let footnote = Font.custom(avenirRegular, size: 12, relativeTo: .footnote)
    static let footnoteMedium = Font.custom(avenirMedium, size: 12, relativeTo: .footnote)
    
    // Small body (14pt) - set indicators, secondary labels
    static let bodySmall = Font.custom(avenirRegular, size: 14, relativeTo: .subheadline)
    static let bodySmallMedium = Font.custom(avenirMedium, size: 14, relativeTo: .subheadline)
    static let bodySmallBold = Font.custom(avenirBold, size: 14, relativeTo: .subheadline)
    
    // Large numbers (24pt) - input fields
    static let numberInput = Font.custom(avenirBold, size: 24, relativeTo: .title2)
    
    // Extra large numbers (32pt) - primary inputs
    static let numberInputLarge = Font.custom(avenirBold, size: 32, relativeTo: .title)
    
    // Button text (16pt)
    static let button = Font.custom(avenirMedium, size: 16, relativeTo: .body)
    static let buttonBold = Font.custom(avenirBold, size: 16, relativeTo: .body)
    
    // Large button text (20pt)
    static let buttonLarge = Font.custom(avenirBold, size: 20, relativeTo: .title3)
    
    // Exercise name header (28pt)
    static let exerciseTitle = Font.custom(avenirBold, size: 28, relativeTo: .title)
    
    // MARK: - Fallback to System Fonts (if Avenir not loaded)
    // If you see system fonts, it means Avenir didn't load properly.
    // Check: 1) Font file is in project 2) Added to Info.plist 3) PostScript name is correct
}
