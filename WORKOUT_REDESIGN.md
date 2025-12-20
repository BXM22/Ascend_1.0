# Workout View Redesign - Implementation Plan

## Overview
Comprehensive UI/UX overhaul of the Workout View in the Ascend iOS workout app, focusing on simplification, visual clarity, and reduced cognitive load while preserving all advanced features. This redesign addresses the current complexity through progressive disclosure, improved visual hierarchy, and streamlined interactions.

## Design Philosophy

Following the **Templates View redesign** approach:
- ✅ **Progressive disclosure** (advanced features hidden until needed)
- ✅ **Simplified visual hierarchy** (focus on active exercise)
- ✅ **Consolidated controls** (reduce button clutter)
- ✅ **Smart defaults** (intelligent suggestions, auto-fill)
- ✅ **Contextual actions** (right action at right time)
- ✅ **Swipe gestures** (quick operations without menus)
- ✅ **Enhanced feedback** (clearer PR celebrations, better rest timer)

---

## Current State Analysis

### **Existing Features**
- Multi-exercise workout tracking (weight/reps, calisthenics, cardio, stretching)
- Set completion with weight/rep input
- Rest timer with circular progress and breathing animation
- PR detection with celebration (badge, confetti, haptics)
- Dropset support (configurable number and weight reduction)
- Smart suggestions (weight/rep recommendations from history)
- Plate calculator (bar loading breakdown)
- Alternative exercises (ExRx integration)
- Warm-up set generation and tracking
- Auto-advance to next exercise
- Exercise segmentation (Warmup/Main/Cardio)
- Workout timer (elapsed time)
- Background persistence
- Undo last set (5-second window)
- Template-based or manual workouts
- Completion modal with stats

### **Current Layout**
1. **Header**: Workout name, volume, time, auto-advance toggle, settings, pause, finish
2. **Rest Timer Zone**: RestTimerView (active) or minimal ready indicator
3. **Workout Timer Bar**: Large time display with reset button
4. **Segmented Navigation**: Warmup/Exercises/Cardio tabs + horizontal exercise chips
5. **Active Exercise Card**: Large card with inputs, suggestions, dropsets, alternatives
6. **Previous Sets**: Grouped display of completed sets
7. **Add Exercise Button**: Bottom button

### **Pain Points Identified**
- 🔴 **Visual complexity**: 7+ buttons in header, multiple disclosure groups
- 🔴 **Information density**: Exercise cards have too many nested sections
- 🔴 **Cognitive load**: Multiple timers, segments, state transitions to track
- 🔴 **Card collapse logic**: Confusing when cards collapse/expand during rest
- 🔴 **Small touch targets**: Exercise chips, preset buttons can be hard to tap
- 🔴 **Accessibility gaps**: Limited VoiceOver support, contrast issues
- 🔴 **PR badge visibility**: Multiple conditions for display, can be missed
- 🔴 **Horizontal scrolling**: Exercise chips require scrolling, may hide exercises

---

## Redesign Strategy

### **PHASE 1: Header Simplification**

**Before:**
```
[Workout Name] [Volume] [Time]
[Auto-advance] [Help] [Settings] [Pause] [Finish]
```

**After:**
```swift
VStack(spacing: 8) {
    // Top row: Name + overflow menu
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(workoutName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            HStack(spacing: 12) {
                // Volume badge
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 12))
                    Text(formatVolume(totalVolume))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppColors.mutedForeground)
                
                // Exercise count
                HStack(spacing: 4) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 12))
                    Text("\(completedExercises)/\(totalExercises)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppColors.mutedForeground)
            }
        }
        
        Spacer()
        
        // Consolidated menu
        Menu {
            Section {
                Button(action: { autoAdvanceEnabled.toggle() }) {
                    Label(
                        "Auto-advance",
                        systemImage: autoAdvanceEnabled ? "checkmark" : ""
                    )
                }
                
                Button(action: { showWorkoutSettings = true }) {
                    Label("Settings", systemImage: "gear")
                }
                
                Button(action: { showHelp = true }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
            }
            
            Section {
                Button(role: .destructive, action: cancelWorkout) {
                    Label("Cancel Workout", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // Bottom row: Timer + action buttons
    HStack(spacing: 12) {
        // Elapsed time
        HStack(spacing: 6) {
            Image(systemName: timerPaused ? "pause.circle.fill" : "clock.fill")
                .font(.system(size: 16))
                .foregroundStyle(timerPaused ? AppColors.accent : LinearGradient.primaryGradient)
            
            Text(formatElapsedTime(elapsedTime))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(timerPaused ? AppColors.accent : LinearGradient.primaryGradient)
        }
        
        Spacer()
        
        // Pause/Resume button
        Button(action: togglePause) {
            Image(systemName: timerPaused ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient.primaryGradient)
        }
        
        // Finish button
        Button(action: finishWorkout) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                Text("Finish")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(LinearGradient.primaryGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
.padding(.horizontal, 20)
.padding(.vertical, 12)
.background(AppColors.background)
```

