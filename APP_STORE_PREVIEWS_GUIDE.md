# 📸 App Store Previews & Screenshots Guide

This guide explains how to add screenshots and app preview videos to App Store Connect for your Ascend app.

## 📋 Required Screenshot Sizes

Apple requires screenshots for at least one device size. Here are the most common sizes:

### iPhone Screenshots (Required for at least one size)

| Device Size | Resolution | Example Devices |
|------------|------------|-----------------|
| **6.7" Display** | 1290 x 2796 pixels | iPhone 14 Pro Max, 15 Pro Max, 16 Pro Max |
| **6.5" Display** | 1242 x 2688 pixels | iPhone 11 Pro Max, XS Max |
| **5.5" Display** | 1242 x 2208 pixels | iPhone 8 Plus, 7 Plus, 6s Plus |

### iPad Screenshots (Optional but recommended)

| Device Size | Resolution | Example Devices |
|------------|------------|-----------------|
| **12.9" Display** | 2048 x 2732 pixels | iPad Pro 12.9" |
| **11" Display** | 1668 x 2388 pixels | iPad Pro 11" |
| **10.5" Display** | 1668 x 2224 pixels | iPad Pro 10.5" |

**Note:** You need at least 3 screenshots, but Apple recommends 5-10 for best results.

## 🎥 App Preview Video Requirements

