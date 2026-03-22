# Templates View

Reference for the **Templates** tab (`TemplatesView` + `TemplatesViewModel`): layout, behavior, data, and how it follows [DESIGN.md](./DESIGN.md).

---

## 1. Role in the app

The Templates screen is where users **browse, search, filter, organize, and launch** saved **workout templates**. It sits alongside programs and skills-oriented content via a **segmented control** and connects to **workout start** (switch to Workout tab with a chosen template) and **settings** (generation options, app settings).

**Entry:** `ContentView` → tab **Templates** → `TemplatesView`.

**Key dependencies:**

| Dependency | Purpose |
|------------|---------|
| `TemplatesViewModel` | Templates CRUD, persistence, defaults, generation settings |
| `WorkoutViewModel` | Starting workouts from a template |
| `WorkoutProgramViewModel` | Programs segment content |
| `ProgressViewModel` | Stats / integration where needed |
| `ThemeManager` | Appearance |

**Callbacks:**

- `onStartTemplate()` — e.g. switch to Workout tab after user picks a template to run.
- `onSettings()` — present `SettingsView` / generation sheet entry points.

---

## 2. Visual system (Kinetic Atelier)

Align new UI with **DESIGN.md**:

- **Canvas:** `surface` (`#131313`); cards on elevated surfaces (`surface-container-low` / `-highest`).
- **Primary actions:** brand primary (`#9cd0d3` / `#3c6e71` on dark) for CTAs, selection, and key icons.
- **Secondary / analytical:** secondary blues for filters, counts, metadata.
- **Typography:** **Manrope** for headings and labels; respect `kineticDisplayTracking` / `kineticLabelTracking` where applicable.
- **Depth:** avoid harsh borders; use tonal shifts and spacing (see DESIGN.md §2 §4).

Templates chrome uses **`KineticTemplatePalette`** + **Manrope** (`TemplateKineticFonts`). Main column matches **`AppConstants.UI.mainColumnMaxWidth`** (600pt) with **`px-6`** (24pt) gutters, centered — same as Studio / Habits. **iPhone (compact):** bento is **one column** (`grid-cols-1`). **iPad / regular width:** two-up row + full-width featured third card + grid for the rest. **Sort** lives in **`TemplateFilterSheet`** (`TemplateLibrarySortOption`). Sheets may still use `AppColors`.

---

## 3. Information architecture

### Segments (`ContentSegment`)

| Segment | Purpose |
|---------|---------|
| **Programs** | Program-driven flows (ties to `WorkoutProgramViewModel`) |
| **Skills** | Kinetic **Mastery** layout: optional **active objective** (`CalisthenicsSkillManager.activeSkillId`, persisted); that skill is the headline + hero and is **pinned first** in `displayOrderedSkills`. Set/clear via **long-press** on cards or **target** menu in `CalisthenicsSkillView`. **Create custom skill**, 2-col compact cards (regular width) or single column; **Practice** / chart opens detail |
| **Templates** | Core **template library** — search, sort, **bento** cards, detail sheet |

Default segment is **Templates** unless state is restored.

### Template list (Templates segment)

- **Auto-generate** — full-width **capsule** (primary text, `surface-container-low` fill, `primary-container` stroke), matching Skills **Create custom skill**; opens the generation sheet. Also in the title **ellipsis** menu as “Generate workout”.
- **Search** — debounced text field; matches template name and exercise names.
- **Filters** — `TemplateFilters` + filter sheet; optional “active” filter state.
- **Sort** — `TemplateLibrarySortOption` in the **filter** sheet (with filter Apply).
- **Layout** — **Compact:** single column, third item can use **featured** styling. **Regular width:** two-column row, then full-width **featured** third card (`showEditorialMetric`), then 2-col grid. Hero URLs cycle from the wireframe; **tap** → detail; **play** / **Start Session** → `startTemplate` + `onStartTemplate`.
- **Excluded** — templates whose name contains `"Progression"` are filtered out of the main list (calisthenics progression handled elsewhere).

---

## 4. UI regions (conceptual)

**Layout:** Library uses a **`GeometryReader`** + centered **`HStack`** + **fixed `width:`** (`min(mainColumnMaxWidth, screen − 2×gutter)`) so **AsyncImage / bento** can’t widen the column after load. **Title, segment strip, auto-generate, and search** sit **above** the `ScrollView` (fixed “hero” chrome); only **segment body** scrolls. Studio / Habits still use the simpler **frame (cap) → frame (infinity) → padding** stack inside one `ScrollView`.

