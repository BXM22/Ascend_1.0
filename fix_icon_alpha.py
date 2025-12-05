#!/usr/bin/env python3
"""
Script to remove alpha channel from all app icons.
This fixes the "Invalid large app icon" error for App Store submission.
"""

import os
from PIL import Image

ICON_DIR = "Ascend/Assets.xcassets/AppIcon.appiconset"

def remove_alpha_channel(input_path, output_path):
    """Remove alpha channel from PNG image by compositing on white background."""
    try:
        img = Image.open(input_path)
        
        # Check if image has alpha channel
        if img.mode in ('RGBA', 'LA'):
            # Create white background
            bg = Image.new('RGB', img.size, (255, 255, 255))
            
            # Paste image on white background
            if img.mode == 'RGBA':
                bg.paste(img, mask=img.split()[3])  # Use alpha channel as mask
            else:
                bg.paste(img)
            
            # Save as RGB (no alpha)
            bg.save(output_path, "PNG")
            return True
        else:
            # No alpha channel, just copy
            img.save(output_path, "PNG")
            return True
    except Exception as e:
        print(f"Error processing {input_path}: {e}")
        return False

def main():
    print("Removing alpha channel from app icons...")
    print()
    
    if not os.path.exists(ICON_DIR):
        print(f"Error: Directory {ICON_DIR} not found!")
        print("Make sure you run this script from the project root directory.")
        return
    
    fixed_count = 0
    skipped_count = 0
    
    # Process all PNG files
    for filename in os.listdir(ICON_DIR):
        if filename.endswith('.png'):
            filepath = os.path.join(ICON_DIR, filename)
            temp_path = filepath + '.tmp'
            
            print(f"Processing: {filename}")
            
            # Check if image has alpha
            try:
                img = Image.open(filepath)
                has_alpha = img.mode in ('RGBA', 'LA')
            except:
                has_alpha = False
            
            if has_alpha:
                if remove_alpha_channel(filepath, temp_path):
                    # Replace original with fixed version
                    os.replace(temp_path, filepath)
                    print(f"  ✓ Fixed: {filename} (removed alpha channel)")
                    fixed_count += 1
                else:
                    print(f"  ✗ Failed: {filename}")
                    if os.path.exists(temp_path):
                        os.remove(temp_path)
            else:
                print(f"  ✓ OK: {filename} (no alpha channel)")
                skipped_count += 1
    
    print()
    print(f"Done! Fixed {fixed_count} icons, {skipped_count} were already OK.")
    print()
    print("Next steps:")
    print("1. Clean build folder in Xcode (Shift + Cmd + K)")
    print("2. Archive again (Product → Archive)")
    print("3. Try uploading to App Store Connect again")

if __name__ == "__main__":
    main()

