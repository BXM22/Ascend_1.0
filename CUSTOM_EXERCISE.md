# Custom Exercise

Reference for **user-defined exercises** in Ascend: the `CustomExercise` model, persistence, how they merge with the built-in exercise database, and where the UI surfaces. For global visual language, see [DESIGN.md](./DESIGN.md).

---

## 1. Role in the app

Custom exercises let users **name movements that are not in the default catalog**, attach **muscle groups**, **alternatives**, optional **equipment** and **video URL**, and then pick those names anywhere exercise text is chosen (sessions, templates, autocomplete).

They are **first-class names** in `ExerciseDataManager`: lookups for muscle groups, alternatives, and video URLs **prefer custom definitions** when the exercise name matches (case-insensitive).

---

## 2. Data model

**File:** `Ascend/Models/CustomExercise.swift`

| Field | Notes |
|--------|--------|
| `id` | `UUID`, stable across edits |
| `name` | Display string; uniqueness enforced when adding (see validation) |
| `primaryMuscleGroups` | `[String]` — values from `MuscleGroup.rawValue` |
| `secondaryMuscleGroups` | Optional secondary tagging |
| `alternatives` | Free-text substitute exercise names |
| `videoURL` | Optional string (often a URL); used as the exercise’s video source when set |
| `category` | `ExerciseCategory.rawValue` (Chest, Back, … Other) |
| `equipment` | Optional free text |
| `dateCreated` | Preserved when editing |

**Enums:** `MuscleGroup` and `ExerciseCategory` define the allowed picker values for the add/edit form.

---

## 3. Persistence and lifecycle

**Owner:** `ExerciseDataManager.shared` (`Ascend/ViewModels/ExerciseDataManager.swift`).

| Concern | Implementation |
|---------|------------------|
| Storage | `UserDefaults`, key `AppConstants.UserDefaultsKeys.customExercises` (`"customExercises"`) |
| Encoding | JSON array of `CustomExercise` |
| Save behavior | Debounced via `PerformanceOptimizer.shared.debouncedSave` |
| Published state | `@Published private(set) var customExercises` — SwiftUI observes changes |

**API (summary):**

- `addCustomExercise(_:)` — appends if no existing exercise has the same **case-insensitive** name  
- `updateCustomExercise(_:)` — replaces by `id`  
- `deleteCustomExercise(_:)` — removes by `id`  
- `clearAllCustomExercises()` — wipes list (also used when resetting app data from settings)  
- `getCustomExercise(name:)` — case-insensitive match  

---

## 4. How custom exercises interact with the catalog

For a given **exercise name string**, `ExerciseDataManager` generally checks **custom first**, then built-in / ExRx behavior.

| Method | Custom behavior |
|--------|------------------|
| `getMuscleGroups(for:)` | If custom match → `(primaryMuscleGroups, secondaryMuscleGroups)`. Else ExRx, then keyword fallback. |
| `getAlternatives(for:)` | Prepends `custom.alternatives`, then merges database / ExRx alternatives (deduped where applicable). |
| `getVideoURL(for:)` | If custom match and `videoURL` set → that string. Else built-in `exerciseDatabase`, skill progressions, calisthenics skills. |

**Autocomplete:** `ExerciseAutocompleteField` appends **all custom exercise names** to the searchable exercise list so users can type and select them like catalog exercises.

---

## 5. UI surfaces

### Add / edit form

**`AddCustomExerciseView`** (`Ascend/Views/Components/AddCustomExerciseView.swift`)

- **Create:** `AddCustomExerciseView(onSave:)`  
- **Edit:** `AddCustomExerciseView(exercise:onSave:)` — pre-fills fields; save calls `onSave` with updated `CustomExercise` (same `id` / `dateCreated` rules as in `saveExercise()`)

**Validation before save:**

- Name non-empty  
- At least one **primary** muscle group  
- On **create** only: no duplicate name (case-insensitive) vs existing custom exercises  

Uses **`AppColors`** / **`LinearGradient.primaryGradient`** for chrome (aligned with general settings-style forms, not necessarily full Kinetic wireframe).

### Library list (browse, edit, delete)

**`CustomExercisesListView`** (`Ascend/Views/Components/CustomExercisesListView.swift`)

- Lists `ExerciseDataManager.shared.customExercises`  
- Tap **edit** → sheet with `AddCustomExerciseView(exercise:)` → `updateCustomExercise`  
- **Delete** → `deleteCustomExercise`  

### Where the add sheet is presented

| Area | Typical trigger |
|------|------------------|
| **Exercise database** | `MasterExerciseListView` — add custom exercise affordance opens `AddCustomExerciseView` → `addCustomExercise` |
| **Session / add exercise** | `WorkoutView` — add custom exercise; optional navigation to `CustomExercisesListView` when the user already has customs |
| **Templates** | `TemplatesView` — template builder flows that need new exercise names (two sheet sites in the file) |

Exact line numbers drift; search the project for `showAddCustomExercise` or `AddCustomExerciseView` to find current call sites.

---

## 6. Dependencies for contributors

| Type | Symbol |
|------|--------|
| Model | `CustomExercise`, `MuscleGroup`, `ExerciseCategory` |
| State / API | `ExerciseDataManager.shared` |
| Forms / lists | `AddCustomExerciseView`, `CustomExercisesListView`, `CustomExerciseCard` |
| Integration | `ExerciseAutocompleteField` (names), workout/template flows that pass exercise name strings |

---

## 7. Future-friendly notes

- **Sync:** Currently local-only (`UserDefaults`). If iCloud or backend sync is added, `CustomExercise` is already `Codable` and `Identifiable`.  
- **Naming collisions:** Built-in catalog names can still be typed; custom entries are separate rows keyed by name in the custom array — product decision whether to block names that exist in the static DB.  
- **Kinetic styling:** Add/edit/list views are **not** fully migrated to Kinetic Manrope chrome; treat [DESIGN.md](./DESIGN.md) as the target when touching visuals.