1. **Title row** — Large “Templates” title + subtitle; trailing **ellipsis menu** (generate, generation settings, multi-select) and **settings** gear (`onSettings`). Multi-select pins a **strip** below the status bar (cancel, count, delete).
2. **Segment control** — pill strip: Programs / Skills / Templates (`kineticSegmentStrip`).
3. **Auto-generate row** — on **Templates** segment only: sparkles + **AUTO-GENERATE** (capsule outline, same as Skills create-custom); opens generation sheet.
4. **Search row** — magnifying glass + field + clear (HTML-style); square **filter** opens **filter sheet** (filters + **sort** picker).
5. **Content** — Programs: `WorkoutSplitsSection`. **Skills:** kinetic wireframe-style `CalisthenicsSkillsSection` (Manrope, material-style cards, progress from `SkillProgressionLevel.isCompleted`). **Templates:** **bento** cards (`TemplateBentoCard`); **context menu** edit / duplicate / delete (where allowed).
6. **FAB** — gradient **+** (`createTemplate`) above the tab bar; hidden during multi-select.
7. **Empty state** — dashed border “No templates found” + **AUTO-GENERATE** (capsule) + secondary **Create Template**.
8. **Sheets** — edit/create template, generation, generation settings, filters, detail, calisthenics progression as before.

---

## 5. Data & persistence

- **Model:** `WorkoutTemplate` (exercises, duration, intensity, flags, etc.).
- **Store:** `UserDefaults` key `AppConstants.UserDefaultsKeys.savedWorkoutTemplates`; JSON encode/decode in `TemplatesViewModel`.
- **Defaults:** `loadDefaultTemplates()` seeds Push/Day/Pull/Legs style templates when empty.
- **Calisthenics:** separate templates loaded via `loadCalisthenicsTemplates()`; cached in VM.

**ViewModel highlights:**

- Debounced saves on `templates` change.
- Suggestion index rebuilt for faster lookups.
- `generationSettings` + `showGenerationSettings` for generation UI.

---

## 6. User flows

| Flow | Description |
|------|-------------|
| **Find template** | Search + filters + sort; optional grouped view. |
| **Start workout** | Select template → route to workout (via `onStartTemplate` / `WorkoutViewModel`). |
| **Create / edit** | Template editor sheet (create/edit); `TemplatesViewModel.saveTemplate` etc. |
| **Duplicate / delete** | Swipe actions or multi-select + bulk delete. |
| **Generate** | Generate sheet → new template from rules / AI settings. |
| **Settings** | Title row gear → `onSettings()`; generation settings may use `viewModel.showGenerationSettings`. |

---

## 7. Performance & accessibility

- **Filtering:** Cached filtered list + cache key (`filterKey`, `sortOption`, `debouncedSearchText`, template count) to avoid recomputing on every frame.
- **Search debounce:** ~300 ms before updating `debouncedSearchText`.
- **Lazy stacks** — `LazyVStack` for long lists.
- **Accessibility** — labels on search field, buttons, and multi-select actions where present in code.

---

## 8. Tests & UI tests

- **Unit:** `AscendTests/TemplatesViewModelTests.swift` — persistence and VM behavior.
- **UI:** `AscendUITests/TemplatesUITests.swift` — critical paths on device/simulator.

---

## 9. Related files

| File | Role |
|------|------|
| `Ascend/Views/TemplatesView.swift` | Main view |
| `Ascend/ViewModels/TemplatesViewModel.swift` | State and persistence |
| `Ascend/Views/Components/TemplateSelectionSheet.swift` | Selection / preview |
| `ContentView.swift` | Tab wiring, `onStartTemplate`, `onSettings` |

---

## 10. Changelog (doc)

| Date | Note |
|------|------|
| 2026-03 | Initial `TEMPLATE_VIEW.md` — documents structure and DESIGN.md alignment. |
| 2026-03 | **Auto-generate** capsule (aligned with Skills create-custom) on Templates segment + kinetic empty state. |
| 2026-03 | **Skills** segment: kinetic mastery layout (hero + grid, create custom skill). |
| 2026-03 | **Active objective** skill: persisted id, pinned to top, editorial headline + hero **ACTIVE** badge. |
