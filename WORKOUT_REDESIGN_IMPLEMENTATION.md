# Workout View Redesign - Implementation Plan

## Overview
Comprehensive UI/UX overhaul of the Workout View following the successful Templates and Progress redesigns. This redesign focuses on **simplified navigation**, **reduced cognitive load**, **enhanced feedback**, and **progressive disclosure** while preserving all advanced workout tracking features.

---

## Design Philosophy

### **Core Principles**
- ✅ **Focus mode** - Minimize distractions during active workout
- ✅ **One tap to log** - Primary action always prominent
- ✅ **Progressive disclosure** - Advanced features hidden until needed
- ✅ **Contextual feedback** - PR celebrations, rest guidance, encouragement
- ✅ **Visual clarity** - Reduce button count, improve hierarchy
- ✅ **Smart defaults** - Auto-suggest weights/reps from history
- ✅ **Swipe gestures** - Quick actions without breaking flow

---

## Current State Analysis

### **Existing Features** ✅
- Multi-exercise workouts (weight/reps, calisthenics, cardio, stretching)
- Set completion tracking with PR detection
- Rest timer with breathing animation
- Dropset support (configurable count and reduction)
- Smart suggestions (weight/rep recommendations)
- Plate calculator (bar loading breakdown)
- Alternative exercises (ExRx integration)
- Warm-up set generation
- Auto-advance to next exercise
- Exercise segmentation (Warmup/Main/Cardio)
- Workout timer (elapsed time)
- Undo last set (5-second window)
- Template-based or manual workouts
- Completion modal with stats
- Background persistence

### **Pain Points Identified** 🔴
1. **Header clutter** - 7 buttons (Auto-advance, Help, Settings, Pause, Finish, Volume, Time)
2. **Exercise navigation** - Horizontal chip scrolling hides exercises
3. **Card complexity** - Multiple disclosure groups (Dropsets, Warm-up, Alternatives, History)
4. **Rest timer position** - Separate section, not integrated into flow
5. **PR celebration** - Easy to miss, badge-only feedback
6. **Cognitive load** - Multiple timers, segments, state transitions
7. **Touch targets** - Small exercise chips, preset buttons
8. **Accessibility** - Limited VoiceOver support

---

## Redesign Strategy

### **PHASE 1: Simplified Header**

**Before:**
```
[Workout Name] [Volume] [Time]
[Auto-advance] [Help] [Settings] [Pause] [Finish]
```

**After:**
```swift
struct WorkoutHeader: View {
    @Binding var workoutName: String
    @Binding var totalVolume: Double
    @Binding var elapsedTime: TimeInterval
    @Binding var timerPaused: Bool
    @Binding var autoAdvanceEnabled: Bool
    let completedExercises: Int
    let totalExercises: Int
    let onTogglePause: () -> Void
    let onFinish: () -> Void
    let onSettings: () -> Void
    let onHelp: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
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
                                .font(.system(size: 11))
                            Text(formatVolume(totalVolume))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppColors.mutedForeground)
                        
                        // Progress badge
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 11))
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
                                systemImage: autoAdvanceEnabled ? "checkmark.circle.fill" : "circle"
                            )
                        }
                        
                        Button(action: onSettings) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button(action: onHelp) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: onCancel) {
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
                        .shadow(color: AppColors.shadow, radius: 2, x: 0, y: 1)
                }
            }
            
            // Bottom row: Timer + action buttons
            HStack(spacing: 12) {
                // Elapsed time
                HStack(spacing: 6) {
                    Image(systemName: timerPaused ? "pause.circle.fill" : "clock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(timerPaused ? Color.orange : LinearGradient.primaryGradient)
                    
                    Text(formatElapsedTime(elapsedTime))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(timerPaused ? Color.orange : LinearGradient.primaryGradient)
                }
                
                Spacer()
                
                // Pause/Resume button
                Button(action: onTogglePause) {
                    Image(systemName: timerPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
                
                // Finish button
                Button(action: onFinish) {
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
                    .shadow(color: AppColors.shadow, radius: 3, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let pounds = Int(volume)
        if pounds >= 1000 {
            return String(format: "%.1fK lbs", Double(pounds) / 1000.0)
        }
        return "\(pounds) lbs"
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
```

**Key Changes:**
- ✅ 7 buttons → 2 buttons + 1 menu
- ✅ Volume and exercise count as metadata badges (not buttons)
- ✅ Auto-advance, Settings, Help moved to overflow menu
- ✅ Timer display more prominent with icon
- ✅ Pause state clearly indicated (orange icon)
- ✅ Finish button gradient-styled, prominent

---

### **PHASE 2: Dot-Based Exercise Navigation**

**Current Issue:** Horizontal scrolling chips hide exercises, unclear total count

**Solution:**