- **Duration:** 15-30 seconds (recommended: 30 seconds)
- **Format:** MP4, MOV, or M4V
- **Resolution:** Same as screenshot sizes (e.g., 1290 x 2796 for 6.7" iPhone)
- **File Size:** Maximum 500 MB
- **Frame Rate:** 30 fps recommended
- **Audio:** Optional, but if included, must be clear and professional

## 📱 How to Capture Screenshots

### Method 1: Using iOS Simulator (Easiest)

1. **Open Xcode**
2. **Run your app in Simulator:**
   - Select a device from the device menu (e.g., "iPhone 15 Pro Max")
   - Press `Cmd + R` to run
   - Navigate to the screens you want to showcase

3. **Take Screenshots:**
   - In Simulator menu: **Device → Screenshots → Save Screenshot** (or press `Cmd + S`)
   - Screenshots are saved to your Desktop by default
   - The filename includes the device name and resolution

4. **Recommended Screenshots for Ascend:**
   - Dashboard/Home screen
   - Active workout screen
   - Progress/Stats view
   - Templates view
   - Exercise selection/autocomplete

### Method 2: Using Physical iPhone

1. **Take Screenshots:**
   - Navigate to the screen you want
   - Press **Volume Up + Power Button** (or **Volume Up + Side Button** on newer iPhones)
   - Screenshot is saved to Photos

2. **Transfer to Mac:**
   - AirDrop, iCloud Photos, or connect via USB
   - Export from Photos app

3. **Verify Resolution:**
   - Right-click image → Get Info
   - Check dimensions match required sizes

## 🎬 How to Create App Preview Video

### Option 1: Screen Recording in Simulator

1. **Open Simulator with your app running**
2. **Start Screen Recording:**
   - In Simulator menu: **Device → Screenshots → Record Screen** (or press `Cmd + R` twice)
   - Or use QuickTime Player: **File → New Screen Recording**

3. **Record your app:**
   - Navigate through key features
   - Show the main workflows (starting a workout, tracking progress, etc.)
   - Keep it smooth and focused (15-30 seconds)

4. **Stop Recording:**
   - Click the stop button in the menu bar
   - Video is saved to your Desktop

5. **Edit if needed:**
   - Use QuickTime Player to trim
   - Or use iMovie/Final Cut Pro for more advanced editing

### Option 2: Screen Recording on Physical iPhone

1. **Enable Screen Recording:**
   - Settings → Control Center → Add "Screen Recording"
   - Swipe down from top-right (or up from bottom on older iPhones)
   - Tap the Screen Recording button

2. **Record:**
   - Navigate through your app
   - Show key features and workflows
   - Keep it 15-30 seconds

3. **Stop Recording:**
   - Tap the red recording indicator in the status bar
   - Video is saved to Photos

4. **Transfer to Mac:**
   - AirDrop or iCloud Photos
   - Export from Photos app

## 📤 Uploading to App Store Connect

### Step 1: Navigate to Your App

1. **Log into App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Select Your App**
   - Click **"My Apps"**
   - Click on **"Ascend"** (or your app name)

3. **Go to App Store Tab**
   - Click **"App Store"** in the left sidebar
   - Select the version you want to add previews to (or create a new version)

### Step 2: Add Screenshots

1. **Select Device Size**
   - Scroll to the **"Screenshots"** section
   - Click on the device size you want to add (e.g., "6.7" Display")

2. **Upload Screenshots**
   - Click **"+"** or drag and drop images
   - Select your screenshot files
   - **Order matters!** Drag to reorder
   - Apple recommends showing your best screenshots first

3. **Add Multiple Sizes (Recommended)**
   - Repeat for other device sizes (6.5", 5.5", etc.)
   - This ensures your app looks good on all devices

4. **Minimum Requirements:**
   - At least 3 screenshots for one device size
   - Screenshots must be in the exact resolution specified
   - Images must be PNG or JPEG format

### Step 3: Add App Preview Video (Optional but Recommended)

1. **In the Same Section**
   - Scroll to **"App Preview"** (right below Screenshots)
   - Click **"+"** or drag and drop your video file

2. **Upload Video**
   - Select your MP4, MOV, or M4V file
   - Wait for upload and processing (may take a few minutes)

3. **Add Preview for Multiple Sizes**
   - You can add different previews for different device sizes
   - Or use the same preview for all sizes

### Step 4: Add Screenshots for iPad (Optional)

1. **Scroll to iPad Section**
   - If your app supports iPad, add iPad screenshots
   - Follow the same process as iPhone screenshots

## ✅ Best Practices

### Screenshot Tips

1. **Show Key Features:**
   - First screenshot should be your most impressive screen
   - Show the main value proposition
   - Highlight unique features

2. **Tell a Story:**
   - Screenshots should flow logically
   - Show the user journey (e.g., Dashboard → Workout → Progress)

3. **Keep Text Minimal:**
   - Screenshots should be self-explanatory
   - If you add text overlays, keep them concise
   - Use clear, readable fonts

4. **Show Real Content:**
   - Use actual data, not placeholder text
   - Make it look polished and professional

5. **Consider Localization:**
   - If you plan to support multiple languages, you'll need screenshots for each

### App Preview Video Tips

1. **Hook Viewers Immediately:**
   - First 3 seconds are crucial
   - Show the most impressive feature right away

2. **Keep It Simple:**
   - Focus on 2-3 key features
   - Don't try to show everything

3. **Smooth Navigation:**
   - Avoid rapid scrolling or jerky movements
   - Use smooth transitions

4. **Add Subtitles (Optional):**
   - Many users watch videos without sound
   - Consider adding text overlays explaining features

5. **Test on Device:**
   - Make sure the video looks good on actual devices
   - Check that text is readable

## 🎨 Screenshot Editing Tools

If you need to edit or optimize screenshots:

- **Preview (Mac):** Built-in, can crop and adjust
- **Photos (Mac/iOS):** Basic editing
- **Sketch/Figma:** For adding text overlays or graphics
- **Canva:** Easy-to-use design tool
- **Photoshop:** Professional editing

## 📝 Checklist Before Submission

- [ ] At least 3 screenshots for one device size
- [ ] Screenshots are in the correct resolution
- [ ] Screenshots show key features clearly
- [ ] App preview video is 15-30 seconds (optional)
- [ ] All images are high quality and professional
- [ ] Screenshots are in the correct order
- [ ] No placeholder text or dummy data (unless intentional)
- [ ] Screenshots match your current app version

## 🚨 Common Issues & Solutions

### Issue: "Invalid Image Dimensions"
**Solution:** Make sure your screenshot is exactly the required resolution. Use an image editor to resize if needed.

### Issue: "File Too Large"
**Solution:** Compress images using Preview or an image optimization tool. Screenshots should be under 10MB each.

### Issue: "Video Format Not Supported"
**Solution:** Convert to MP4 using QuickTime Player (File → Export → Movie) or HandBrake.

### Issue: "Screenshots Don't Match App"
**Solution:** Make sure you're uploading screenshots from the current version of your app.

## 📚 Additional Resources

- **App Store Connect Help:** https://help.apple.com/app-store-connect/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **App Store Marketing Guidelines:** https://developer.apple.com/app-store/marketing/guidelines/

---

## Quick Reference: Screenshot Sizes for Ascend

**Minimum Required:**
- iPhone 6.7" Display: 1290 x 2796 pixels (3+ screenshots)

**Recommended:**
- iPhone 6.5" Display: 1242 x 2688 pixels
- iPhone 5.5" Display: 1242 x 2208 pixels
- iPad 12.9": 2048 x 2732 pixels (if supporting iPad)

**App Preview:**
- Same resolution as screenshots
- 15-30 seconds duration
- MP4, MOV, or M4V format

---

**Need Help?** If you encounter any issues, check the App Store Connect help documentation or contact Apple Developer Support.