**Benefits:**
- Reduced from 7 buttons → 2 buttons + 1 menu
- Clearer visual hierarchy (name → metadata → actions)
- More breathing room, less visual noise
- Timer more prominent, easier to glance

---

### **PHASE 2: Exercise Navigation Redesign**

**Current Issue:** Horizontal scrolling chips can hide exercises, segment control unclear

**Proposed Solution:**

```swift
VStack(spacing: 0) {
    // Exercise progress indicator
    HStack(spacing: 8) {
        ForEach(sortedExercises.indices, id: \.self) { index in
            let exercise = sortedExercises[index]
            let isActive = index == currentExerciseIndex
            let isCompleted = exercise.sets.count >= exercise.targetSets
            
            Circle()
                .fill(isCompleted ? AppColors.success : (isActive ? LinearGradient.primaryGradient : AppColors.muted))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(AppColors.border, lineWidth: isActive ? 2 : 0)
                )
                .onTapGesture {
                    withAnimation(.smooth) {
                        currentExerciseIndex = index
                    }
                }
        }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(AppColors.card)
    
    // Current exercise name + navigation
    HStack {
        Button(action: previousExercise) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(hasPreviousExercise ? AppColors.textPrimary : AppColors.muted)
        }
        .disabled(!hasPreviousExercise)
        
        VStack(spacing: 4) {
            Text(currentExercise.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Exercise \(currentExerciseIndex + 1) of \(sortedExercises.count)")
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        
        Button(action: nextExercise) {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(hasNextExercise ? AppColors.textPrimary : AppColors.muted)
        }
        .disabled(!hasNextExercise)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(AppColors.card)
}
```

**Benefits:**
- **Dot navigation**: Shows all exercises at glance, tap to jump
- **Swipe navigation**: Left/right arrows for linear progression
- **Progress indication**: Completed exercises shown in green
- **No horizontal scrolling**: All exercises visible in dot row
- **Clearer position**: "Exercise X of Y" always visible

---

### **PHASE 3: Simplified Exercise Card**

**Current Issue:** Too many disclosure groups, nested sections, visual clutter

**Proposed Redesign:**

