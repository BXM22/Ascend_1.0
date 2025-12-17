# Legacy: How to Add CSV File to App Bundle

> **Note:** The app now ships with a curated JSON exercise dataset (`exercises.json`) that is loaded automatically by `ExRxDirectoryManager`. CSV import is optional and intended only for advanced users or development tooling.

## Step 1: Add CSV File to Xcode Project (Optional)

1. **Open your Xcode project**
2. **Right-click on the `Ascend` folder** in the Project Navigator (left sidebar)
3. **Select "Add Files to 'Ascend'..."**
4. **Navigate to your CSV file:**
   - File: `Gym Exercise Dataset export 2025-12-16 07-12-04.csv`
   - Location: `/Users/brennenmeregillano/Downloads/`
5. **IMPORTANT: Check these options:**
   - ✅ **"Copy items if needed"** - This copies the file into your project
   - ✅ **"Add to targets: Ascend"** - This includes it in the app bundle
6. **Click "Add"**

## Step 2: Verify File is in Bundle

1. **Select the CSV file** in Xcode's Project Navigator
2. **Open the File Inspector** (right sidebar, first tab)
3. **Check "Target Membership":**
   - ✅ Make sure **"Ascend"** is checked
   - This ensures the file is included when building the app

## Step 3: Alternative - Rename File (Optional)

If you want to use a simpler name:

1. **Rename the file** in Xcode to: `exercises.csv`
2. The code will automatically find it with this name

## Step 4: Build and Test (Optional)

1. **Build the app** (Cmd+B)
2. **Run the app** (Cmd+R)
3. **Check the console logs** - You should see:
   - `📚 Found CSV in app bundle`
   - `✅ CSV import successful: ...`

## How It Worked (Legacy Path)

Historically, the app would:
1. Look for the CSV file in the app bundle first (production)
2. Fall back to Downloads folder (development only)
3. Import exercises on first launch if not already imported
4. Store imported exercises in UserDefaults (persistent)

In the current version, exercise data comes from the bundled JSON file instead, so you generally do **not** need to add or manage a CSV file unless you have a very specific migration workflow.

## Troubleshooting

**If CSV is not found:**
- Verify the file is in the Xcode project (visible in Project Navigator)
- Check Target Membership includes "Ascend"
- Try cleaning build folder (Cmd+Shift+K) and rebuilding
- Check console logs for the exact error message

**If import fails:**
- Check CSV file format matches expected structure
- Verify file encoding is UTF-8
- Check console logs for specific error details


