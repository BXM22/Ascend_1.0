//
//  TemplateColorPicker.swift
//  Ascend
//
//  Color picker component for template customization
//

import SwiftUI

struct TemplateColorPicker: View {
    @Binding var selectedColorHex: String?
    @State private var showColorPicker = false
    @State private var customHexInput: String = ""
    @State private var showHexInput = false
    @ObservedObject private var paletteManager = ColorPaletteManager.shared
    
    private var selectedColor: Color {
        if let hex = selectedColorHex {
            return Color(hex: hex)
        }
        return AppColors.primary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Template Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
                
                // Current color indicator
                Button(action: {
                    showColorPicker.toggle()
                    HapticManager.selection()
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.border, lineWidth: 2)
                            )
                        
                        Text(selectedColorHex == nil ? "Auto" : "Custom")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.foreground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            if showColorPicker {
                VStack(spacing: 12) {
                    // Auto option
                    Button(action: {
                        selectedColorHex = nil
                        showColorPicker = false
                        HapticManager.selection()
                    }) {
                        HStack {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColorHex == nil ? AppColors.primary : Color.clear, lineWidth: 3)
                                )
                            
                            Text("Auto (Based on exercises)")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.foreground)
                            
                            Spacer()
                            
                            if selectedColorHex == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedColorHex == nil ? AppColors.primary.opacity(0.1) : AppColors.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Preset color palette grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preset Colors")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(AppColors.templateColorPalette, id: \.hex) { colorOption in
                                Button(action: {
                                    selectedColorHex = colorOption.hex
                                    showColorPicker = false
                                    HapticManager.selection()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: colorOption.hex))
                                            .frame(width: 40, height: 40)
                                        
                                        if selectedColorHex == colorOption.hex {
                                            Circle()
                                                .stroke(AppColors.foreground, lineWidth: 3)
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(12)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Saved Palettes
                    if !paletteManager.palettes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Saved Palettes")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.mutedForeground)
                                
                                Spacer()
                                
                                if let defaultPalette = paletteManager.defaultPalette {
                                    Button(action: {
                                        // Apply first color from default palette
                                        if let firstColor = defaultPalette.colors.first {
                                            selectedColorHex = firstColor
                                            showColorPicker = false
                                            HapticManager.impact(style: .medium)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                            Text("Apply Default")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundColor(AppColors.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppColors.primary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                            
                            ForEach(paletteManager.palettes) { palette in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        HStack(spacing: 4) {
                                            if palette.isDefault {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(AppColors.primary)
                                            }
                                            Text(palette.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(AppColors.foreground)
                                        }
                                        
                                        Spacer()
                                        
                                        // Quick apply button for default palette
                                        if palette.isDefault && palette.colors.count > 0 {
                                            Button(action: {
                                                // Apply first color from default palette
                                                if let firstColor = palette.colors.first {
                                                    selectedColorHex = firstColor
                                                    showColorPicker = false
                                                    HapticManager.impact(style: .medium)
                                                }
                                            }) {
                                                Text("Apply")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(AppColors.primary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(AppColors.primary.opacity(0.1))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                        }
                                    }
                                    
                                    // Palette colors
                                    HStack(spacing: 6) {
                                        ForEach(palette.colors, id: \.self) { hex in
                                            Button(action: {
                                                selectedColorHex = hex
                                                showColorPicker = false
                                                HapticManager.selection()
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(hex: hex))
                                                        .frame(width: 32, height: 32)
                                                    
                                                    if selectedColorHex == hex {
                                                        Circle()
                                                            .stroke(AppColors.foreground, lineWidth: 2)
                                                            .frame(width: 32, height: 32)
                                                        
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .shadow(color: .black.opacity(0.3), radius: 1)
                                                    }
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(10)
                                .background(palette.isDefault ? AppColors.primary.opacity(0.05) : AppColors.secondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(palette.isDefault ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(12)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Color grid chart
                    ColorGridPicker(selectedColorHex: $selectedColorHex) { hex in
                        showColorPicker = false
                    }
                    
                    // Custom hex color input
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            showHexInput.toggle()
                            if showHexInput && customHexInput.isEmpty {
                                customHexInput = selectedColorHex ?? ""
                            }
                            HapticManager.selection()
                        }) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 14))
                                Text("Custom Color (Hex)")
                                    .font(.system(size: 14))
                                Spacer()
                                Image(systemName: showHexInput ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(AppColors.foreground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColors.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        if showHexInput {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("#")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.mutedForeground)
                                    
                                    TextField("FFFFFF", text: $customHexInput)
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppColors.foreground)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.asciiCapable)
                                        .onChange(of: customHexInput) { _, newValue in
                                            // Remove # if user types it
                                            customHexInput = newValue.replacingOccurrences(of: "#", with: "").uppercased()
                                            // Limit to 6 characters
                                            if customHexInput.count > 6 {
                                                customHexInput = String(customHexInput.prefix(6))
                                            }
                                        }
                                    
                                    // Color preview
                                    if isValidHex(customHexInput) {
                                        Circle()
                                            .fill(Color(hex: customHexInput))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(AppColors.border, lineWidth: 2)
                                            )
                                    } else {
                                        Circle()
                                            .fill(AppColors.secondary)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "questionmark")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.mutedForeground)
                                            )
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(AppColors.input)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                
                                if !customHexInput.isEmpty && !isValidHex(customHexInput) {
                                    Text("Invalid hex color. Use 6 characters (0-9, A-F).")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.destructive)
                                }
                                
                                Button(action: {
                                    if isValidHex(customHexInput) {
                                        selectedColorHex = customHexInput
                                        showColorPicker = false
                                        HapticManager.selection()
                                    }
                                }) {
                                    Text("Apply Custom Color")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(isValidHex(customHexInput) ? LinearGradient.primaryGradient : LinearGradient(colors: [AppColors.secondary], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .disabled(!isValidHex(customHexInput))
                            }
                            .padding(12)
                            .background(AppColors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showColorPicker)
        .animation(.easeInOut(duration: 0.2), value: showHexInput)
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        guard hex.count == 6 else { return false }
        let hexSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        return hex.unicodeScalars.allSatisfy { hexSet.contains($0) }
    }
}

#Preview {
    TemplateColorPicker(selectedColorHex: .constant(nil))
        .padding()
        .background(AppColors.background)
}