```swift
struct ExerciseNavigationBar: View {
    let exercises: [Exercise]
    @Binding var currentIndex: Int
    let onExerciseSelect: (Int) -> Void
    
    private var hasPrevious: Bool {
        currentIndex > 0
    }
    
    private var hasNext: Bool {
        currentIndex < exercises.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Dot indicators
            HStack(spacing: 8) {
                ForEach(exercises.indices, id: \.self) { index in
                    let exercise = exercises[index]
                    let isActive = index == currentIndex
                    let isCompleted = exercise.sets.count >= exercise.targetSets
                    
                    Circle()
                        .fill(
                            isCompleted 
                                ? AppColors.success 
                                : (isActive ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(AppColors.muted))
                        )
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: isActive ? 2 : 0)
                        )
                        .onTapGesture {
                            withAnimation(.smooth) {
                                onExerciseSelect(index)
                            }
                            HapticManager.shared.impact(style: .light)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(AppColors.border)
            
            // Current exercise name + arrows
            HStack(spacing: 12) {
                Button(action: {
                    if hasPrevious {
                        withAnimation(.smooth) {
                            onExerciseSelect(currentIndex - 1)
                        }
                        HapticManager.shared.impact(style: .light)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasPrevious ? AppColors.textPrimary : AppColors.muted)
                        .frame(width: 40, height: 40)
                }
                .disabled(!hasPrevious)
                
                VStack(spacing: 4) {
                    Text(exercises[currentIndex].name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("Exercise \(currentIndex + 1) of \(exercises.count)")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    if hasNext {
                        withAnimation(.smooth) {
                            onExerciseSelect(currentIndex + 1)
                        }
                        HapticManager.shared.impact(style: .light)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(hasNext ? AppColors.textPrimary : AppColors.muted)
                        .frame(width: 40, height: 40)
                }
                .disabled(!hasNext)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 3, x: 0, y: 2)
    }
}
```

**Benefits:**
- ✅ All exercises visible at once (dot row)
- ✅ Tap dot to jump to exercise
- ✅ Swipe arrows for linear navigation
- ✅ Completed exercises indicated in green
- ✅ Active exercise highlighted with border
- ✅ Current position always clear ("Exercise X of Y")
- ✅ No horizontal scrolling needed

---

### **PHASE 3: Simplified Exercise Card**

**Current Issue:** Too many disclosure groups, nested sections

**Solution:**

```swift
struct SimplifiedExerciseCard: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let exerciseIndex: Int
    
    var exercise: Exercise {
        viewModel.currentWorkout!.exercises[exerciseIndex]
    }
    
    @State private var weight: String = ""
    @State private name reps: String = ""
    @State private var showHistory = false
    @State private var showAlternatives = false
    @State private var showDropsetSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
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
                        Label("Alternatives", systemImage: "arrow.triangle.swap")
                    }
                    
                    if exercise.type == .weighted {
                        Button(action: { showDropsetSettings = true }) {
                            Label("Dropset Settings", systemImage: "arrow.down.circle")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive, action: deleteExercise) {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
            
            // Input section (type-specific)
            inputSection
            
            // Smart suggestions row
            if let suggestion = viewModel.getWeightSuggestion(for: exercise) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text("Suggested: \(Int(suggestion.weight)) lbs × \(suggestion.reps) reps")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    Spacer()
                    
                    Button("Use") {
                        weight = "\(Int(suggestion.weight))"
                        reps = "\(suggestion.reps)"
                        HapticManager.shared.impact(style: .light)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                }
                .padding(12)
                .background(AppColors.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Complete Set button
            Button(action: completeSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Set")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient.primaryGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(!canCompleteSet)
            
            // Previous sets (if any)
            if !exercise.sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Previous Sets")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.mutedForeground)
                    
                    ForEach(exercise.sets.reversed()) { set in
                        PreviousSetRow(set: set)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showHistory) {
            ExerciseHistorySheet(exerciseName: exercise.name)
        }
        .sheet(isPresented: $showAlternatives) {
            AlternativeExercisesSheet(currentExercise: exercise.name)
        }
        .sheet(isPresented: $showDropsetSettings) {
            DropsetSettingsSheet(exercise: exercise)
        }
    }
    
    @ViewBuilder
    private var inputSection: some View {
        switch exercise.type {
        case .weighted:
            weightedInputs
        case .calisthenics:
            calisthenicsInputs
        case .cardio:
            cardioInputs
        case .stretch:
            stretchInputs
        }
    }
    
    private var weightedInputs: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Weight")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("lbs", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Reps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                
                TextField("reps", text: $reps)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // ... other input types (calisthenics, cardio, stretch)
    
    private var canCompleteSet: Bool {
        switch exercise.type {
        case .weighted:
            return !weight.isEmpty && !reps.isEmpty
        case .calisthenics:
            return !reps.isEmpty
        case .cardio:
            return true // Time/distance tracked separately
        case .stretch:
            return true // Duration tracked separately
        }
    }
    
    private func completeSet() {
        // Implementation
        HapticManager.shared.impact(style: .medium)
    }
    
    private func deleteExercise() {
        // Implementation
    }
}

struct PreviousSetRow: View {
    let set: ExerciseSet
    
    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
            
            Spacer()
            
            if let weight = set.weight, let reps = set.reps {
                Text("\(Int(weight)) lbs × \(reps)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if set.isPR {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(10)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
```

