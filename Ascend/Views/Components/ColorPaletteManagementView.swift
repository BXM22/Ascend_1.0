//
//  ColorPaletteManagementView.swift
//  Ascend
//
//  View for importing, managing, and applying color palettes
//

import SwiftUI

struct ColorPaletteManagementView: View {
    @ObservedObject var paletteManager = ColorPaletteManager.shared
    @State private var showImportSheet = false
    @State private var showCreatePalette = false
    @State private var editingPalette: ColorPalette?
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Color Palettes")
                        .font(AppTypography.largeTitleBold)
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Import, save, and reuse color palettes")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                
                // Import Palette Button
                Button(action: {
                    showImportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import from Coolors")
                    }
                    .font(AppTypography.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, AppSpacing.lg)
                
                // Saved Palettes
                if paletteManager.palettes.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.primary.opacity(0.6))
                        
                        Text("No Palettes Yet")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Import a palette from Coolors.co or create a custom one")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Saved Palettes")
                            .font(AppTypography.heading3)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        ForEach(paletteManager.palettes) { palette in
                            ColorPaletteRow(
                                palette: palette,
                                isDefault: paletteManager.defaultPaletteId == palette.id,
                                onEdit: {
                                    editingPalette = palette
                                    showCreatePalette = true
                                },
                                onDelete: {
                                    paletteManager.deletePalette(palette)
                                },
                                onSetDefault: {
                                    paletteManager.setDefaultPalette(palette)
                                },
                                onClearDefault: {
                                    paletteManager.clearDefaultPalette()
                                }
                            )
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .navigationTitle("Color Palettes")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showImportSheet) {
            PaletteImportSheet(onPaletteImported: { palette in
                paletteManager.addPalette(palette)
                showImportSheet = false
            })
        }
        .sheet(isPresented: $showCreatePalette) {
            if let palette = editingPalette {
                CreatePaletteSheet(
                    palette: palette,
                    onSave: { updatedPalette in
                        paletteManager.updatePalette(updatedPalette)
                        editingPalette = nil
                        showCreatePalette = false
                    },
                    onCancel: {
                        editingPalette = nil
                        showCreatePalette = false
                    }
                )
            }
        }
    }
}

struct ColorPaletteRow: View {
    let palette: ColorPalette
    let isDefault: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    let onClearDefault: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(palette.name)
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        if isDefault {
                            Text("(Default)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    Text("\(palette.colors.count) colors")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if isDefault {
                        Button(action: onClearDefault) {
                            Label("Remove Default", systemImage: "star.slash")
                        }
                    } else {
                        Button(action: onSetDefault) {
                            Label("Set as Default", systemImage: "star")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            // Color swatches
            HStack(spacing: 8) {
                ForEach(palette.colors, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete Palette?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(palette.name)'? This action cannot be undone.")
        }
    }
}

struct PaletteImportSheet: View {
    let onPaletteImported: (ColorPalette) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var urlInput: String = ""
    @State private var importError: String?
    @State private var importedColors: [String]?
    @State private var paletteName: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Instructions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Import from Coolors")
                            .font(AppTypography.heading2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Paste a Coolors.co palette URL to import colors")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.mutedForeground)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    
                    // URL Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Palette URL")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("https://coolors.co/palette/...", text: $urlInput)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .onChange(of: urlInput) { _, _ in
                                importError = nil
                                importedColors = nil
                            }
                        
                        if let error = importError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.destructive)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Import Button
                    Button(action: {
                        importPalette()
                    }) {
                        Text("Import Palette")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(urlInput.isEmpty ? LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom) : LinearGradient.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(urlInput.isEmpty)
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Preview
                    if let colors = importedColors {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Preview")
                                .font(AppTypography.heading3)
                                .foregroundColor(AppColors.textPrimary)
                            
                            // Color swatches
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { hex in
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(AppColors.border, lineWidth: 2)
                                            )
                                        
                                        Text(hex.uppercased())
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                }
                            }
                            
                            // Name input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Palette Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                TextField("My Palette", text: $paletteName)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.foreground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(AppColors.input)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Save Button
                            Button(action: {
                                let palette = ColorPalette(
                                    name: paletteName.isEmpty ? "Imported Palette" : paletteName,
                                    colors: colors
                                )
                                onPaletteImported(palette)
                                HapticManager.success()
                            }) {
                                Text("Save Palette")
                                    .font(AppTypography.bodyBold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(paletteName.isEmpty ? LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom) : LinearGradient.primaryGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(paletteName.isEmpty)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Import Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func importPalette() {
        guard !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            importError = "URL cannot be empty"
            return
        }
        
        guard let colors = CoolorsURLParser.parse(urlString: urlInput) else {
            importError = "Invalid Coolors.co URL format"
            return
        }
        
        guard colors.count >= 2 else {
            importError = "Palette must contain at least 2 colors"
            return
        }
        
        // Sort colors by brightness (darkest to lightest) for consistent UI mapping
        let sortedColors = ColorTheme.sortColorsByBrightness(colors)
        importedColors = sortedColors
        
        if paletteName.isEmpty {
            paletteName = "Imported Palette"
        }
        importError = nil
        HapticManager.selection()
    }
}

struct CreatePaletteSheet: View {
    let palette: ColorPalette
    @State private var paletteName: String
    @State private var colorHexes: [String]
    @State private var newColorHex: String = ""
    let onSave: (ColorPalette) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    
    init(palette: ColorPalette, onSave: @escaping (ColorPalette) -> Void, onCancel: @escaping () -> Void) {
        self.palette = palette
        _paletteName = State(initialValue: palette.name)
        _colorHexes = State(initialValue: palette.colors)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Palette Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        TextField("Palette Name", text: $paletteName)
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    
                    // Colors
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Colors")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        // Color list
                        ForEach(Array(colorHexes.enumerated()), id: \.offset) { index, hex in
                            HStack(spacing: AppSpacing.md) {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(AppColors.border, lineWidth: 2)
                                    )
                                
                                Text(hex.uppercased())
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(AppColors.foreground)
                                
                                Spacer()
                                
                                Button(action: {
                                    colorHexes.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppColors.destructive)
                                }
                            }
                            .padding(AppSpacing.sm)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, AppSpacing.lg)
                        }
                        
                        // Add color input
                        HStack(spacing: AppSpacing.sm) {
                            TextField("#FFFFFF", text: $newColorHex)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(AppColors.foreground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(AppColors.input)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .onChange(of: newColorHex) { _, newValue in
                                    newColorHex = newValue.replacingOccurrences(of: "#", with: "").uppercased()
                                    if newColorHex.count > 6 {
                                        newColorHex = String(newColorHex.prefix(6))
                                    }
                                }
                            
                            Button(action: {
                                if isValidHex(newColorHex) {
                                    colorHexes.append(newColorHex)
                                    newColorHex = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(isValidHex(newColorHex) ? AppColors.primary : AppColors.mutedForeground)
                            }
                            .disabled(!isValidHex(newColorHex))
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updated = ColorPalette(
                            id: palette.id,
                            name: paletteName,
                            colors: colorHexes,
                            createdAt: palette.createdAt
                        )
                        onSave(updated)
                    }
                    .disabled(paletteName.isEmpty || colorHexes.isEmpty)
                }
            }
        }
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        guard hex.count == 6 else { return false }
        let hexSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        return hex.unicodeScalars.allSatisfy { hexSet.contains($0) }
    }
}

#Preview {
    ColorPaletteManagementView()
}

