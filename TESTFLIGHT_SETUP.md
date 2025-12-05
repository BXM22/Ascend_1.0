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

---

## 🚀 App Store Submission Guide

Now that you have an Apple Developer membership, here's how to submit your app to the App Store for public release.

### Prerequisites

- ✅ Active Apple Developer Program membership ($99/year)
- ✅ App tested and working properly
- ✅ App Store Connect account access
- ✅ App screenshots and metadata ready

### Step 1: Prepare Your App for Submission

**1.1: Update Version Numbers**
- In Xcode, select your project → Target "Ascend" → General tab
- **Version**: This is your public version (e.g., "1.0", "1.1", "2.0")
- **Build**: This must be unique for each upload (e.g., "1", "2", "3")
- For your first submission, use Version: "1.0", Build: "1"

**1.2: Configure Signing for App Store**
- Go to Signing & Capabilities tab
- Make sure "Automatically manage signing" is checked
- Select your **paid Apple Developer Team** (not "Personal Team")
- The Team should show your organization name, not "Personal Team"
- Bundle Identifier should be: `com.app.com.Ascend`

**1.3: Set App Icon and Launch Screen**
- Make sure you have app icons in `Assets.xcassets/AppIcon.appiconset/`
- Verify all required icon sizes are present
- Test that your app launches properly

**1.4: Test Your App Thoroughly**
- Test on multiple devices if possible
- Test all features and workflows
- Check for crashes or bugs
- Verify app works offline (if applicable)

### Step 2: Create App in App Store Connect

**2.1: Log into App Store Connect**
- Go to https://appstoreconnect.apple.com
- Sign in with your Apple Developer account

**2.2: Create New App (If Not Already Created)**
- Click **"My Apps"** in the top navigation
- Click the **"+"** button → **"New App"**
- Fill in the required information:
  - **Platform**: iOS
  - **Name**: Ascend (or your app name - max 30 characters)
  - **Primary Language**: English (or your preferred language)
  - **Bundle ID**: Select `com.app.com.Ascend` (or register it if needed)
  - **SKU**: A unique identifier (e.g., `ascend-001`) - this is for your records only
  - **User Access**: Full Access
- Click **"Create"**

**2.3: Register Bundle ID (If Needed)**
- If your bundle ID isn't registered yet:
  - Go to https://developer.apple.com/account/resources/identifiers/list
  - Click **"+"** to add a new identifier
  - Select **"App IDs"** → Continue
  - Select **"App"** → Continue
  - Description: "Ascend App"
  - Bundle ID: `com.app.com.Ascend` (or use "Explicit" and enter it)
  - Select any capabilities your app uses
  - Click **"Continue"** → **"Register"**

### Step 3: Prepare App Store Assets

**3.1: App Screenshots (Required)**
You need screenshots for at least one device size. Apple requires:
- **iPhone 6.7" Display** (iPhone 14 Pro Max, 15 Pro Max, etc.): 1290 x 2796 pixels
- **iPhone 6.5" Display** (iPhone 11 Pro Max, XS Max): 1242 x 2688 pixels
- **iPhone 5.5" Display** (iPhone 8 Plus, etc.): 1242 x 2208 pixels

**How to Take Screenshots:**
1. Run your app in the iOS Simulator
2. Navigate to the screens you want to showcase
3. In Simulator: **Device → Screenshots → Save Screenshot** (or Cmd + S)
4. Or use your actual iPhone and take screenshots
5. Edit/crop as needed to match required dimensions

**3.2: App Preview Video (Optional but Recommended)**
- 15-30 second video showcasing your app
- Same dimensions as screenshots
- Can significantly improve conversion rates

**3.3: App Description**
- **Name**: Ascend (or your chosen name, max 30 characters)
- **Subtitle**: Short tagline (max 30 characters, optional)
- **Description**: Detailed description of your app (max 4000 characters)
  - First sentence is crucial - it appears in search results
  - Highlight key features
  - Use bullet points for readability
  - Include keywords naturally

**3.4: Keywords**
- Up to 100 characters
- Comma-separated
- No spaces after commas
- Example: "workout,fitness,calisthenics,training,exercise"

**3.5: Support URL**
- Required: A website URL for support
- Can be a simple landing page or your website
- Example: `https://yourwebsite.com/support`

**3.6: Marketing URL (Optional)**
- Your app's marketing website
- Optional but recommended

**3.7: Privacy Policy URL (Required if app collects data)**
- Required if your app:
  - Collects user data
  - Uses analytics
  - Has user accounts
  - Tracks users
- Create a privacy policy page
- Host it on your website or use a privacy policy generator

**3.8: App Category**
- Primary Category: Select the best fit (e.g., "Health & Fitness", "Lifestyle")
- Secondary Category (optional): Select another relevant category

**3.9: App Age Rating**
- Complete the age rating questionnaire
- Answer questions about your app's content
- Apple will assign a rating (4+, 9+, 12+, 17+)

### Step 4: Archive and Upload Your App

**4.1: Select Generic iOS Device**
- In Xcode, at the top next to the play button
- Click the device selector
- Select **"Any iOS Device"** or **"Generic iOS Device"**
- This is required to create an archive

**4.2: Clean Build Folder**
- **Product → Clean Build Folder** (or press **Shift + Cmd + K**)
- This ensures a fresh build