```swift
struct SimplifiedExerciseCard: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let exerciseIndex: Int
    
    var exercise: Exercise {
        viewModel.currentWorkout!.exercises[exerciseIndex]
    }
    
    var isActive: Bool {
        exerciseIndex == viewModel.currentExerciseIndex
    }
    
    @State private var showHistory = false
    @State private var showAlternatives = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            HStack {
                // Set progress
                Text("Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(categoryGradient)
                
                Spacer()
                
                // Quick actions menu
                Menu {
                    Button(action: { showHistory = true }) {
                        Label("View History", systemImage: "chart.bar")
                    }
                    
                    Button(action: { showAlternatives = true }) {
                        Label("Alternatives", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button(action: toggleFavorite) {
                        Label(
                            isFavorite ? "Remove Favorite" : "Add Favorite",
                            systemImage: isFavorite ? "star.fill" : "star"
                        )
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: deleteExercise) {
                        Label("Delete Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            if isActive && !viewModel.restTimerActive {
                // Main input area (only when active and not resting)
                VStack(spacing: 24) {
                    // Weight & Reps inputs (side by side)
                    HStack(spacing: 20) {
                        // Weight
                        VStack(spacing: 8) {
                            Text("Weight")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            HStack(spacing: 12) {
                                Button(action: { decrementWeight() }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(categoryGradient)
                                }
                                
                                Text("\(Int(currentWeight))")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(minWidth: 80)
                                    .contentTransition(.numericText())
                                
                                Button(action: { incrementWeight() }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(categoryGradient)
                                }
                            }
                            
                            Text("lbs")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mutedForeground)
                        }
                        
                        Divider()
                            .frame(height: 100)
                        
                        // Reps
                        VStack(spacing: 8) {
                            Text("Reps")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                            
                            HStack(spacing: 12) {
                                Button(action: { decrementReps() }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(categoryGradient)
                                }
                                
                                Text("\(currentReps)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(minWidth: 80)
                                    .contentTransition(.numericText())
                                
                                Button(action: { incrementReps() }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(categoryGradient)
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick preset buttons (reps only)
                    HStack(spacing: 8) {
                        ForEach([5, 8, 10, 12, 15], id: \.self) { preset in
                            Button(action: { currentReps = preset }) {
                                Text("\(preset)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(currentReps == preset ? .white : AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(currentReps == preset ? categoryGradient : LinearGradient(colors: [AppColors.muted], startPoint: .top, endPoint: .bottom))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Smart suggestion (if available)
                    if let suggestion = getSuggestion() {
                        Button(action: { applySuggestion(suggestion) }) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 14))
                                Text("Try \(Int(suggestion.weight)) lbs × \(suggestion.reps)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    // Advanced features (collapsible)
                    DisclosureGroup(
                        isExpanded: $showAdvanced,
                        content: {
                            VStack(spacing: 16) {
                                // Plate calculator
                                if currentWeight >= 90 {
                                    PlateCalculatorView(weight: currentWeight)
                                }
                                
                                // Dropsets toggle
                                Toggle("Dropsets", isOn: $dropsetsEnabled)
                                    .tint(AppColors.accent)
                                
                                if dropsetsEnabled {
                                    HStack {
                                        Stepper("Sets: \(numberOfDropsets)", value: $numberOfDropsets, in: 1...5)
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Text("Reduction")
                                        Spacer()
                                        Text("-\(Int(weightReductionPerDropset)) lbs")
                                            .foregroundColor(AppColors.accent)
                                        Stepper("", value: $weightReductionPerDropset, in: 5...50, step: 5)
                                            .labelsHidden()
                                    }
                                }
                                
                                // Warm-up toggle
                                Toggle("Warm-up Set", isOn: $isWarmup)
                                    .tint(AppColors.accent)
                            }
                            .padding(.top, 8)
                        },
                        label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14))
                                Text("Advanced Options")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(AppColors.accent)
                        }
                    )
                    .padding(.horizontal, 20)
                    
                    // Complete Set button (prominent)
                    Button(action: completeSet) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Complete Set")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(categoryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.foreground.opacity(0.2), radius: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Collapsed state (resting or inactive)
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    
                    Text(viewModel.restTimerActive ? "Resting..." : "Completed")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    if !exercise.sets.isEmpty {
                        Text(formatLastSet(exercise.sets.last!))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // Previous sets (always visible below)
            if !exercise.sets.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed Sets")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    ForEach(exercise.sets) { set in
                        CompletedSetRow(set: set, gradient: categoryGradient)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteSet(set)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
            }
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.foreground.opacity(isActive ? 0.1 : 0.05), radius: isActive ? 12 : 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isActive ? categoryGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom), lineWidth: isActive ? 2 : 0)
        )
        .sheet(isPresented: $showHistory) {
            ExerciseHistoryView(exerciseName: exercise.name)
        }
        .sheet(isPresented: $showAlternatives) {
            AlternativeExercisesSheet(currentExercise: exercise.name)
        }
    }
}
```

**Key Improvements:**
- **Reduced disclosure groups**: 4 → 1 (Advanced Options)
- **Cleaner input area**: Side-by-side weight/reps with large numbers
- **Smart suggestions inline**: No hidden disclosure group
- **Context menu**: History, alternatives, favorite in overflow menu
- **Collapsed state**: Shows last set when resting/inactive
- **Swipe to delete**: Sets can be swiped away
- **Progressive disclosure**: Advanced features hidden by default

---

### **PHASE 4: Enhanced Rest Timer**

**Current Issue:** Rest timer can obscure PR badge, complex state management

**Proposed Redesign:**

