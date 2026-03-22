# Workout View

Reference for the **Session** tab (`WorkoutView` + `WorkoutViewModel`): layout, exercise surfaces, timers, and how it relates to [DESIGN.md](./DESIGN.md).

---

## 1. Role in the app

The Workout screen is the **live session** surface: **elapsed time**, **volume**, **rest**, **set logging**, and **finish / cancel**. Users arrive here when they start a workout from a template, program day, or ad-hoc flow. A secondary **Timer** segment embeds the sports interval timer without leaving the tab.

**Entry:** `ContentView` → tab **Session** → `WorkoutView(viewModel: workoutViewModel)`.

**Key dependencies:**

| Dependency | Purpose |
|------------|---------|
| `WorkoutViewModel` | Current workout, exercise index, rest/PR/timer state, completion |
| `SettingsManager` | Rest behavior, timer pause, HealthKit-related prefs (via VM) |
| `ProgressViewModel` | History sheet, PR detection, stats (weak, injected) |
| `TemplatesViewModel` | Template linkage when workout started from a template |
| `WorkoutProgramViewModel` | Program context when applicable |
| `ThemeManager` | Settings sheet appearance |

**Note:** Workout **completion modal** (`WorkoutCompletionModal`) is presented from **`ContentView`** when `WorkoutViewModel.showCompletionModal` is set for template-originated sessions, so it sits above the tab hierarchy.

---

## 2. Visual system

Session UI primarily uses **`AppColors`** (semantic light/dark + optional custom theme), **`LinearGradient.primaryGradient`** for accents, and system typography on cards. It is **not** fully migrated to the Kinetic Templates **Manrope** wireframe; header uses **`.system`** fonts with gradient title treatment.

Align new workout chrome with **DESIGN.md** where practical: tonal surfaces, primary lit on dark for CTAs, avoid harsh 1px rules except focused exercise selection rings.

---

## 3. Information architecture

### Top-level segments (`WorkoutTimerSegment`)

| Segment | Purpose |
|---------|---------|
| **Workout** | Hero header + scrollable exercise list / navigation |
| **Timer** | `SportsTimerView(isEmbedded: true)` — interval / stopwatch-style tooling |

The segment bar (`WorkoutTimerSegmentBar`) sits **below** the hero when **Workout** is selected; switching to **Timer** hides the redesigned workout header.

### Workout content modes

When **Workout** is active and `currentWorkout` has exercises:

1. **Horizontal (default)** — `ExerciseNavigationBar` + **one** focused card (`currentExercise`) + **Add Exercise**.
2. **Vertical** — toggle from header; **all** exercises in a `LazyVStack` with reorder chevrons and tap-to-focus.

If there are **no** exercises, an empty state prompts **Add Exercise**.

### Exercise card routing (`exerciseCardView(for:)`)

Cards are chosen from **`WorkoutViewModel`** section/type helpers:

| Condition | Component |
|-----------|-----------|
| Stretch section | `StretchExerciseCard` |
| Cardio (`isCardioExercise`) | `CardioExerciseCard` |
| Calisthenics + hold target | `CalisthenicsHoldExerciseCard` |
| Calisthenics reps | `CalisthenicsExerciseCard` |
| Default weighted | `SimplifiedWeightedExerciseCard` |

Current exercise gets a **primary stroke** overlay (`RoundedRectangle` 12pt) where applicable.

---

## 4. UI regions (conceptual)

1. **Hero header** (`RedesignedWorkoutHeader`) — **Sticky** above the segment bar (not inside the exercise `ScrollView`). Shows workout name, volume, completed/total exercises, elapsed time, pause, **Finish**, overflow (settings / help / cancel), layout toggle, auto-advance binding.
2. **Segment bar** — **Workout** vs **Timer** with icons and underline.
3. **Scroll content** (`exercisesScrollContent`) — `ScrollViewReader` + `LazyVStack` (spacing 16):
   - **Rest:** `EnhancedRestTimerBanner` when `restTimerActive`.
   - **PR:** `PRCelebrationBanner` when `showPRBadge` + message.
   - **Exercises:** horizontal nav + card **or** vertical list + card(s).
   - **Add:** `AddExerciseButton` → `showAddExerciseSheet`.
   - Bottom **spacer** (~100pt) for tab bar clearance.
4. **Sheets** — add exercise, exercise history, in-VM settings, help (`PageFeaturesView` workout page).
5. **Alerts** — confirm **Finish** workout, confirm **Cancel** workout.

**Tap-to-dismiss keyboard** on the root `VStack` (resign first responder).

---

## 5. State & flows (ViewModel highlights)

`WorkoutViewModel` owns session state: `currentWorkout`, `currentExerciseIndex`, `elapsedTime`, rest timers, PR flags, expanded sections, dropset config, auto-advance, undo metadata, and sheets (`showAddExerciseSheet`, `showSettingsSheet`, `showExerciseHistory`, completion modal flags).

**Typical flows:**

| Flow | Description |
|------|-------------|
| **Log sets** | Card-specific; VM updates sets, may trigger rest, PR UI, `readyForNextSet` for scroll sync |
| **Rest** | Banner actions: skip, ±30s |
| **Finish** | Alert → `finishWorkout()` — completion UI may be handled at `ContentView` |
| **Cancel** | Alert → `cancelWorkout()` |
| **Add exercise** | Sheet → `addExercise(...)` |
| **Reorder** | Vertical mode — `moveExercise(from:to:)` |

---

## 6. File layout note

`Ascend/Views/WorkoutView.swift` is a **large** file: the primary **`WorkoutView`** struct lives at the **top** (~lines 12–492). The same file also contains many legacy and shared UI types (`LegacyWorkoutView`, `ExerciseCard`, `SettingsView` re-exports, plate calculator, etc.). Prefer **`WorkoutView`** + **`WorkoutTimerSegmentBar`** for navigation when reading; extract new session UI into **`Ascend/Views/Components/`** when adding features.

**Extracted session chrome:**

| File | Role |
|------|------|
| `Ascend/Views/Components/RedesignedWorkoutHeader.swift` | Sticky hero: name, stats, controls |

---

## 7. Related files

| File | Role |
|------|------|
| `Ascend/Views/WorkoutView.swift` | `WorkoutView`, segment bar, `exerciseCardView`, many exercise subviews |
| `Ascend/ViewModels/WorkoutViewModel.swift` | Session logic, timers, set completion |
| `Ascend/ViewModels/WorkoutViewModel+Validation.swift` | Validation helpers |
| `Ascend/Views/Components/RedesignedWorkoutHeader.swift` | Workout hero |
| `Ascend/Views/SportsTimerView.swift` | Embedded **Timer** segment (`isEmbedded: true`) |
| `ContentView.swift` | Tab host, completion modal overlay |

---

## 8. Tests

- **Unit:** `AscendTests/WorkoutViewModelTests.swift` — view model behavior.

---

## 9. Changelog (doc)

| Date | Note |
|------|------|
| 2026-03 | Initial `WORKOUT_VIEW.md` — documents `WorkoutView` shell, segments, card routing, and VM boundaries. |
