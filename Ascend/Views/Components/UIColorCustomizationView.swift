//
//  UIColorCustomizationView.swift
//  Ascend
//
//  Settings view for customizing all UI colors
//

import SwiftUI

struct UIColorCustomizationView: View {
    @ObservedObject var colorManager = UIColorCustomizationManager.shared
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var savedThemeManager = SavedThemeManager.shared
    @State private var selectedColorKey: UIColorCustomization.ColorKey?
    @State private var showColorPicker = false
    @State private var showResetAllConfirmation = false
    @State private var showThemeImport = false
    @State private var themeURLText = ""
    @State private var themeName = ""
    @State private var themeImportError: String?
    @State private var themeImportSuccess = false
    @State private var showDeleteThemeConfirmation = false
    @State private var themeToDelete: ColorTheme?
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("UI Color Customization")
                        .font(AppTypography.largeTitleBold)
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Customize colors throughout the app")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                
                // Theme Import Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Text("App Theme")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        if settingsManager.customTheme != nil {
                            Button(action: {
                                settingsManager.resetToDefaultTheme()
                                themeImportSuccess = false
                                HapticManager.impact(style: .light)
                            }) {
                                Text("Reset")
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(AppColors.destructive)
                            }
                        }
                    }
                    
                    // Current theme indicator
                    if let currentTheme = settingsManager.customTheme {
                        HStack {
                            HStack(spacing: 8) {
                                ForEach(currentTheme.colors.prefix(5), id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(AppColors.border, lineWidth: 1)
                                        )
                                }
                            }
                            
                            Text(currentTheme.name)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if !showThemeImport {
                        Button(action: {
                            withAnimation(AppAnimations.standard) {
                                showThemeImport = true
                            }
                            HapticManager.selection()
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Import Theme from Coolors.co")
                            }
                            .font(AppTypography.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            TextField("Paste Coolors.co URL", text: $themeURLText)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.sm)
                                .background(AppColors.input)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                            
                            TextField("Theme Name (optional)", text: $themeName)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.sm)
                                .background(AppColors.input)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            if let error = themeImportError {
                                Text(error)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.destructive)
                            }
                            
                            if themeImportSuccess {
                                Text("Theme imported and saved successfully!")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.success)
                            }
                            
                            HStack(spacing: AppSpacing.sm) {
                                Button(action: {
                                    importTheme()
                                }) {
                                    Text("Import & Save")
                                        .font(AppTypography.bodyBold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(LinearGradient.primaryGradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Button(action: {
                                    withAnimation(AppAnimations.standard) {
                                        showThemeImport = false
                                        themeURLText = ""
                                        themeName = ""
                                        themeImportError = nil
                                        themeImportSuccess = false
                                    }
                                }) {
                                    Text("Cancel")
                                        .font(AppTypography.bodyBold)
                                        .foregroundColor(AppColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppColors.secondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    
                    // Saved Themes
                    if !savedThemeManager.themes.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Saved Themes")
                                .font(AppTypography.heading3)
                                .foregroundColor(AppColors.textPrimary)
                            
                            ForEach(savedThemeManager.themes) { theme in
                                SavedThemeRow(
                                    theme: theme,
                                    isActive: settingsManager.customTheme?.id == theme.id,
                                    onSelect: {
                                        settingsManager.applyTheme(theme)
                                        HapticManager.selection()
                                    },
                                    onDelete: {
                                        themeToDelete = theme
                                        showDeleteThemeConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, AppSpacing.lg)
                .alert("Delete Theme?", isPresented: $showDeleteThemeConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let theme = themeToDelete {
                            savedThemeManager.deleteTheme(theme)
                            // If this was the active theme, reset to default
                            if settingsManager.customTheme?.id == theme.id {
                                settingsManager.resetToDefaultTheme()
                            }
                            themeToDelete = nil
                        }
                    }
                } message: {
                    if let theme = themeToDelete {
                        Text("Are you sure you want to delete '\(theme.name)'? This action cannot be undone.")
                    }
                }
                
                // Palette Management Link
                NavigationLink(destination: ColorPaletteManagementView()) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                        Text("Manage Color Palettes")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.foreground)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, AppSpacing.lg)
                    
                    // Reset All Button
                    if colorManager.hasCustomizations {
                        Button(action: {
                            showResetAllConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset All Colors")
                            }
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.destructive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.destructive.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                
                // Color Categories
                ForEach(UIColorCustomization.ColorCategory.allCases, id: \.self) { category in
                    ColorCategorySection(
                        category: category,
                        colorManager: colorManager,
                        onColorSelected: { key in
                            selectedColorKey = key
                            showColorPicker = true
                        }
                    )
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .navigationTitle("App Colors")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showColorPicker) {
            if let key = selectedColorKey {
                ColorCustomizationSheet(
                    colorKey: key,
                    currentHex: colorManager.getCustomColor(for: key),
                    onColorSelected: { hex in
                        colorManager.setCustomColor(hex, for: key)
                    },
                    onReset: {
                        colorManager.resetColor(for: key)
                    }
                )
            }
        }
        .alert("Reset All Colors?", isPresented: $showResetAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                colorManager.resetAll()
            }
        } message: {
            Text("This will reset all custom colors to their default values. This action cannot be undone.")
        }
    }
    
    private func importTheme() {
        themeImportError = nil
        themeImportSuccess = false
        
        guard !themeURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            themeImportError = "Please enter a URL"
            return
        }
        
        let themeNameText = themeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = settingsManager.importAndSaveTheme(from: themeURLText, name: themeNameText)
        
        switch result {
        case .success:
            themeImportSuccess = true
            HapticManager.success()
            // Clear text after successful import
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(AppAnimations.standard) {
                    showThemeImport = false
                    themeURLText = ""
                    themeName = ""
                    themeImportSuccess = false
                }
            }
        case .failure(let error):
            themeImportError = error.localizedDescription
            HapticManager.impact(style: .medium)
        }
    }
}

struct ColorCategorySection: View {
    let category: UIColorCustomization.ColorCategory
    @ObservedObject var colorManager: UIColorCustomizationManager
    let onColorSelected: (UIColorCustomization.ColorKey) -> Void
    
    private var colorsInCategory: [UIColorCustomization.ColorKey] {
        UIColorCustomization.ColorKey.allCases.filter { $0.category == category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(category.rawValue)
                .font(AppTypography.heading3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(colorsInCategory, id: \.rawValue) { colorKey in
                    ColorCustomizationRow(
                        colorKey: colorKey,
                        isCustomized: colorManager.isCustomized(colorKey),
                        currentColor: getCurrentColor(for: colorKey),
                        onTap: {
                            onColorSelected(colorKey)
                        }
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getCurrentColor(for key: UIColorCustomization.ColorKey) -> Color {
        // Get the actual color value from AppColors
        switch key {
        case .background: return AppColors.background
        case .foreground: return AppColors.foreground
        case .card: return AppColors.card
        case .primary: return AppColors.primary
        case .secondary: return AppColors.secondary
        case .accent: return AppColors.accent
        case .mutedForeground: return AppColors.mutedForeground
        case .onPrimary: return AppColors.onPrimary
        case .accentForeground: return AppColors.accentForeground
        case .border: return AppColors.border
        case .input: return AppColors.input
        case .muted: return AppColors.muted
        case .destructive: return AppColors.destructive
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .primaryGradientStart: return AppColors.primaryGradientStart
        case .primaryGradientEnd: return AppColors.primaryGradientEnd
        }
    }
}

struct ColorCustomizationRow: View {
    let colorKey: UIColorCustomization.ColorKey
    let isCustomized: Bool
    let currentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Color swatch
                Circle()
                    .fill(currentColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                
                // Color info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(colorKey.displayName)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if isCustomized {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    Text(colorKey.description)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Customize button
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorCustomizationSheet: View {
    let colorKey: UIColorCustomization.ColorKey
    let currentHex: String?
    @State private var selectedHex: String?
    let onColorSelected: (String) -> Void
    let onReset: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(currentColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: 3)
                            )
                        
                        Text(colorKey.displayName)
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(colorKey.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.top, AppSpacing.lg)
                    
                    // Color Picker
                    TemplateColorPicker(selectedColorHex: $selectedHex)
                        .padding(.horizontal, AppSpacing.lg)
                    
                    // Reset button
                    if currentHex != nil {
                        Button(action: {
                            onReset()
                            dismiss()
                            HapticManager.impact(style: .medium)
                        }) {
                            Text("Reset to Default")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.destructive.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Customize Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if let hex = selectedHex {
                            onColorSelected(hex)
                        }
                        dismiss()
                        HapticManager.impact(style: .medium)
                    }
                    .disabled(selectedHex == nil)
                }
            }
            .onAppear {
                selectedHex = currentHex
            }
        }
    }
    
    private var currentColor: Color {
        if let hex = selectedHex {
            return Color(hex: hex)
        } else if let hex = currentHex {
            return Color(hex: hex)
        } else {
            // Get default color
            switch colorKey {
            case .background: return AppColors.alabasterGrey
            case .foreground: return AppColors.inkBlack
            case .card: return .white
            case .primary: return AppColors.prussianBlue
            case .secondary: return Color(hex: "f5f5f5")
            case .accent: return AppColors.duskBlue
            case .mutedForeground: return AppColors.dustyDenim
            case .onPrimary: return AppColors.alabasterGrey
            case .accentForeground: return AppColors.alabasterGrey
            case .border: return AppColors.dustyDenim
            case .input: return Color(hex: "f5f5f5")
            case .muted: return Color(hex: "f0f0f0")
            case .destructive: return Color(hex: "dc2626")
            case .success: return AppColors.duskBlue
            case .warning: return Color(hex: "d97706")
            case .primaryGradientStart: return AppColors.prussianBlue
            case .primaryGradientEnd: return AppColors.duskBlue
            }
        }
    }
}

struct SavedThemeRow: View {
    let theme: ColorTheme
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Color swatches
            HStack(spacing: 6) {
                ForEach(theme.colors.prefix(5), id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }
            
            // Theme name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(theme.name)
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if isActive {
                        Text("(Active)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Text("\(theme.colors.count) colors")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: AppSpacing.sm) {
                if !isActive {
                    Button(action: onSelect) {
                        Text("Apply")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.destructive)
                        .padding(8)
                        .background(AppColors.destructive.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(isActive ? AppColors.primary.opacity(0.05) : AppColors.secondary)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    UIColorCustomizationView(settingsManager: SettingsManager())
}