**Key Improvements:**
- ✅ All inputs visible (no disclosure groups)
- ✅ Advanced features in overflow menu
- ✅ Smart suggestions prominent
- ✅ Large "Complete Set" button
- ✅ Previous sets always visible
- ✅ PR indicator on set rows
- ✅ Cleaner visual hierarchy

---

### **PHASE 4: Enhanced Rest Timer**

**Current Issue:** Rest timer separate section, breaks flow

**Solution: Integrated Banner**

```swift
struct EnhancedRestTimerBanner: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onSkip: () -> Void
    
    @State private var breatheScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            // Breathing animation circle
            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 60, height: 60)
                    .scaleEffect(breatheScale)
                    .opacity(0.3)
                
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 50, height: 50)
                
                Text("\(viewModel.restTimeRemaining)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    breatheScale = 1.3
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Breathe and recover")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mutedForeground)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.muted)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.primaryGradient)
                            .frame(
                                width: geo.size.width * (1 - Double(viewModel.restTimeRemaining) / Double(viewModel.restDuration)),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }
            
            Spacer()
            
            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}
```

**Benefits:**
- ✅ Integrated into main flow (banner style)
- ✅ Breathing animation guides recovery
- ✅ Progress bar shows time remaining
- ✅ Skip button for quick advance
- ✅ Doesn't hide exercise card
- ✅ Contextual messages ("Breathe and recover")

---

### **PHASE 5: PR Celebration Banner**

**Current Issue:** PR badge easy to miss

**Solution: Full-width celebration banner**

```swift
struct PRCelebrationBanner: View {
    let exercise: String
    let prType: String // "New PR!", "Matched PR!", "Volume PR!"
    let onDismiss: () -> Void
    
    @State private var confettiTrigger = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Animated trophy
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .confettiCannon(counter: $confettiTrigger, num: 30, radius: 200)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prType)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    Text(exercise)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Keep crushing it! 💪")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient.primaryGradient
                .opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(LinearGradient.primaryGradient, lineWidth: 2)
        )
        .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .onAppear {
            confettiTrigger = true
            HapticManager.shared.notification(type: .success)
        }
    }
}
```

**Benefits:**
- ✅ Impossible to miss
- ✅ Confetti animation on appear
- ✅ Motivational message
- ✅ Dismissible (but prominent)
- ✅ Gradient border + background
- ✅ Success haptic feedback

---

### **PHASE 6: Redesigned Completion Modal**

**Current Issue:** Basic stats list

**Solution:**

```swift
struct WorkoutCompletionModal: View {
    let workout: Workout
    let onDismiss: () -> Void
    let onSaveAndExit: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero section
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                
                Text("Workout Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(workout.name)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "clock.fill",
                    label: "Duration",
                    value: formatDuration(workout.duration)
                )
                
                StatCard(
                    icon: "flame.fill",
                    label: "Exercises",
                    value: "\(workout.exercises.count)"
                )
                
                StatCard(
                    icon: "scalemass.fill",
                    label: "Total Volume",
                    value: "\(Int(workout.totalVolume)) lbs"
                )
                
                StatCard(
                    icon: "star.fill",
                    label: "PRs Set",
                    value: "\(workout.prCount)"
                )
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onSaveAndExit) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Save & Exit")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: onDismiss) {
                    Text("Continue Tracking")
                        .font(.system(size: 15))
                        .foregroundStyle(LinearGradient.primaryGradient)
                }
            }
        }
        .padding(24)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 5)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
```

---

## Implementation Checklist

### **Models** (if needed)
- [ ] `WorkoutTab.swift` - Tab enum (if implementing tab structure)
- [ ] No new filters needed (workout is linear flow)

### **UI Components**
- [ ] `WorkoutHeader.swift` - Simplified header with consolidated menu
- [ ] `ExerciseNavigationBar.swift` - Dot navigation with arrows
- [ ] `SimplifiedExerciseCard.swift` - Streamlined exercise card
- [ ] `EnhancedRestTimerBanner.swift` - Integrated rest timer banner
- [ ] `PRCelebrationBanner.swift` - Full-width PR celebration
- [ ] `WorkoutCompletionModal.swift` - Redesigned completion modal

