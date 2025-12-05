# 👥 Add Friends & Family to TestFlight (External Testing)

Now that you have it working for yourself, here's how to add friends and family as external testers.

## 🎯 External Testing Overview

**External Testing:**
- ✅ Up to 10,000 testers
- ✅ Anyone with an email can test
- ✅ Testers don't need to be in your App Store Connect team
- ⏳ Requires Beta App Review (24-48 hours, one-time)
- ✅ Perfect for friends, family, and beta testers

## 📋 Step-by-Step Setup

### Step 1: Create an External Testing Group

1. **In App Store Connect:**
   - Go to your app → **TestFlight** tab
   - In the left sidebar, click **"Testers"**
   - You should see **"INTERNAL TESTING"** (what you're using now)
   - Click the **"+"** button (top right) or look for **"Create Group"**

2. **Create New Group:**
   - Name: "Friends & Family" or "Beta Testers"
   - Click **"Create"**

### Step 2: Add the Build to the Group

1. **Go to Builds:**
   - Click **"Builds"** → **"iOS"** in left sidebar
   - Click on build **"1"** (your current build)

2. **Enable for External Testing:**
   - Go to **"Test Information"** tab
   - Scroll to **"Groups"** section
   - Click **"+"** next to Groups
   - **Select your new external group** (e.g., "Friends & Family")
   - Click **"Save"**

### Step 3: Submit for Beta App Review

1. **After adding the build to the group:**
   - You'll see a message about Beta App Review
   - Click **"Submit for Review"** or **"Start Beta App Review"**

2. **Fill Out Review Information:**
   - **What to Test:** Describe what testers should focus on
     - Example: "Please test the core workout tracking features, exercise logging, and progress tracking. Report any bugs or issues you encounter."
   - **Contact Information:** Your email (usually pre-filled)
   - **Demo Account (if needed):** Only if your app requires login
   - **Notes:** Any additional info for reviewers

3. **Submit:**
   - Click **"Submit for Review"**
   - Review typically takes **24-48 hours**

### Step 4: Wait for Approval

1. **Check Status:**
   - Go to **TestFlight** → **Builds** → Click build "1"
   - Status will show:
     - **"In Review"** - Being reviewed
     - **"Ready to Test"** - Approved! ✅
     - **"Rejected"** - Need to fix issues (rare)

2. **You'll get an email** when approved

### Step 5: Add Testers (After Approval)

Once the build is approved:

1. **Go to Testers:**
   - **TestFlight** tab → **"Testers"** in left sidebar
   - Click on your external group (e.g., "Friends & Family")

2. **Add Testers:**
   - Click **"+"** button
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

## 🎁 Share TestFlight Link (Alternative Method)

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

## ⚡ Quick Summary

1. ✅ Create external testing group
2. ✅ Add build to the group
3. ⏳ Submit for Beta App Review (24-48 hour wait)
4. ✅ Once approved, add testers by email
5. 🎉 They receive invitation and can test!

## 📝 What to Write for "What to Test"

**Example for Ascend:**
```
Please test the following features:
- Creating and starting workouts
- Adding exercises and logging sets/reps
- Tracking progress and viewing PRs
- Using workout templates
- Rest timer functionality
- Custom exercise creation

Please report any bugs, crashes, or issues you encounter. Thank you for testing!
```

## ⏰ Timeline

- **Beta App Review:** 24-48 hours (one-time per build)
- **After Approval:** Testers can be added instantly
- **Invitation Email:** Sent immediately when you add testers
- **Tester Setup:** Takes 2-3 minutes for them to install

## 🔄 For Future Builds

Once your first build is approved for external testing:
- **New builds** in the same version can be added to the group immediately
- **No review needed** for subsequent builds in the same version
- Just add the new build to the group and testers get it automatically

## 🆘 Common Issues

### "Build Not Available for External Testing"
- Make sure you submitted for Beta App Review
- Wait for approval (24-48 hours)

### "Testers Not Receiving Email"
- Check spam folder
- Verify email addresses are correct
- They can also check TestFlight app directly

### "Can't Add Build to Group"
- Make sure the build is processed (shows "Ready to Test")
- You may need to submit for review first

---

**The key difference:**
- **Internal Testing** = No review, but testers must be in your team (up to 100)
- **External Testing** = Requires review, but anyone can test (up to 10,000)

For friends and family, **external testing** is the way to go!