```swift
struct EnhancedRestTimer: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var timeRemaining: Int {
        viewModel.restTimeRemaining
    }
    
    var progressPercentage: Double {
        Double(timeRemaining) / Double(viewModel.restTimerTotalDuration)
    }
    
    var timerColor: LinearGradient {
        if timeRemaining > 30 {
            return AppColors.accentGradient
        } else if timeRemaining > 10 {
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // PR Badge (displayed above timer during rest)
            if viewModel.showPRBadge {
                PRCelebrationBanner(
                    message: viewModel.prMessage,
                    gradient: AppColors.categoryGradient(for: viewModel.currentExercise.name)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Circular timer
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppColors.muted.opacity(0.3), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progressPercentage)
                
                // Breathing animation circle
                Circle()
                    .fill(timerColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(breathingScale)
                
                // Time display
                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(timerColor)
                        .contentTransition(.numericText())
                    
                    Text("Rest")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            .onAppear {
                startBreathingAnimation()
            }
            
            // Timer controls
            HStack(spacing: 16) {
                // -30s
                Button(action: { viewModel.adjustRestTimer(by: -30) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                        Text("30s")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Skip
                Button(action: { viewModel.skipRest() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                        Text("Skip")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(timerColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // +30s
                Button(action: { viewModel.adjustRestTimer(by: 30) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("30s")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.card)
                .shadow(color: AppColors.foreground.opacity(0.1), radius: 16)
        )
        .padding(.horizontal, 20)
    }
    
    @State private var breathingScale: CGFloat = 1.0
    
    func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            breathingScale = 1.15
        }
    }
}
```

**Key Improvements:**
- **PR banner above timer**: No overlap, clear celebration
- **Color-coded progress**: Blue → Orange → Red based on time
- **Simplified controls**: -30s | Skip | +30s (no "Done" button, skip auto-advances)
- **Breathing animation**: Visual cue for rest period
- **Larger display**: 160pt circle for better visibility

---

### **PHASE 5: PR Celebration Redesign**

**Current Issue:** PR badge can be missed, multiple display locations

**Proposed Solution:**

```swift
struct PRCelebrationBanner: View {
    let message: String
    let gradient: LinearGradient
    
    @State private var confettiTrigger = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Trophy icon with shimmer
            ZStack {
                Circle()
                    .fill(LinearGradient.goldGradient.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(LinearGradient.goldGradient)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: shimmerOffset)
                        .mask(
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24))
                        )
                    )
            }
            
            // Message
            VStack(alignment: .leading, spacing: 2) {
                Text("NEW PR!")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(LinearGradient.goldGradient)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient.goldGradient, lineWidth: 2)
                )
                .shadow(color: Color.yellow.opacity(0.3), radius: 12)
        )
        .confettiCannon(counter: $confettiTrigger, num: 30, radius: 300)
        .onAppear {
            startShimmer()
            HapticManager.success()
            HapticManager.impact(style: .heavy)
            confettiTrigger.toggle()
        }
    }
    
    @State private var shimmerOffset: CGFloat = -100
    
    func startShimmer() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 100
        }
    }
}
```

**Benefits:**
- **Consistent display**: Always above rest timer, never hidden
- **Banner style**: Horizontal layout, more space for message
- **Gold theme**: Unmistakable achievement indicator
- **Confetti on appear**: Automatic celebration
- **Shimmer effect**: Eye-catching animation

---

### **PHASE 6: Completed Sets Redesign**

```swift
struct CompletedSetRow: View {
    let set: ExerciseSet
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number badge
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(set.setNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(gradient)
            }
            
            // Set details
            HStack(spacing: 8) {
                if set.isWarmup {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                
                Text("\(Int(set.weight)) lbs")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("×")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.mutedForeground)
                
                Text("\(set.reps) reps")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                if set.isDropset {
                    Text("(Dropset \(set.dropsetNumber ?? 0))")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppColors.success)
        }
        .padding(12)
        .background(AppColors.muted.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

### **PHASE 7: Alternative Exercises Sheet**

```swift
struct AlternativeExercisesSheet: View {
    let currentExercise: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var exerciseDataManager = ExerciseDataManager.shared
    
