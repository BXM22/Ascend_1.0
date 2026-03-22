# Settings

Reference for the **Settings** experience in Ascend: what it contains, where it lives in code, and how preferences are stored.

---

## Entry points

Settings opens as a **modal sheet** (navigation title **Settings**, trailing **Done**) from:

- **ContentView** — gear / settings affordances on Dashboard, Progress, Templates, Habits.
- **WorkoutView** — in-workout access to the same `SettingsView`.

Implementation: `SettingsView` in `Ascend/Views/WorkoutView.swift` (search for `// MARK: - Settings View`).

Dependencies passed into `SettingsView`:

| Dependency | Role |
|------------|------|
| `SettingsManager` | Rest timer, warm-up percentages, custom color theme, bar weight, reset orchestration |
| `ProgressViewModel` | Cleared on full data reset |
| `TemplatesViewModel` | Reset / default templates |
| `WorkoutProgramViewModel` | Reset programs |
| `ThemeManager` | Light / dark / system mode; reset to system on full data reset |

Appearance mode (light / dark / system) is **not** duplicated inside this sheet; it is controlled via **`ThemeManager`** from headers (e.g. `HeaderThemeToggle`) elsewhere.

---

## Screen sections (current UI)

### 1. Rest Timer

- **Purpose:** Default rest duration between sets (seconds).
- **Controls:**
  - Current value summary.
  - **Quick options** grid — presets from `AppConstants.restTimerOptions` (e.g. 30 … 300 s).
  - **Custom duration** slider: **30–600** seconds, step **15** (see `SettingsView` + `SettingsManager.restTimerDuration`).
- **Persistence:** `UserDefaults` key `restTimerDuration` (`AppConstants.UserDefaultsKeys.restTimerDuration`).
- **Default:** `AppConstants.Timer.defaultRestDuration` (90 s).

### 2. Apple Health

- **Component:** `AppleHealthSettingsSection` (same file as `SettingsView`, below it).
- **Purpose:** Connect or reconnect **HealthKit** so completed workouts can sync.
- **Behavior:** Uses `HealthKitManager.shared`; shows connection status and primary action **Connect to Apple Health** / **Reconnect**.

### 3. App Colors

- **Purpose:** Deep customization of UI colors (per-key overrides) and related theme tooling.
- **Navigation:** **Customize UI Colors** → `UIColorCustomizationView` (`Ascend/Views/Components/UIColorCustomizationView.swift`).
- **Related:** `UIColorCustomizationManager`, `SavedThemeManager`, Coolors import via `SettingsManager.importTheme` / `importAndSaveTheme` (see `SettingsManager.swift`).
- **Indicator:** Checkmark when `UIColorCustomizationManager.shared.hasCustomizations` is true.

### 4. Data Management

- **Reset All Data** — destructive; shows a confirmation alert.
- **Effect:** Calls `SettingsManager.resetAllData(progressViewModel:templatesViewModel:programViewModel:themeManager:)`.
- **Clears (high level):** UserDefaults keys listed in `SettingsManager` (rest timer, theme, programs, templates, custom exercises, completed workouts, PRs, workout/rest days, rest timer state, etc.), in-memory singletons (`WorkoutHistoryManager`, custom exercises), progress counts, templates trimmed to defaults, programs reset to defaults, `ThemeManager.themeMode` → `.system`.

### 5. Exercise Database

- **View All Exercises** — opens `MasterExerciseListView` (sheet); count from `ExRxDirectoryManager.shared.getAllExercises()`.

### 6. Custom Exercises

- **Add Custom Exercise** — sheet `AddCustomExerciseView`; persists via `ExerciseDataManager`.
- **View Custom Exercises** — shown when the user has custom exercises; opens `CustomExercisesListView`.

### 7. Help & Support

- **Show Tutorial** — resets `OnboardingManager.shared` tutorial and dismisses the settings sheet so the tutorial can run.

---

## `SettingsManager` (core preferences)

File: `Ascend/ViewModels/SettingsManager.swift`.

| Property | Notes |
|----------|--------|
| `restTimerDuration` | Int (seconds); persisted |
| `barWeight` | Double (lbs default 45); key `"barWeight"` |
| `warmupPercentages` | `[Double]`; default `AppConstants.Warmup.defaultPercentages` |
| `pauseTimerDuringRest` | Bool |
| `customTheme` | Optional `ColorTheme`; JSON in UserDefaults `customColorTheme` |

Theme import from Coolors URLs, apply/reset theme helpers, and **full reset** are implemented here.

---

## Related components (not necessarily on the Settings sheet)

- **`WarmupSettingsSection`** — defined in `WorkoutView.swift` near `WarmupSettingsSection`; warm-up **data** still lives on `SettingsManager`, but this section may not be embedded in `SettingsView` (verify in UI if you add it).
- **`RecoverySettingsView`** — recovery-related UI (`Ascend/Views/Components/RecoverySettingsView.swift`).
- **`ThemeManager`** — `Ascend/ViewModels/ThemeManager.swift` (system / light / dark).

---

## Design alignment

For visual language (Kinetic Atelier, surfaces, typography), see **`DESIGN.md`**. Settings currently uses shared `AppColors` / card styling in `SettingsView`; a future pass could align every block with **Kinetic** tokens used on Dashboard / Progress.

---

## Files to touch when changing Settings

| Area | Primary files |
|------|----------------|
| Settings UI | `WorkoutView.swift` (`SettingsView`, `AppleHealthSettingsSection`) |
| Persistence & reset | `SettingsManager.swift`, `AppConstants.swift` (`UserDefaultsKeys`) |
| Color UI | `UIColorCustomizationView.swift`, `ColorTheme.swift` |
| Health | `HealthKitManager` (and related), `AppleHealthSettingsSection` |