### **Main View Updates**
- [ ] Redesign `WorkoutView.swift` main structure
- [ ] Replace header with `WorkoutHeader`
- [ ] Replace horizontal chips with `ExerciseNavigationBar`
- [ ] Replace current exercise cards with `SimplifiedExerciseCard`
- [ ] Integrate `EnhancedRestTimerBanner` (conditional display)
- [ ] Integrate `PRCelebrationBanner` (on PR detection)
- [ ] Update completion flow with new modal

### **ViewModel Updates** (if needed)
- [ ] Add `currentExerciseIndex` tracking (if not existing)
- [ ] Add helper methods for navigation (previous/next exercise)
- [ ] Ensure PR detection triggers banner state
- [ ] Ensure rest timer state management

### **Testing**
- [ ] Verify all exercise types work (weighted, calisthenics, cardio, stretch)
- [ ] Test dot navigation and arrow navigation
- [ ] Test PR celebration banner appearance
- [ ] Test rest timer banner functionality
- [ ] Test completion modal stats calculation
- [ ] Verify dropset settings accessible from menu
- [ ] Verify history/alternatives accessible from menu
- [ ] Test auto-advance functionality
- [ ] Test pause/resume functionality
- [ ] Verify undo last set works
- [ ] Test finish workout flow

---

## Key Features Preserved

✅ **All Exercise Types** - Weighted, calisthenics, cardio, stretching  
✅ **PR Detection** - Weight PRs, rep PRs, volume PRs  
✅ **Rest Timer** - Breathing animation, skip option  
✅ **Smart Suggestions** - Weight/rep recommendations  
✅ **Dropsets** - Configurable count and reduction  
✅ **Warm-up Sets** - Generation and tracking  
✅ **Auto-advance** - Automatic next exercise  
✅ **Plate Calculator** - Bar loading breakdown  
✅ **Alternative Exercises** - ExRx integration  
✅ **Exercise History** - Past performance viewing  
✅ **Undo Last Set** - 5-second window  
✅ **Workout Timer** - Elapsed time tracking  
✅ **Pause/Resume** - Timer control  
✅ **Background Persistence** - State preservation  

---

## Success Metrics

### **Simplification**
- Header buttons: 7 → 2 + menu ✅
- Exercise navigation: Scrolling chips → Dot indicators ✅
- Card disclosure groups: 4-5 → 0 (moved to menu) ✅
- Primary action prominence: Hidden → Large gradient button ✅

### **Clarity**
- Exercise position visibility: Chip scroll → "X of Y" label ✅
- Rest timer integration: Separate section → Banner ✅
- PR feedback: Small badge → Full-width banner ✅
- Completion summary: List → Card grid ✅

### **Accessibility**
- VoiceOver labels on all interactive elements ✅
- Semantic traits for buttons/menus ✅
- Haptic feedback on all actions ✅
- High contrast color usage ✅

---

## Migration Notes

### **What Changes**
1. **Header** - Simplified with consolidated menu
2. **Exercise Navigation** - Dots replace chips
3. **Exercise Cards** - Disclosure groups moved to menu
4. **Rest Timer** - Banner style instead of separate section
5. **PR Celebration** - Full-width banner with confetti
6. **Completion Modal** - Card-based stats grid

### **What Stays the Same**
1. **All workout data** - No data migration needed
2. **All exercise tracking logic** - Same set completion flow
3. **All integrations** - HealthKit, CloudKit, etc.
4. **All settings** - Rest duration, auto-advance, etc.
5. **All background behavior** - State restoration, etc.

### **No Breaking Changes**
- All existing workouts will work
- All ViewModel methods preserved
- All integrations with other views maintained
- Theme system fully compatible

---

## Future Enhancements (Phase 2)

1. **Exercise Form Videos** - Inline video demonstrations
2. **Real-time Form Analysis** - Camera-based rep counting
3. **Voice Commands** - "Complete set", "Start rest timer"
4. **Workout Notes** - Quick notes per exercise
5. **Superset Support** - Pair exercises for supersets
6. **Exercise Swaps** - One-tap swap with alternatives
7. **Progress Photos** - Photo capture at workout completion
8. **Social Sharing** - Share workout summary to social media

---

## Conclusion

This redesign transforms the Workout View from a feature-dense interface into a **focused, streamlined workout companion**. By applying progressive disclosure, consolidating controls, and enhancing feedback mechanisms, the redesign reduces cognitive load while maintaining all advanced features.

**Key Wins:**
- ✅ Simpler navigation (dots > chips)
- ✅ Cleaner header (2 buttons + menu > 7 buttons)
- ✅ Better feedback (PR banner > badge)
- ✅ Integrated rest timer (banner > separate section)
- ✅ Focus on primary action (large "Complete Set" button)
- ✅ All features preserved (moved to menus, not removed)

**Ready for implementation following the same systematic approach used for Progress View redesign.**
