#!/bin/bash

# Simple script to remove alpha channel using macOS built-in tools
# No Python packages required!

ICON_DIR="Ascend/Assets.xcassets/AppIcon.appiconset"

echo "Removing alpha channel from app icons..."
echo "Using macOS built-in tools (no extra packages needed)"
echo ""

if [ ! -d "$ICON_DIR" ]; then
    echo "Error: Directory $ICON_DIR not found!"
    echo "Make sure you run this from the project root."
    exit 1
fi

# Process each PNG file
for png_file in "$ICON_DIR"/*.png; do
    if [ -f "$png_file" ]; then
        filename=$(basename "$png_file")
        echo "Processing: $filename"
        
        # Check if file has alpha channel
        has_alpha=$(sips -g hasAlpha "$png_file" 2>/dev/null | grep "hasAlpha" | awk '{print $2}')
        
        if [ "$has_alpha" = "yes" ]; then
            # Get image dimensions
            width=$(sips -g pixelWidth "$png_file" 2>/dev/null | grep "pixelWidth" | awk '{print $2}')
            height=$(sips -g pixelHeight "$png_file" 2>/dev/null | grep "pixelHeight" | awk '{print $2}')
            
            if [ -n "$width" ] && [ -n "$height" ]; then
                # Create temporary file with white background and composite
                temp_file="${png_file}.fixed"
                
                # Method: Export as JPEG (no alpha) then convert back to PNG
                # This removes alpha channel
                sips -s format jpeg -s formatOptions 100 "$png_file" --out "$temp_file" > /dev/null 2>&1
                
                if [ -f "$temp_file" ]; then
                    # Convert back to PNG
                    sips -s format png "$temp_file" --out "$png_file" > /dev/null 2>&1
                    rm -f "$temp_file"
                    
                    # Verify alpha is removed
                    new_alpha=$(sips -g hasAlpha "$png_file" 2>/dev/null | grep "hasAlpha" | awk '{print $2}')
                    if [ "$new_alpha" = "no" ]; then
                        echo "  ✓ Fixed: $filename (alpha channel removed)"
                    else
                        echo "  ⚠ Warning: $filename may still have alpha"
                    fi
                else
                    echo "  ✗ Failed: $filename"
                fi
            else
                echo "  ⚠ Warning: Could not read dimensions for $filename"
            fi
        else
            echo "  ✓ OK: $filename (no alpha channel)"
        fi
    fi
done

echo ""
echo "Done! All icons processed."
echo ""
echo "Next steps:"
echo "1. Clean build folder in Xcode (Shift + Cmd + K)"
echo "2. Archive again (Product → Archive)"
echo "3. Try uploading to App Store Connect again"

