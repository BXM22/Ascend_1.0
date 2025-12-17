# Fix: Missing Bundle Executable Error

## Problem
The app bundle is missing its main executable (`Ascend`), causing installation to fail with error code 3000/3002.

## Root Cause
The Sources build phase is empty, meaning Swift files aren't being compiled. This is a known issue with Xcode's file system synchronization when using `fileSystemSynchronizedGroups`.

## Solution

### Option 1: Re-sync Files in Xcode (Recommended)
1. **Close Xcode completely**
2. **Delete DerivedData:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Ascend-*
   ```
3. **Reopen Xcode**
4. **Wait for file system synchronization** - Xcode will automatically detect and add Swift files
5. **Build the project** (⌘+B)
6. **Verify the executable exists:**
   ```bash
   ls -lh DerivedData/Ascend/Build/Products/Debug-iphoneos/Ascend.app/Ascend
   ```

### Option 2: Manual File Addition (If Option 1 doesn't work)
1. In Xcode, select the **Ascend** target
2. Go to **Build Phases** → **Compile Sources**
3. Click the **+** button
4. Add all Swift files from the `Ascend` folder
5. Build again

### Option 3: Verify Build Settings
Ensure these settings are correct:
- `PRODUCT_NAME = Ascend`
- `EXECUTABLE_NAME = Ascend`
- `INFOPLIST_KEY_CFBundleExecutable = $(PRODUCT_NAME)`

## Verification
After fixing, verify the executable exists:
```bash
file DerivedData/Ascend/Build/Products/Debug-iphoneos/Ascend.app/Ascend
```

Should show: `Ascend: Mach-O universal binary with 2 architectures: [arm64]`

