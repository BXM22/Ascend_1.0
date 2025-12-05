#!/bin/bash

# Script to remove alpha channel from all app icons
# This fixes the "Invalid large app icon" error for App Store submission

ICON_DIR="Ascend/Assets.xcassets/AppIcon.appiconset"

echo "Removing alpha channel from app icons..."
echo ""

# Check if sips is available (macOS built-in tool)
if ! command -v sips &> /dev/null; then
    echo "Error: sips command not found. This script requires macOS."
    exit 1
fi

# Process all PNG files in the icon directory
for png_file in "$ICON_DIR"/*.png; do
    if [ -f "$png_file" ]; then
        filename=$(basename "$png_file")
        echo "Processing: $filename"
        
        # Check if file has alpha channel
        has_alpha=$(sips -g hasAlpha "$png_file" 2>/dev/null | grep "hasAlpha" | awk '{print $2}')
        
        if [ "$has_alpha" = "yes" ]; then
            # Create a temporary file with white background
            # First, create a white background image
            temp_bg="/tmp/icon_bg_$$.png"
            width=$(sips -g pixelWidth "$png_file" | awk '{print $2}')
            height=$(sips -g pixelHeight "$png_file" | awk '{print $2}')
            
            # Create white background
            sips -s format png -z "$height" "$width" --setProperty formatOptions 0 --padToHeightWidth "$height" "$width" --padColor FFFFFF /System/Library/CoreServices/DefaultDesktop.heic --out "$temp_bg" 2>/dev/null || \
            convert -size "${width}x${height}" xc:white "$temp_bg" 2>/dev/null || \
            python3 -c "from PIL import Image; Image.new('RGB', ($width, $height), 'white').save('$temp_bg')" 2>/dev/null
            
            if [ -f "$temp_bg" ]; then
                # Composite the icon over white background
                sips --setProperty format png "$png_file" --out "$png_file.tmp" > /dev/null 2>&1
                # Use sips to remove alpha by compositing on white
                sips -s format png "$png_file" --out "$png_file.tmp" > /dev/null 2>&1
                
                # Alternative: Use Python if available (more reliable)
                if command -v python3 &> /dev/null; then
                    python3 << EOF
from PIL import Image
import sys

img = Image.open("$png_file")
if img.mode == 'RGBA':
    # Create white background
    bg = Image.new('RGB', img.size, (255, 255, 255))
    # Paste icon on white background
    bg.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
    bg.save("$png_file.tmp", "PNG")
    print("Fixed with Python")
else:
    # Just copy if no alpha
    img.save("$png_file.tmp", "PNG")
    print("No alpha channel found")
EOF
                fi
                
                if [ -f "$png_file.tmp" ]; then
                    mv "$png_file.tmp" "$png_file"
                    echo "  ✓ Fixed: $filename (removed alpha channel)"
                else
                    echo "  ⚠ Warning: Could not fix $filename automatically"
                fi
                rm -f "$temp_bg"
            else
                echo "  ⚠ Warning: Could not create background for $filename"
            fi
        else
            echo "  ✓ OK: $filename (no alpha channel)"
        fi
    fi
done

echo ""
echo "Done! All icons have been processed."
echo ""
echo "Next steps:"
echo "1. Clean build folder in Xcode (Shift + Cmd + K)"
echo "2. Archive again (Product → Archive)"
echo "3. Try uploading to App Store Connect again"

