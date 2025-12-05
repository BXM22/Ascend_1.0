# Ascend - SwiftUI iOS App



## Features

- 💪 **Workout Tracking**: Track exercises, sets, weight, and reps
- ⏱️ **Rest Timer**: Circular progress timer for rest periods
- 🏆 **PR Detection**: Automatic personal record detection and celebration
- 📊 **Progress Charts**: Visualize strength and volume progress over time
- 📋 **Workout Templates**: Pre-defined workout templates (Push, Pull, Leg Day)
- 🎨 **Beautiful UI**: Modern design with your custom color palette

## Color Palette

- **Ink Black**: `#0d1b2a` - Primary text
- **Prussian Blue**: `#1b263b` - Primary buttons and accents
- **Dusk Blue**: `#415a77` - Secondary accents
- **Dusty Denim**: `#778da9` - Borders and muted elements
- **Alabaster Grey**: `#e0e1dd` - Background

## Project Structure

```
WorkoutTracker/
├── WorkoutTrackerApp.swift      # App entry point
├── Models/
│   └── Models.swift             # Data models (Exercise, Set, PR, Template, etc.)
├── ViewModels/
│   ├── WorkoutViewModel.swift   # Workout state management
│   ├── ProgressViewModel.swift  # Progress tracking
│   └── TemplatesViewModel.swift # Template management
├── Views/
│   ├── ContentView.swift        # Main container with tab navigation
│   ├── WorkoutView.swift        # Workout screen
│   ├── ProgressView.swift       # Progress/charts screen
│   ├── TemplatesView.swift      # Templates screen
│   └── Components/
│       ├── RestTimerView.swift  # Rest timer component
│       └── PreviousSetsView.swift # Previous sets list
└── Theme/
    └── AppColors.swift          # Color theme and gradients
```

## Setup Instructions

### Option 1: Create Xcode Project

1. Open Xcode
2. Create a new iOS App project
3. Choose SwiftUI as the interface
4. Copy all files from this directory into your Xcode project
5. Make sure to organize files into the folders shown above
6. Build and run!

### Option 2: Use Swift Package Manager

If you prefer to use this as a package or integrate into an existing project:

1. Ensure all files are in the correct directory structure
2. Add the files to your Xcode project
3. Build and run

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Key Features Implementation

### Workout Tracking
- Real-time workout timer
- Exercise set tracking with weight and reps
- Automatic progression through sets
- Previous sets display

### Rest Timer
- 90-second default rest timer
- Circular progress indicator
- Skip and complete options
- Automatic completion

### PR Detection
- Compares current set to previous sets at same weight
- Shows PR badge with celebration message
- Auto-dismisses after 3 seconds

### Progress Charts
- Uses Swift Charts framework
- Line chart for strength progress (Bench, Squat, Deadlift)
- Bar chart for volume progress
- Week/Month view toggle

### Templates
- Pre-defined workout templates
- Start workout from template
- Edit template functionality

## Customization

### Colors
Edit `Theme/AppColors.swift` to change the color scheme.

### Default Values
Edit the ViewModels to change default exercise names, set counts, rest timer duration, etc.

### Charts
Modify `ProgressView.swift` to customize chart appearance and data.

## Future Enhancements

- [ ] Core Data persistence
- [ ] CloudKit sync
- [ ] Apple Watch companion app
- [ ] Workout history
- [ ] Exercise library
- [ ] Custom rest timer durations
- [ ] Export workout data
- [ ] Social sharing

## Notes

- Currently uses sample/mock data for progress charts
- Workout data is stored in memory (not persisted)
- To add persistence, integrate Core Data or SwiftData

## License

Free to use and modify for personal projects.

