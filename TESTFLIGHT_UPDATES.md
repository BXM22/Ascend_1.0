# 🔄 How to Push Updates to TestFlight

This guide shows you how to update your TestFlight app with new builds.

## 📋 Quick Process

1. Update version/build numbers in Xcode
2. Archive the new build
3. Upload to App Store Connect
4. Add to testing groups (if needed)
5. Testers get the update automatically!

## 🚀 Step-by-Step: Push an Update

### Step 1: Update Version/Build Numbers

1. **Open Xcode:**
   - Open `Ascend.xcodeproj`

2. **Update Build Number:**
   - Select your project in navigator (blue "Ascend" icon)
   - Select **"Ascend"** target
   - Go to **"General"** tab
   - Find **"Version"** and **"Build"** fields
   
3. **Increment Build Number:**
   - **Version:** Keep as "1.0" (or increment to "1.1" for major updates)
   - **Build:** Increment by 1 (e.g., "1" → "2", "2" → "3")
   - **Important:** Build number must be unique and higher than previous

**Example:**
- Current: Version 1.0, Build 1
- Update: Version 1.0, Build 2 (or Version 1.1, Build 1)

### Step 2: Clean Build Folder

1. **In Xcode:**
   - **Product → Clean Build Folder** (or press **Shift + Cmd + K**)
   - This ensures a fresh build

### Step 3: Archive the New Build

1. **Select Device:**
   - At the top of Xcode, select **"Any iOS Device"** or **"Generic iOS Device"**
   - (Not a simulator - must be a device)

2. **Create Archive:**
   - **Product → Archive**
   - Wait for archive to complete (may take a few minutes)
   - Organizer window opens automatically

### Step 4: Upload to App Store Connect

1. **In Organizer:**
   - Select your new archive (should show the new build number)
   - Click **"Distribute App"**

2. **Distribution Options:**
   - Select **"App Store Connect"**
   - Click **"Next"**

3. **Upload Options:**
   - Choose **"Upload"**
   - Click **"Next"**

4. **Distribution Options:**
   - Leave defaults (usually fine)
   - Click **"Next"**

5. **Signing:**
   - Choose **"Automatically manage signing"** (recommended)
   - Select your paid Developer team
   - Click **"Next"**

6. **Review:**
   - Check the summary
   - Click **"Upload"**
   - Wait for upload to complete (may take several minutes)

### Step 5: Wait for Processing

1. **In App Store Connect:**
   - Go to **TestFlight** → **Builds** → **iOS**
   - You'll see your new build in **"Build Uploads"** section
   - Status: **"Processing"** (10-30 minutes typically)

2. **When Complete:**
   - Status changes to **"Complete"**
   - Build appears in your version list

### Step 6: Add Build to Testing Groups

#### For Internal Testing (No Review Needed):

1. **Click on the new build** (e.g., build "2")
2. **Go to "Test Information" tab**
3. **In "Groups" section:**
   - Click **"+"** next to Groups
   - Select **"INTERNAL TESTING"** group
   - Click **"Save"**
4. **Testers get update immediately!** ✅

#### For External Testing:

**If build is in same version (e.g., 1.0):**
- **No review needed!** ✅
- Just add to external group
- Testers get it automatically

**If new version (e.g., 1.1):**
- May need new Beta App Review
- Usually faster than first review

1. **Click on the new build**
2. **Go to "Test Information" tab**
3. **In "Groups" section:**
   - Click **"+"** next to Groups
   - Select your external group (e.g., "Ascend external test")
   - Click **"Save"**
4. **If review needed:**
   - Submit for review (usually faster than first time)
5. **Testers get update after approval**

## ⚡ Quick Update Workflow

```bash
# 1. Update build number in Xcode
# 2. Clean build (Shift + Cmd + K)
# 3. Archive (Product → Archive)
# 4. Upload (Distribute App → App Store Connect → Upload)
# 5. Wait for processing (10-30 min)
# 6. Add to testing groups
# 7. Testers get update!
```

## 📱 What Testers See

### Automatic Updates:

- **Internal Testers:** Get update immediately when you add build to group
- **External Testers:** Get update after approval (if needed)
- **TestFlight App:** Shows "Update Available" badge
- **They tap "Update"** and get the new version

### Update Notification:

- Testers may receive email notification
- TestFlight app shows update badge
- They can update anytime

## 🔄 Version vs Build Numbers

### Version Number:
- **Public version** (what users see)
- Examples: "1.0", "1.1", "2.0"
- Only change for major updates or App Store releases

### Build Number:
- **Internal build identifier**
- Must be unique and incrementing
- Examples: "1", "2", "3", "4"
- **Always increment** for each upload

### Best Practice:
- **Same version, increment build:** 1.0 (1) → 1.0 (2) → 1.0 (3)
- **New version, reset build:** 1.0 (5) → 1.1 (1) → 1.1 (2)

## ✅ Update Checklist

- [ ] Increment build number in Xcode
- [ ] Clean build folder
- [ ] Archive new build
- [ ] Upload to App Store Connect
- [ ] Wait for processing (10-30 min)
- [ ] Add build to INTERNAL TESTING group
- [ ] Add build to external group (if using)
- [ ] Testers receive update!

## 🎯 Common Scenarios

### Scenario 1: Quick Bug Fix
- **Version:** Keep 1.0
- **Build:** Increment (1 → 2)
- **Internal:** Add immediately (no review)
- **External:** Add immediately if same version

### Scenario 2: New Features
- **Version:** Increment to 1.1
- **Build:** Start at 1
- **Internal:** Add immediately
- **External:** May need quick review (usually faster)

### Scenario 3: Major Update
- **Version:** Increment to 2.0
- **Build:** Start at 1
- **Internal:** Add immediately
- **External:** May need review

## 🆘 Troubleshooting

### "Build number must be higher"
- **Fix:** Increment the build number
- Current build is "2", next must be "3" or higher

### "Build not showing in TestFlight"
- **Fix:** Wait longer - processing can take 30+ minutes
- Refresh the page
- Check "Build Uploads" section for status

### "Testers not getting update"
- **Fix:** Make sure build is added to their testing group
- Check build status is "Ready to Test"
- They may need to manually check TestFlight app

### "Can't add build to group"
- **Fix:** Wait for processing to complete
- Build must show "Ready to Test" status
- Check export compliance is answered

## 💡 Pro Tips

1. **Increment Build Every Time:**
   - Even for tiny fixes
   - Build number must always increase

2. **Internal Testing is Instant:**
   - No review needed
   - Perfect for quick iterations

3. **External Updates are Usually Fast:**
   - Same version = no review needed
   - New version = usually faster review than first time

4. **Test Before Uploading:**
   - Test the build on your device first
   - Make sure it works before sending to testers

5. **Version History:**
   - Keep track of what changed in each build
   - Helps testers know what to test

---

## 📝 Example Update Flow

**Current State:**
- Version: 1.0
- Build: 1
- In TestFlight

**You fix a bug:**

1. **Xcode:**
   - Version: 1.0 (keep same)
   - Build: 2 (increment)

2. **Archive & Upload:**
   - Product → Archive
   - Distribute → Upload

3. **Wait 15 minutes:**
   - Processing completes

4. **Add to Groups:**
   - Build 2 → INTERNAL TESTING ✅
   - Build 2 → External group ✅

5. **Testers:**
   - See "Update Available" in TestFlight
   - Tap "Update"
   - Get build 2 with bug fix!

---

**That's it!** Updates are straightforward - just increment build number, archive, upload, and add to groups. Testers get updates automatically! 🚀

