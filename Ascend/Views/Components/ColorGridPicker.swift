//
//  ColorGridPicker.swift
//  Ascend
//
//  Color grid picker organized by hue and saturation
//

import SwiftUI

struct ColorGridPicker: View {
    @Binding var selectedColorHex: String?
    let onColorSelected: (String) -> Void
    
    @State private var colorGrid: [[String]] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Color Chart")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                Spacer()
                
                // Hue labels
                HStack(spacing: 4) {
                    Text("Less Saturated")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.mutedForeground)
                    Text("→")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.mutedForeground)
                    Text("More Saturated")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    // Hue row labels
                    HStack(spacing: 0) {
                        Text("Hue →")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.mutedForeground)
                            .frame(width: 50, alignment: .leading)
                            .padding(.leading, 8)
                        
                        ForEach(0..<5, id: \.self) { satIndex in
                            Spacer()
                        }
                    }
                    
                    // Color grid
                    ForEach(Array(colorGrid.enumerated()), id: \.offset) { hueIndex, row in
                        HStack(spacing: 6) {
                            // Hue indicator
                            Text(hueLabel(for: hueIndex))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                                .frame(width: 50, alignment: .leading)
                                .padding(.leading, 8)
                            
                            // Color swatches
                            ForEach(Array(row.enumerated()), id: \.offset) { satIndex, hex in
                                Button(action: {
                                    selectedColorHex = hex
                                    onColorSelected(hex)
                                    HapticManager.selection()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 36, height: 36)
                                        
                                        if selectedColorHex == hex {
                                            Circle()
                                                .stroke(AppColors.foreground, lineWidth: 3)
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(12)
            }
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onAppear {
            colorGrid = AppColors.generateColorGrid()
        }
    }
    
    private func hueLabel(for index: Int) -> String {
        let hues = ["Red", "Orange", "Yellow", "Lime", "Green", "Teal", "Cyan", "Blue", "Indigo", "Purple", "Pink", "Rose"]
        if index < hues.count {
            return hues[index]
        }
        return "\(index)"
    }
}

#Preview {
    ColorGridPicker(selectedColorHex: .constant(nil)) { hex in
        print("Selected: \(hex)")
    }
    .padding()
    .background(AppColors.background)
}








