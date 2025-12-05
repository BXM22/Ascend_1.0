# Testing Ascend on Your iPhone

This guide covers two methods: **FREE direct installation** (for testing on your own device) and **TestFlight** (for sharing with others, requires paid account).

**👉 For free testing on just your phone, use the FREE Method below!**

---

## 🆓 FREE Method: Direct Installation (Recommended for Personal Testing)

This method is **completely free** and lets you install the app directly on your iPhone using Xcode. No paid Apple Developer account needed!

### Prerequisites (Free Method)

- **Mac with Xcode installed**
- **iPhone with USB cable** (or wireless connection)
- **Free Apple ID** (the same one you use for the App Store)

### Step-by-Step: Free Installation

1. **Connect Your iPhone**
   - Connect your iPhone to your Mac using a USB cable
   - Unlock your iPhone and tap "Trust This Computer" if prompted
   - Make sure your iPhone is unlocked during the process

2. **Sign In to Xcode with Your Apple ID**
   - Open Xcode
   - Go to **Xcode → Settings** (or **Preferences** on older versions)
   - Click the **Accounts** tab
   - Click the **+** button and select **Apple ID**
   - Sign in with your Apple ID (the free one you use for the App Store)
   - Your account will appear as "Personal Team" or "Free Account"

3. **Configure Signing in Your Project** (Detailed Steps)

   **Step 3.1: Open Your Project**
   - Open Terminal (or use Finder)
   - Navigate to your project folder, or run:
     ```bash
     cd /Users/ashtonalva/Projects/Ascend_1.0
     open Ascend.xcodeproj
     ```
   - Xcode will open with your project

   **Step 3.2: Select Your Project in the Navigator**
   - Look at the left sidebar in Xcode (the Navigator panel)
   - At the very top, you'll see a blue icon with "Ascend" next to it
   - Click on this blue "Ascend" item (it's the project root)
   - This will show the project settings in the main editor area

   **Step 3.3: Select the Target**
   - In the main editor area, you'll see a list of targets (usually just "Ascend")
   - Under the "TARGETS" section, click on **"Ascend"** (the app target, not the test targets)
   - The right side of the editor will update to show target-specific settings

   **Step 3.4: Open Signing & Capabilities Tab**
   - At the top of the editor area, you'll see tabs like: "General", "Signing & Capabilities", "Info", "Build Settings", etc.
   - Click on the **"Signing & Capabilities"** tab
   - You should now see signing options

   **Step 3.5: Enable Automatic Signing**
   - In the "Signing & Capabilities" section, you'll see a checkbox that says:
     **"Automatically manage signing"**
   - Check this box (click the checkbox to put a checkmark in it)
   - Once checked, Xcode will automatically handle certificates and provisioning profiles

   **Step 3.6: Select Your Team**
   - Below the "Automatically manage signing" checkbox, you'll see a dropdown menu labeled **"Team"**
   - Click on the dropdown menu
   - You should see your Apple ID listed, something like:
     - "Your Name (Personal Team)" or
     - "your.email@example.com (Personal Team)"
   - Select your Apple ID from the list
   - If you don't see your Apple ID, go back to Step 2 and make sure you added it to Xcode

   **Step 3.7: Verify It Worked**
   - After selecting your team, Xcode will automatically:
     - Create a provisioning profile
     - Set up code signing
   - You should see:
     - ✓ "Automatically manage signing" checkbox is checked
     - Team: "Your Name (Personal Team)" is selected
     - Bundle Identifier: `com.app.com.Ascend`
     - Signing Certificate: "Apple Development"
     - Provisioning Profile: "Xcode Managed Profile"

   **⚠️ Common Warnings (These are Normal!):**
   
   If you see yellow warning triangles with messages like:
   - **"Status Communication with Apple failed"** - "Your team has no devices from which to generate a provisioning profile"
   - **"No profiles for 'com.app.com.Ascend' were found"**
   
   **Don't worry!** These warnings are normal and will be resolved when you:
   1. Connect your iPhone (Step 1 - make sure it's connected and unlocked)
   2. Click the **"Try Again"** button next to the warning, OR
   3. Simply proceed to Step 4 (select your iPhone) - Xcode will automatically fix this when you build

   **What You Should See (After Device is Connected):**
   ```
   ✓ Automatically manage signing
   Team: Your Name (Personal Team)
   Bundle Identifier: com.app.com.Ascend
   Signing Certificate: Apple Development
   Provisioning Profile: Xcode Managed Profile
   (No yellow warnings)
   ```

   **If You See Red Errors:**
   - "No accounts with App Store Connect access" → This is normal for free accounts, ignore it
   - "Failed to register bundle identifier" → Try changing the bundle ID to something unique like `com.yourname.Ascend`
   - "No signing certificate found" → Make sure you completed Step 2 (signing in to Xcode)

4. **Select Your iPhone as the Build Target**
   - At the top of Xcode, next to the play/stop buttons
   - Click the device selector (it might say "Any iOS Device" or a simulator name)
   - Select your connected iPhone from the list
   - If your iPhone doesn't appear, make sure it's unlocked and trusted

5. **Build and Run**
   - Click the **Play button** (▶️) or press **Cmd + R**
   - Xcode will build the app and install it on your iPhone
   - The first time, you may need to:
     - Trust the developer on your iPhone: **Settings → General → VPN & Device Management** → Trust your developer account
   - The app will launch automatically on your iPhone!

### Important Notes for Free Method

- **App Expiration**: Apps installed this way expire after **7 days**. You'll need to rebuild and reinstall weekly.
- **Device Limit**: You can install on up to **3 devices** with a free account
- **No App Store**: This method doesn't use the App Store or TestFlight - it's direct installation
- **Updates**: To update the app, just build and run again from Xcode

### Troubleshooting Free Method

1. **"No accounts with App Store Connect access"**
   - This is normal for free accounts - ignore it
   - Make sure you selected your Personal Team in Signing & Capabilities

2. **"Failed to register bundle identifier"**
   - Xcode will automatically create a provisioning profile
   - If it fails, try changing the bundle identifier to something unique like `com.yourname.Ascend`

3. **"Untrusted Developer" on iPhone**
   - Go to **Settings → General → VPN & Device Management**
   - Tap on your Apple ID email
   - Tap **"Trust [Your Email]"**

4. **iPhone not showing in device list**
   - Make sure iPhone is unlocked
   - Try unplugging and replugging the USB cable
   - Check that you tapped "Trust This Computer" on your iPhone

---

## 💰 TestFlight Method (Paid - For Sharing with Others)

This method requires a **paid Apple Developer Program membership ($99/year)** but allows you to share your app with up to 10,000 testers via TestFlight.

### Prerequisites (TestFlight Method)

1. **Apple Developer Account** - You need an active Apple Developer Program membership ($99/year)
   - Sign up at: https://developer.apple.com/programs/
   - This is required to distribute apps via TestFlight

2. **App Store Connect Access**
   - Log in at: https://appstoreconnect.apple.com
   - Make sure you have Admin or App Manager access

## Step-by-Step Process

### Step 1: Configure Your App in Xcode

1. **Open your project in Xcode**
   ```bash
   open Ascend.xcodeproj
   ```

2. **Set up Signing & Capabilities**
   - Select your project in the navigator
   - Select the "Ascend" target
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Team (your Apple Developer account)
   - Xcode will automatically create/select a provisioning profile

3. **Verify Bundle Identifier**
   - Current bundle ID: `com.app.com.Ascend`
   - Make sure this matches what you'll register in App Store Connect
   - If you need to change it, update it in the project settings

### Step 2: Create App in App Store Connect

1. **Log into App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Navigate to "My Apps"

2. **Create New App**
   - Click the "+" button to create a new app
   - Fill in the required information:
     - **Platform**: iOS
     - **Name**: Ascend (or your preferred name)
     - **Primary Language**: English (or your preferred)
     - **Bundle ID**: Select or register `com.app.com.Ascend`
     - **SKU**: A unique identifier (e.g., `ascend-001`)
     - **User Access**: Full Access (for TestFlight)

3. **Complete App Information**
   - Fill in the required app information
   - Upload app screenshots (required for TestFlight)
   - Add app description
   - Set privacy policy URL (if required)

### Step 3: Archive and Upload Your App

1. **Select Generic iOS Device**
   - In Xcode, select "Any iOS Device" or "Generic iOS Device" from the device selector
   - This is required to create an archive

2. **Clean Build Folder**
   - Product → Clean Build Folder (Shift + Cmd + K)

3. **Archive the App**
   - Product → Archive
   - Wait for the archive process to complete
   - The Organizer window will open automatically

4. **Validate the Archive**
   - In the Organizer, select your archive
   - Click "Validate App"
   - Fix any issues that come up

5. **Distribute the App**
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Upload"
   - Follow the prompts:
     - Select your distribution options
     - Choose automatic signing (recommended)
     - Review the summary
     - Click "Upload"
   - Wait for the upload to complete (this can take several minutes)

### Step 4: Set Up TestFlight

1. **Wait for Processing**
   - After upload, go to App Store Connect
   - Navigate to your app → TestFlight tab
   - Wait for Apple to process your build (usually 10-30 minutes, sometimes longer)
   - You'll see a status indicator showing processing progress

2. **Add Test Information**
   - Once processing is complete, you'll need to:
     - Answer export compliance questions
     - Add test information (optional but recommended)

3. **Add Internal Testers**
   - Go to TestFlight → Internal Testing
   - Add yourself and your team members as internal testers
   - Internal testers can test immediately (up to 100 people)
   - They must be added to your App Store Connect team

4. **Add External Testers (Optional)**
   - Go to TestFlight → External Testing
   - Create a new group
   - Add the build you want to test
   - Add testers by email (up to 10,000 external testers)
   - Submit for Beta App Review (required for external testing)
   - Review typically takes 24-48 hours

### Step 5: Install TestFlight on Your iPhone

1. **Download TestFlight App**
   - Install the TestFlight app from the App Store on your iPhone
   - It's a free app from Apple

2. **Accept Invitation**
   - If you're an internal tester, you'll automatically see the build
   - If you're an external tester, check your email for an invitation
   - Open the invitation on your iPhone and accept it

3. **Install the App**
   - Open the TestFlight app on your iPhone
   - Find "Ascend" in your list of available apps
   - Tap "Install" to download and install the app
   - The app will appear on your home screen

## Troubleshooting

### Common Issues

1. **"No accounts with App Store Connect access"**
   - Make sure you're signed in with an Apple ID that has App Store Connect access
   - Xcode → Preferences → Accounts → Add your Apple ID

2. **"Bundle identifier is already in use"**
   - The bundle ID `com.app.com.Ascend` might already be registered
   - Either use a different bundle ID or claim the existing one in App Store Connect

3. **Upload fails**
   - Check your internet connection
   - Make sure you're using the latest version of Xcode
   - Verify your Apple Developer account is active

4. **Build not appearing in TestFlight**
   - Wait for processing (can take up to an hour)
   - Check for any compliance issues in App Store Connect
   - Make sure you completed all required information

5. **Can't install on device**
   - Make sure you accepted the TestFlight invitation
   - Check that your device is registered in your developer account
   - Try deleting and reinstalling the TestFlight app

## Quick Reference Commands

```bash
# Open project in Xcode
open Ascend.xcodeproj

# Clean build (in Xcode)
# Product → Clean Build Folder (Shift + Cmd + K)

# Archive (in Xcode)
# Product → Archive
```

## Important Notes

- **Build Expiration**: TestFlight builds expire after 90 days
- **Version Numbers**: Each build needs a unique build number (increment `CURRENT_PROJECT_VERSION`)
- **Testing Limits**: 
  - Internal testers: Up to 100 people, immediate access
  - External testers: Up to 10,000 people, requires Beta App Review
- **Update Frequency**: You can upload new builds as often as needed
- **Feedback**: Testers can provide feedback directly through the TestFlight app

## Next Steps After First Upload

1. Test the app thoroughly on your device
2. Share TestFlight links with your team
3. Collect feedback from testers
4. Fix bugs and upload new builds as needed
5. When ready, submit for App Store review

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

