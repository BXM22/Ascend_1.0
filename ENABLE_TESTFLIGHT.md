# 🚀 Enable Build for TestFlight External Testing

Your build has been uploaded! Now let's get it on TestFlight for your friends and family.

## ⏰ Step 1: Wait for Processing

1. **Go to App Store Connect:**
   - https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account
   - Click on your app **"Ascend"**

2. **Check Build Status:**
   - Click **"TestFlight"** tab (left sidebar)
   - Go to **"Builds"** → **"iOS"**
   - You should see your build (Version 1.0.1, Build 2)
   - Status will show: **"Processing"** (orange/yellow)

3. **Wait:**
   - Usually takes **10-30 minutes**
   - Sometimes up to 1 hour
   - You'll get an email when it's ready

4. **When Ready:**
   - Status changes to **"Ready to Test"** (green) ✅

## 📋 Step 2: Answer Export Compliance (If Prompted)

When the build finishes processing, you may see a warning:

1. **Click on the build** (version 1.0.1, build 2)

2. **Answer Export Compliance Questions:**
   - **"Does your app use encryption?"**
     - Usually select **"No"** (unless you use custom encryption)
     - HTTPS/SSL is "standard encryption" and doesn't count
   - **"Does your app use standard encryption?"**
     - Usually select **"Yes"** (if you use HTTPS/SSL)
   - Click **"Save"**

## 👥 Step 3: Create External Testing Group (If Not Already Created)

1. **In TestFlight tab:**
   - Click **"Testers"** in left sidebar
   - Look for an external testing group

2. **If you don't have one:**
   - Click **"+"** button (top right)
   - Name: "External Testers" or "Friends & Family"
   - Description: (Optional) "External beta testers"
   - Click **"Create"**

## 🎯 Step 4: Add Build to External Testing Group

1. **Go to Builds:**
   - **TestFlight** tab → **"Builds"** → **"iOS"**
   - Click on your build (version 1.0.1, build 2)

2. **Enable for External Testing:**
   - Click **"Test Information"** tab
   - Scroll down to **"Groups"** section
   - Click **"+"** next to Groups
   - Select your **external testing group** (e.g., "External Testers")
   - Click **"Save"**

## 📝 Step 5: Submit for Beta App Review

**Important:** External testing requires Beta App Review (one-time per build).

1. **After adding build to group:**
   - You'll see a message about Beta App Review
   - Click **"Submit for Review"** or **"Start Beta App Review"**

2. **Fill Out Review Information:**
   - **"What to Test"** - Describe what testers should focus on:
     ```
     Please test the following features:
     - Creating and starting workouts
     - Adding exercises and logging sets/reps/weight
     - Tracking progress and viewing personal records (PRs)
     - Using workout templates and custom programs
     - Rest timer functionality
     - Custom exercise creation
     - Dashboard statistics and progress charts
     
     Please report any bugs, crashes, or issues you encounter. 
     Thank you for testing Ascend!
     ```
   
   - **"Contact Information"** - Your email (usually pre-filled)
   - **"Demo Account"** - Only if your app requires login (leave blank)
   - **"Notes"** - Any additional info (optional)

3. **Submit:**
   - Click **"Submit for Review"**
   - Status will change to **"In Review"**
   - ⏰ Review typically takes **24-48 hours** (one-time)

## ⏳ Step 6: Wait for Beta App Review Approval

1. **Check Status:**
   - Go to **TestFlight** → **Builds** → Click your build
   - Status will show:
     - **"In Review"** - Being reviewed by Apple
     - **"Ready to Test"** - Approved! ✅
     - **"Rejected"** - Need to fix issues (rare)

2. **You'll Receive Email:**
   - Apple will email you when the review is complete
   - Usually within 24-48 hours

## 👥 Step 7: Add Testers (After Approval)

Once the build is approved:

1. **Go to Testers:**
   - **TestFlight** tab → **"Testers"** in left sidebar
   - Click on your external group (e.g., "External Testers")

2. **Add Testers:**
   - Click **"+"** button (top right)
   - **Add by email:**
     - Enter email addresses (one per line or comma-separated)
     - Example:
       ```
       friend1@email.com
       friend2@email.com
       family@email.com
       ```
   - Click **"Add"** or **"Invite"**

3. **Testers Receive Invitation:**
   - They'll get an email with TestFlight link
   - They click the link
   - Opens TestFlight app (or App Store to download TestFlight)
   - They can install your app!

## 🔗 Step 8: Share Public Link (Alternative)

After approval, you can also share a public link:

1. **In your external group:**
   - Look for **"Public Link"** or **"Share Link"** option
   - Enable it if available
   - Copy the link
   - Share with friends/family

2. **They can:**
   - Click the link
   - Install TestFlight app (if needed)
   - Install your app directly

## ✅ Quick Checklist

- [ ] Build uploaded to App Store Connect ✅
- [ ] Wait for processing (10-30 minutes)
- [ ] Answer export compliance questions (if prompted)
- [ ] Create external testing group (if needed)
- [ ] Add build to external group
- [ ] Submit for Beta App Review
- [ ] Wait for approval (24-48 hours)
- [ ] Add testers by email
- [ ] Share TestFlight link (optional)

## 📱 What Testers Need to Do

1. **Install TestFlight:**
   - Download TestFlight app from App Store (free)

2. **Accept Invitation:**
   - Click the link in the email they receive
   - Or open TestFlight app and accept invitation

3. **Install App:**
   - Tap "Install" in TestFlight
   - App installs like a normal app

4. **Test:**
   - Use the app normally
   - Report feedback through TestFlight if needed

## 🔄 For Future Builds

Once your first build is approved for external testing:
- ✅ **New builds** in the same version (1.0.1) can be added immediately
- ✅ **No review needed** for subsequent builds in the same version
- ✅ Just upload new build, add to group, and testers get it automatically

## ⏰ Timeline Summary

- **Upload:** ✅ Done!
- **Processing:** 10-30 minutes
- **Beta App Review:** 24-48 hours (one-time)
- **After Approval:** Testers can be added instantly

---

**You're almost there!** Just wait for processing, then enable it for external testing. Good luck! 🎉