**4.3: Archive the App**
- **Product → Archive**
- Wait for the archive to complete (this may take a few minutes)
- The Organizer window will open automatically showing your archive

**4.4: Validate the Archive**
- In the Organizer, select your archive
- Click **"Validate App"**
- Select **"App Store Connect"** → **Next**
- Select your team → **Next**
- Choose **"Automatically manage signing"** → **Next**
- Review the summary → **Validate**
- Fix any errors that appear
- If validation passes, you're ready to upload!

**4.5: Distribute to App Store Connect**
- In the Organizer, with your archive selected
- Click **"Distribute App"**
- Select **"App Store Connect"** → **Next**
- Choose **"Upload"** → **Next**
- Select your distribution options:
  - ✅ **"Upload your app's symbols"** (recommended for crash reporting)
  - ✅ **"Manage Version and Build Number"** (if you want Xcode to manage it)
- Click **Next**
- Choose **"Automatically manage signing"** → **Next**
- Review the summary → **Upload**
- Wait for upload to complete (this can take 5-15 minutes depending on app size)

### Step 5: Complete App Store Listing

**5.1: Wait for Processing**
- Go to App Store Connect → My Apps → Your App
- Click on **"1.0 Prepare for Submission"** (or your version number)
- Wait for Apple to process your build (usually 10-30 minutes, sometimes up to 2 hours)
- You'll see processing status in the "Build" section
- Once processed, you'll see a green checkmark ✅

**5.2: Select Your Build**
- In the "Build" section, click **"+ Select a build"**
- Choose the build you just uploaded
- Click **"Done"**

**5.3: Fill Out App Information**
- **Screenshots**: Upload your screenshots for each required device size
- **Description**: Enter your app description
- **Keywords**: Enter your keywords
- **Support URL**: Enter your support URL
- **Marketing URL**: Enter if you have one
- **Privacy Policy URL**: Enter if required
- **Category**: Select primary and secondary categories
- **Age Rating**: Complete the questionnaire

**5.4: App Review Information**
- **Contact Information**:
  - First Name, Last Name
  - Phone Number
  - Email Address
- **Demo Account** (if your app requires login):
  - Provide test account credentials
  - Include any special instructions
- **Notes** (optional):
  - Any special instructions for reviewers
  - Explain any features that might need clarification

**5.5: Version Information**
- **What's New in This Version**: Description of changes (for updates)
- For first version, you can say "Initial release" or describe key features

**5.6: Pricing and Availability**
- **Price**: Select "Free" or set a price
- **Availability**: Choose countries where your app will be available
- **Schedule**: Set automatic release or manual release after approval

### Step 6: Submit for Review

**6.1: Final Checks**
Before submitting, make sure:
- ✅ All required fields are filled
- ✅ Screenshots are uploaded
- ✅ Build is selected and processed
- ✅ App description is complete
- ✅ Support URL is provided
- ✅ Privacy policy is provided (if needed)
- ✅ Age rating is complete
- ✅ Contact information is filled

**6.2: Submit**
- Scroll to the top of the page
- Click **"Add for Review"** or **"Submit for Review"**
- Confirm any final prompts
- Your app status will change to **"Waiting for Review"**

**6.3: What Happens Next**
- **In Review**: Apple is reviewing your app (typically 24-48 hours, can be longer)
- **Pending Developer Release**: Approved, waiting for you to release
- **Ready for Sale**: Your app is live on the App Store!
- **Rejected**: Review feedback provided, fix issues and resubmit

### Step 7: After Submission

**7.1: Monitor Status**
- Check App Store Connect regularly
- You'll receive email notifications about status changes
- Check the "App Review" section for any messages

**7.2: If Your App is Rejected**
- Read the rejection reason carefully
- Fix the issues mentioned
- Update your app and upload a new build
- Resubmit with explanation of fixes
- You can also appeal if you disagree with the rejection

**7.3: If Your App is Approved**
- If you chose "Automatic Release": App goes live immediately
- If you chose "Manual Release": Click "Release This Version" when ready
- Your app will appear on the App Store within 24 hours
- Share your App Store link with the world!

### Important Notes

- **Review Time**: First submission typically takes 24-48 hours, sometimes up to a week
- **Rejections**: Don't panic - most apps get rejected on first submission. Fix issues and resubmit.
- **Updates**: For app updates, increment version/build numbers and repeat the process
- **App Store Guidelines**: Make sure your app follows [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Common Rejection Reasons**:
  - Missing privacy policy
  - App crashes or bugs
  - Incomplete functionality
  - Misleading descriptions
  - Missing required information

### Quick Checklist Before Submitting

- [ ] App tested and working properly
- [ ] Version and build numbers set
- [ ] Signing configured with paid developer account
- [ ] App created in App Store Connect
- [ ] Bundle ID registered
- [ ] Screenshots prepared and uploaded
- [ ] App description written
- [ ] Keywords entered
- [ ] Support URL provided
- [ ] Privacy policy URL provided (if needed)
- [ ] Age rating completed
- [ ] Contact information filled
- [ ] Build uploaded and processed
- [ ] Build selected in App Store Connect
- [ ] All required fields completed
- [ ] Ready to submit!

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect](https://appstoreconnect.apple.com)

