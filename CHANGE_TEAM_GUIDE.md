# 🔄 How to Change Team to Paid Developer Account

This guide shows you how to switch from your free "Personal Team" to your paid Apple Developer Program team.

## ✅ Step-by-Step Instructions

### Step 1: Add Your Paid Developer Account to Xcode

1. **Open Xcode**
2. **Go to Xcode Settings:**
   - **Xcode → Settings** (or **Preferences** on older versions)
   - Click the **Accounts** tab
3. **Add Your Paid Account:**
   - Click the **+** button (bottom left)
   - Select **Apple ID**
   - Sign in with the **same Apple ID** you used to purchase the Developer Program membership
   - Your account should now show with your **organization name** (not "Personal Team")
   - You should see something like: **"Your Name (Your Company Name)"** or **"Your Company Name"**

### Step 2: Change Team in Project Settings

1. **Open Your Project:**
   - Open `Ascend.xcodeproj` in Xcode

2. **Select Project in Navigator:**
   - In the left sidebar, click the blue **"Ascend"** icon at the top (the project root)

3. **Select the Target:**
   - In the main editor, under **TARGETS**, click **"Ascend"** (the app target)

4. **Go to Signing & Capabilities:**
   - Click the **"Signing & Capabilities"** tab at the top

5. **Change the Team:**
   - Make sure **"Automatically manage signing"** is checked ✅
   - Click the **Team** dropdown menu
   - You should now see:
     - Your old "Personal Team" (free account)
     - Your new **paid Developer Program team** (shows your organization name)
   - **Select your paid Developer Program team** (the one with your organization name, NOT "Personal Team")

6. **Verify the Change:**
   - After selecting, you should see:
     - ✅ Team: **"Your Name (Your Company Name)"** or **"Your Company Name"**
     - ✅ Bundle Identifier: `com.app.com.Ascend`
     - ✅ Signing Certificate: "Apple Distribution" (for Release) or "Apple Development" (for Debug)
     - ✅ Provisioning Profile: "Xcode Managed Profile"
   - **Important:** The team name should **NOT** say "Personal Team"

### Step 3: Verify Both Build Configurations

Make sure the team is set for **both** Debug and Release:

1. **Check Debug Configuration:**
   - In Signing & Capabilities, look for any dropdown that says "Debug" or "Release"
   - Or go to **Build Settings** tab
   - Search for "Development Team"
   - Make sure both Debug and Release show your paid team

2. **If You See Multiple Configurations:**
   - Some projects have Debug, Release, and others
   - Make sure **all** of them use your paid team
   - You can change them individually if needed

### Step 4: Clean and Rebuild

1. **Clean Build Folder:**
   - **Product → Clean Build Folder** (or press **Shift + Cmd + K**)

2. **Verify It Works:**
   - Try building the project: **Product → Build** (or **Cmd + B**)
   - You should see no errors related to signing or team

## 🔍 How to Tell If You're Using the Right Team

### ✅ Correct (Paid Team):
- Team name shows your **organization/company name**
- Team name does **NOT** say "Personal Team"
- You can create archives for App Store distribution
- You can upload to TestFlight

### ❌ Wrong (Free/Personal Team):
- Team name says **"Personal Team"**
- Team name shows just your name with "(Personal Team)"
- You'll get errors when trying to archive for App Store
- TestFlight uploads will fail

## 🚨 Common Issues & Solutions

### Issue: "I don't see my paid team in the dropdown"

**Solutions:**
1. **Make sure you added the account correctly:**
   - Go to Xcode → Settings → Accounts
   - Verify your paid account is listed
   - If it shows "Personal Team", you might be using the wrong Apple ID

2. **Check your Apple Developer account:**
   - Go to https://developer.apple.com/account
   - Make sure your membership is active
   - Make sure you're signed in with the correct Apple ID

3. **Refresh accounts in Xcode:**
   - Xcode → Settings → Accounts
   - Select your account
   - Click **"Download Manual Profiles"** button
   - Close and reopen Xcode

### Issue: "No accounts with App Store Connect access"

**Solution:**
- This usually means you're still using Personal Team
- Make sure you selected the **paid Developer Program team** (not Personal Team)
- The paid team should show your organization name

### Issue: "Failed to create provisioning profile"

**Solutions:**
1. Make sure "Automatically manage signing" is checked
2. Make sure you selected the correct paid team
3. Try cleaning the build folder (Shift + Cmd + K)
4. Try restarting Xcode

### Issue: "Team changed but still can't upload to TestFlight"

**Solutions:**
1. Make sure you're using the **Release** configuration when archiving
2. Clean build folder and rebuild
3. Make sure the bundle ID matches what's in App Store Connect
4. Verify your paid membership is active

## 📝 Quick Checklist

- [ ] Added paid Developer account to Xcode (Settings → Accounts)
- [ ] Selected paid team in Signing & Capabilities (NOT "Personal Team")
- [ ] Verified both Debug and Release use paid team
- [ ] Cleaned build folder
- [ ] Team name shows organization name (not "Personal Team")
- [ ] Can create archive successfully
- [ ] Can upload to TestFlight/App Store Connect

## 💡 Pro Tips

1. **Team ID:** Your paid team will have a Team ID (like `ZNNWAD9F59`). You can see this in:
   - Xcode → Settings → Accounts → Select your team → Team ID
   - Or in App Store Connect → Users and Access → Team ID

2. **Multiple Teams:** If you're part of multiple developer teams, make sure you select the one with the **active paid membership**

3. **Bundle ID:** Make sure your bundle ID (`com.app.com.Ascend`) is registered under your paid team in App Store Connect

4. **Automatic Signing:** Always use "Automatically manage signing" - it's much easier than manual signing

---

## ✅ Verification

After changing teams, verify everything works:

1. **Try to Archive:**
   - Product → Archive
   - Should work without errors about team or signing

2. **Check Team in Archive:**
   - In the Organizer (Window → Organizer)
   - Select your archive
   - Check the team name - should be your paid team

3. **Try Upload:**
   - Distribute App → App Store Connect
   - Should work without "Personal Team" errors

---

**That's it!** Once you've changed to your paid team, you can upload to TestFlight and submit to the App Store.

