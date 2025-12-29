//
//  UIColorCustomization.swift
//  Ascend
//
//  Model for storing custom UI color overrides
//

import Foundation

struct UIColorCustomization: Codable {
    var customColors: [String: String] // [colorKey: hexValue]
    
    init(customColors: [String: String] = [:]) {
        self.customColors = customColors
    }
    
    // All available color keys that can be customized
    static let allColorKeys: [ColorKey] = [
        // Core Colors
        .background, .foreground, .card,
        // Brand Colors
        .primary, .secondary, .accent,
        // Text Colors
        .mutedForeground, .onPrimary, .accentForeground,
        // UI Elements
        .border, .input, .muted,
        // Status Colors
        .destructive, .success, .warning,
        // Gradients
        .primaryGradientStart, .primaryGradientEnd
    ]
    
    enum ColorKey: String, Codable, CaseIterable {
        // Core Colors
        case background = "background"
        case foreground = "foreground"
        case card = "card"
        
        // Brand Colors
        case primary = "primary"
        case secondary = "secondary"
        case accent = "accent"
        
        // Text Colors
        case mutedForeground = "mutedForeground"
        case onPrimary = "onPrimary"
        case accentForeground = "accentForeground"
        
        // UI Elements
        case border = "border"
        case input = "input"
        case muted = "muted"
        
        // Status Colors
        case destructive = "destructive"
        case success = "success"
        case warning = "warning"
        
        // Gradients
        case primaryGradientStart = "primaryGradientStart"
        case primaryGradientEnd = "primaryGradientEnd"
        
        var displayName: String {
            switch self {
            case .background: return "Background"
            case .foreground: return "Foreground"
            case .card: return "Card"
            case .primary: return "Primary"
            case .secondary: return "Secondary"
            case .accent: return "Accent"
            case .mutedForeground: return "Muted Text"
            case .onPrimary: return "Text on Primary"
            case .accentForeground: return "Text on Accent"
            case .border: return "Border"
            case .input: return "Input Field"
            case .muted: return "Muted Background"
            case .destructive: return "Destructive"
            case .success: return "Success"
            case .warning: return "Warning"
            case .primaryGradientStart: return "Primary Gradient Start"
            case .primaryGradientEnd: return "Primary Gradient End"
            }
        }
        
        var description: String {
            switch self {
            case .background: return "Main app background color"
            case .foreground: return "Primary text color"
            case .card: return "Card and surface background"
            case .primary: return "Primary brand color"
            case .secondary: return "Secondary background color"
            case .accent: return "Accent color for highlights"
            case .mutedForeground: return "Secondary text color"
            case .onPrimary: return "Text color on primary backgrounds"
            case .accentForeground: return "Text color on accent backgrounds"
            case .border: return "Border and divider color"
            case .input: return "Input field background"
            case .muted: return "Muted background elements"
            case .destructive: return "Error and destructive actions"
            case .success: return "Success indicators"
            case .warning: return "Warning indicators"
            case .primaryGradientStart: return "Start color of primary gradient"
            case .primaryGradientEnd: return "End color of primary gradient"
            }
        }
        
        var category: ColorCategory {
            switch self {
            case .background, .foreground, .card:
                return .core
            case .primary, .secondary, .accent:
                return .brand
            case .mutedForeground, .onPrimary, .accentForeground:
                return .text
            case .border, .input, .muted:
                return .uiElements
            case .destructive, .success, .warning:
                return .status
            case .primaryGradientStart, .primaryGradientEnd:
                return .gradients
            }
        }
    }
    
    enum ColorCategory: String, CaseIterable {
        case core = "Core Colors"
        case brand = "Brand Colors"
        case text = "Text Colors"
        case uiElements = "UI Elements"
        case status = "Status Colors"
        case gradients = "Gradients"
    }
}