    var alternatives: [String] {
        exerciseDataManager.getAlternatives(for: currentExercise)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Similar exercises you can substitute for \(currentExercise)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mutedForeground)
                } header: {
                    Text("About Alternatives")
                }
                
                Section {
                    ForEach(alternatives, id: \.self) { alternative in
                        Button(action: {
                            replaceExercise(with: alternative)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(alternative)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    if let category = detectCategory(alternative) {
                                        Text(category)
                                            .font(.system(size: 13))
                                            .foregroundColor(AppColors.mutedForeground)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(AppColors.categoryGradient(for: alternative))
                            }
                        }
                    }
                } header: {
                    Text("Alternatives (\(alternatives.count))")
                }
            }
            .navigationTitle("Alternative Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
```

---

### **PHASE 8: Workout Completion Modal Redesign**

```swift
struct WorkoutCompletionModal: View {
    let stats: WorkoutCompletionStats
    @Environment(\.dismiss) var dismiss
    @State private var confettiTrigger = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Celebration header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                .scaleEffect(scaleAmount)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        scaleAmount = 1.15
                    }
                }
                
                Text("Workout Complete!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("Great job crushing that workout!")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    icon: "clock.fill",
                    value: formatDuration(stats.duration),
                    label: "Duration",
                    gradient: AppColors.accentGradient
                )
                
                StatCard(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(stats.exerciseCount)",
                    label: "Exercises",
                    gradient: AppColors.chestGradient
                )
                
                StatCard(
                    icon: "number.circle.fill",
                    value: "\(stats.totalSets)",
                    label: "Total Sets",
                    gradient: AppColors.backGradient
                )
                
                StatCard(
                    icon: "scalemass.fill",
                    value: formatVolume(stats.totalVolume),
                    label: "Total Volume",
                    gradient: AppColors.legsGradient
                )
            }
            
            // PRs achieved
            if !stats.prsAchieved.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(LinearGradient.goldGradient)
                        Text("New PRs!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(LinearGradient.goldGradient)
                    }
                    
                    ForEach(stats.prsAchieved, id: \.self) { pr in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text(pr)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                        }
                        .padding(12)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    shareWorkout()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Workout")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(32)
        .background(AppColors.background)
        .confettiCannon(counter: $confettiTrigger, num: 50, radius: 400)
        .onAppear {
            confettiTrigger.toggle()
            HapticManager.success()
        }
    }
    
    @State private var scaleAmount: CGFloat = 0.8
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(gradient)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

---

## Accessibility Enhancements

### **VoiceOver Support**

```swift
// Exercise card
.accessibilityElement(children: .combine)
.accessibilityLabel("\(exercise.name), Set \(exercise.sets.count + 1) of \(exercise.targetSets)")
.accessibilityHint("Double tap to expand exercise options")
.accessibilityAddTraits(.isButton)

// Weight/reps buttons
.accessibilityLabel("Increment weight by 5 pounds")
.accessibilityHint("Current weight: \(Int(currentWeight)) pounds")

// Complete set button
.accessibilityLabel("Complete set with \(Int(currentWeight)) pounds for \(currentReps) reps")
.accessibilityHint("Double tap to log this set and start rest timer")

// Rest timer
.accessibilityLabel("Rest timer: \(formatTime(timeRemaining)) remaining")
.accessibilityValue("\(Int(progressPercentage * 100)) percent complete")
.accessibilityHint("Swipe up to skip rest period")

// PR banner
.accessibilityLabel("New personal record achieved")
.accessibilityValue(prMessage)
.accessibilityAddTraits(.isStaticText)
```

### **Dynamic Type**

```swift
// All text uses .font(.system(size: _, relativeTo: .body))
Text(exercise.name)
    .font(.system(size: 18, weight: .bold, relativeTo: .headline))

// Weight/reps scale appropriately
Text("\(Int(currentWeight))")
    .font(.system(size: 40, weight: .bold, relativeTo: .largeTitle))
    .minimumScaleFactor(0.7)
```

### **Haptic Feedback**

```swift
// Complete set
HapticManager.success() // On successful set completion
HapticManager.impact(style: .heavy) // On button press

// Rest timer warnings
HapticManager.warning() // At 30s, 15s remaining
HapticManager.impact(style: .medium) // At 5s remaining
HapticManager.success() // At timer completion

// PR achievement
HapticManager.success()
HapticManager.impact(style: .heavy)

// Navigation
HapticManager.selection() // On exercise switch
```

---

## Key Files to Create/Modify

### **New Component Files:**
1. `SimplifiedExerciseCard.swift` - Redesigned exercise card
2. `EnhancedRestTimer.swift` - Improved rest timer UI
3. `PRCelebrationBanner.swift` - PR achievement banner
4. `CompletedSetRow.swift` - Set history row component
5. `ExerciseProgressIndicator.swift` - Dot navigation component
6. `AlternativeExercisesSheet.swift` - Alternative exercises picker
7. `WorkoutCompletionModal.swift` - Redesigned completion modal
8. `PlateCalculatorView.swift` - Inline plate breakdown
9. `SmartSuggestionBadge.swift` - Weight/rep suggestion UI

### **Modified Files:**
1. `WorkoutView.swift` - Complete redesign with simplified header
2. `WorkoutViewModel.swift` - Streamlined state management
3. `RestTimerView.swift` - Enhanced with banner support
4. `WorkoutHeader.swift` - Consolidated into overflow menu

