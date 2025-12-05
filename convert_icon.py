#!/usr/bin/env python3
"""
Convert SVG to PNG for iOS app icons
Requires: pip install svglib reportlab
"""

import os
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM

def convert_svg_to_png(svg_path, png_path, size):
    """Convert SVG to PNG at specified size"""
    try:
        drawing = svg2rlg(svg_path)
        if drawing:
            drawing.width = size
            drawing.height = size
            drawing.scale(size / 200, size / 200)  # Original SVG is 200x200
            renderPM.drawToFile(drawing, png_path, fmt='PNG', dpi=72)
            print(f"Created {png_path} ({size}x{size})")
            return True
    except Exception as e:
        print(f"Error converting to {size}x{size}: {e}")
        return False

# Icon sizes needed for iOS
sizes = {
    "AppIcon-20x20@1x.png": 20,
    "AppIcon-20x20@2x.png": 40,
    "AppIcon-20x20@3x.png": 60,
    "AppIcon-29x29@1x.png": 29,
    "AppIcon-29x29@2x.png": 58,
    "AppIcon-29x29@3x.png": 87,
    "AppIcon-40x40@1x.png": 40,
    "AppIcon-40x40@2x.png": 80,
    "AppIcon-40x40@3x.png": 120,
    "AppIcon-60x60@2x.png": 120,
    "AppIcon-60x60@3x.png": 180,
    "AppIcon-76x76@1x.png": 76,
    "AppIcon-76x76@2x.png": 152,
    "AppIcon-83.5x83.5@2x.png": 167,
    "AppIcon-1024x1024@1x.png": 1024,
}

svg_path = "Ascend/Assets.xcassets/AppIcon.appiconset/logo.svg"
output_dir = "Ascend/Assets.xcassets/AppIcon.appiconset/"

if not os.path.exists(svg_path):
    print(f"Error: {svg_path} not found")
    exit(1)

for filename, size in sizes.items():
    png_path = os.path.join(output_dir, filename)
    convert_svg_to_png(svg_path, png_path, size)

print("\nDone! All icon sizes have been generated.")

