# Testing Guide

This document outlines how to test the Ascend Workout Tracker app.

## Manual Testing Checklist

### Workout Functionality Tests

#### 1. Workout Creation
- [ ] Start a new workout from scratch
- [ ] Start a workout from a template
- [ ] Verify workout timer starts automatically
- [ ] Verify exercise navigation works

#### 2. Exercise Management
- [ ] Add a new exercise to workout
- [ ] Complete a set with weight and reps
- [ ] Complete a hold exercise set
- [ ] Verify sets are tracked correctly
- [ ] Verify current set counter increments

#### 3. PR Detection
- [ ] Complete a set that beats existing PR → Should show PR badge
- [ ] Complete a set with lower weight → Should NOT add to PR list
- [ ] Complete a set with same weight, more reps → Should show PR badge
- [ ] Verify PR is only added when it's actually a new record

#### 4. Rest Timer
- [ ] Verify rest timer starts after completing a set
- [ ] Verify rest timer counts down correctly
- [ ] Test skip rest functionality
- [ ] Test complete rest functionality
- [ ] Verify rest timer uses settings duration

#### 5. Workout Control
- [ ] Pause workout → Timer should stop
- [ ] Finish workout → Should reset and save workout date
- [ ] Verify workout date is added to progress tracking

### Alternative Exercises & Video Features

#### 6. Alternative Exercises
- [ ] View alternative exercises for Bench Press
- [ ] View alternative exercises for Squat
- [ ] Switch to an alternative exercise
- [ ] Verify sets are preserved when switching
- [ ] Verify empty state shows when no alternatives exist

#### 7. Video Tutorials
- [ ] Click "Watch Tutorial" button for exercise with video
- [ ] Verify YouTube video opens in Safari
- [ ] Verify button doesn't show for exercises without video
- [ ] Test with various exercise types

### Progress Tracking Tests

#### 8. Progress View
- [ ] View workout streak (current and longest)
- [ ] View PR tracker with exercise selection
- [ ] Switch between Week and Month views
- [ ] Verify PR history displays correctly
- [ ] Verify stats grid shows correct data

#### 9. Dashboard
- [ ] View dashboard with all stat cards
- [ ] Verify quick stats display correctly
- [ ] View recent PRs
- [ ] View top exercises
- [ ] Verify weekly summary calculations

### UI/UX Tests

#### 10. Navigation
- [ ] Navigate between all tabs (Dashboard, Workout, Progress, Templates)
- [ ] Verify tab selection highlights correctly
- [ ] Test theme picker toggle
- [ ] Verify theme switching works

#### 11. Dark Mode
- [ ] Test all screens in dark mode
- [ ] Verify icons are visible in dark mode
- [ ] Verify dropdown menus are readable
- [ ] Verify text contrast is adequate

#### 12. Design System
- [ ] Verify consistent spacing throughout app
- [ ] Verify typography is consistent
- [ ] Verify colors match design system
- [ ] Verify card shadows and borders

### Edge Cases

#### 13. Error Handling
- [ ] Add exercise with empty name → Should be disabled
- [ ] Complete set with invalid weight/reps → Should handle gracefully
- [ ] Test with no internet (for video links)
- [ ] Test with invalid YouTube URL

#### 14. Data Persistence
- [ ] Verify workout data persists during session
- [ ] Verify PRs are maintained
- [ ] Verify settings are saved

## Automated Testing Setup

To set up automated tests in Xcode:

1. Create a new Test Target:
   - File → New → Target
   - Choose "iOS Unit Testing Bundle"
   - Name it "AscendTests"

2. Add test files to the test target:
   - Create test files in the test target
   - Import the main app module: `@testable import Ascend`

3. Example test structure:

```swift
import XCTest
@testable import Ascend

class WorkoutViewModelTests: XCTestCase {
    var viewModel: WorkoutViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = WorkoutViewModel()
    }
    
    func testStartWorkout() {
        viewModel.startWorkout(name: "Test")
        XCTAssertNotNil(viewModel.currentWorkout)
    }
}
```

## Test Data

### Sample Exercises for Testing
- Bench Press (has alternatives: Push-ups, Dumbbell Press)
- Squat (has alternatives: Bodyweight Squat, Jump Squats)
- Deadlift (has alternatives: Romanian Deadlift, Good Mornings)
- Plank (hold exercise, has alternatives: Side Plank, Mountain Climbers)

### Sample PRs for Testing
- Bench Press: 200 lbs × 5 reps
- Squat: 275 lbs × 3 reps
- Deadlift: 315 lbs × 1 rep

## Performance Testing

- [ ] Test app performance with 100+ PRs
- [ ] Test workout timer accuracy
- [ ] Test rest timer accuracy
- [ ] Verify smooth scrolling in lists
- [ ] Test app launch time

## Accessibility Testing

- [ ] Test with VoiceOver enabled
- [ ] Verify all buttons are accessible
- [ ] Test Dynamic Type support
- [ ] Verify color contrast meets WCAG standards