---

## Implementation Checklist

### **Week 1: Header & Navigation**
- [ ] Redesign header with consolidated menu
- [ ] Create dot-based exercise progress indicator
- [ ] Add left/right navigation buttons
- [ ] Remove horizontal scrolling exercise chips

### **Week 2: Exercise Card Simplification**
- [ ] Build SimplifiedExerciseCard component
- [ ] Implement progressive disclosure (Advanced Options)
- [ ] Create inline smart suggestions
- [ ] Add context menu for quick actions

### **Week 3: Rest Timer Enhancement**
- [ ] Redesign rest timer with banner support
- [ ] Create PRCelebrationBanner component
- [ ] Improve color-coded progress
- [ ] Simplify timer controls

### **Week 4: Completed Sets & Alternatives**
- [ ] Build CompletedSetRow component
- [ ] Add swipe-to-delete for sets
- [ ] Create AlternativeExercisesSheet
- [ ] Implement exercise replacement logic

### **Week 5: Completion Modal & Polish**
- [ ] Redesign WorkoutCompletionModal
- [ ] Add confetti and celebration effects
- [ ] Create shareable workout summary
- [ ] Improve stats grid layout

### **Week 6: Accessibility & Testing**
- [ ] Add comprehensive VoiceOver support
- [ ] Test Dynamic Type scaling
- [ ] Implement haptic feedback throughout
- [ ] Performance testing with 10+ exercises
- [ ] Bug fixes and refinements

---

## Success Metrics

- ✅ **Reduced visual complexity**: 7 header buttons → 2 + menu
- ✅ **Clearer focus**: Active exercise prominently displayed
- ✅ **Faster input**: Side-by-side weight/reps, larger touch targets
- ✅ **Better PR visibility**: Banner display above timer
- ✅ **Improved navigation**: Dot indicator shows all exercises
- ✅ **Progressive disclosure**: Advanced features hidden until needed
- ✅ **Enhanced accessibility**: Full VoiceOver, Dynamic Type support

---

## Future Enhancements

### **Phase 2 Features:**
1. **Voice Commands**: "Complete set", "Skip rest", "Next exercise"
2. **Apple Watch Companion**: Mirror workout on watch, timer control
3. **Form Cues**: Video overlay or AR form guidance
4. **Tempo Tracking**: Metronome for eccentric/concentric phases
5. **Supersets**: Pair exercises for back-to-back execution
6. **Rest Timer Customization**: Per-exercise rest durations
7. **Auto-weight Progression**: Increase weight based on performance
8. **Workout Notes**: Quick notes per set or exercise
9. **Camera Integration**: Record sets for form review

---

## Design Decisions

### **Why Dot Navigation?**
- Shows all exercises at a glance
- No horizontal scrolling required
- Clear visual progress indicator
- Tap to jump to any exercise
- Scales well with 5-15 exercises

### **Why Simplified Exercise Cards?**
- Reduces cognitive load during workout
- Progressive disclosure keeps advanced features accessible but hidden
- Larger touch targets for weight/reps input
- Side-by-side layout mirrors mental model ("weight × reps")
- Less scrolling to complete a set

### **Why Banner-Style PR Display?**
- Never obscured by rest timer
- More space for achievement message
- Gold theme creates clear visual distinction
- Confetti celebration feels more rewarding
- Shimmer effect draws attention

### **Why Consolidated Header?**
- Reduces visual noise (7 buttons → 3 elements)
- Overflow menu follows iOS patterns
- More space for workout name and stats
- Timer more prominent and glanceable
- Cleaner, more professional appearance

---

## Conclusion

This redesign transforms the Workout View from a **feature-dense, complex interface** into a **focused, streamlined experience** with:

✅ **Simplified Header**: 7 buttons → 2 + overflow menu  
✅ **Clearer Navigation**: Dot indicator + left/right arrows  
✅ **Reduced Complexity**: Progressive disclosure for advanced features  
✅ **Enhanced PR Celebration**: Banner display with confetti and shimmer  
✅ **Improved Rest Timer**: Color-coded progress, banner integration  
✅ **Better Accessibility**: Full VoiceOver, Dynamic Type, haptics  
✅ **Maintained Features**: All existing functionality preserved  

The redesign follows the successful **Templates View** pattern while addressing the unique challenges of in-workout tracking and real-time input.
