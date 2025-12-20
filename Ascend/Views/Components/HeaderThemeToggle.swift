//
//  HeaderThemeToggle.swift
//  Ascend
//
//  Created on December 18, 2025.
//

import SwiftUI

/// Simple theme toggle button for headers that cycles through light/dark/system
struct HeaderThemeToggle: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var isHovered = false
    
    private var iconName: String {
        switch themeManager.themeMode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    private func cycleTheme() {
        HapticManager.impact(style: .light)
        switch themeManager.themeMode {
        case .system:
            themeManager.themeMode = .light
        case .light:
            themeManager.themeMode = .dark
        case .dark:
            themeManager.themeMode = .system
        }
    }
    
    var body: some View {
        Button(action: cycleTheme) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textPrimary)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(AppAnimations.quick, value: isHovered)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("Toggle theme mode")
        .accessibilityHint("Current mode: \(themeManager.themeMode.rawValue). Tap to cycle through system, light, and dark modes")
    }
}



