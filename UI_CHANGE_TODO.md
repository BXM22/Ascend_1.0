# UI changes still to do

Living checklist for **Kinetic Atelier** alignment ([DESIGN.md](./DESIGN.md)), **detail / card surfaces**, and gaps called out in feature docs. Checked items are for you to mark off in-repo as you ship.

---

## Detail & preview surfaces (high impact)

These are the flows where users “open” something for more context—most still use generic `AppColors` / `NavigationView` patterns while the Templates chrome is already kinetic ([TEMPLATE_VIEW.md](./TEMPLATE_VIEW.md) §2, §10).

- [ ] **Template detail sheet** (`TemplateDetailView.swift`) — Bring in line with kinetic tokens: glass-style presentation where appropriate, capped content width on large devices, Manrope display/label tracking, tonal cards instead of flat badges, hero CTA using `LinearGradient.heroCTA`, avoid harsh bordered chips.
- [ ] **Template create/edit** (`TemplateEditView` in `TemplatesView.swift`) — Doc’d as not redesigned ([TEMPLATES_REDESIGN.md](./Ascend/TEMPLATES_REDESIGN.md) Known Limitations). Match editor chrome, inputs (ghost border / focus glow from DESIGN §5), and section spacing to the rest of Templates.
- [ ] **Template filter sheet** (`TemplateFilterSheet.swift`) — Same visual system as search row + bento list; consistent pill/chip styling and sheet detents.
- [ ] **Program detail** (`WorkoutProgramView.swift` + sheet host in `WorkoutProgramsSection.swift`) — Horizontal “simple” program cards and full program scroll are pre-kinetic; align header, day selector, and day detail cards with surface hierarchy and typography rules.
- [ ] **Programs list / expanded cards** (`WorkoutSplitsSection.swift`, `WorkoutProgramCard`) — Replace decorative emoji header pattern if desired; unify card radius, spacing, and CTA styling with DESIGN §5.
- [ ] **Skill detail sheet** (`CalisthenicsSkillsSection.swift` → `CalisthenicsSkillView.swift`) — Navigation chrome + body: kinetic surfaces, editorial layout for progression/steps, consistent with Skills segment expectations in TEMPLATE_VIEW.
- [ ] **Exercise / PR detail** (`ExerciseDetailSheet.swift` → `ExerciseHistoryView`) — Current sheet is a thin wrapper; [PROGRESS_REDESIGN_IMPLEMENTATION.md](./PROGRESS_REDESIGN_IMPLEMENTATION.md) describes a richer detail experience (hero, badges, chart, history). Either implement that vision or deliberately scope a smaller kinetic pass (header, stat cards, list rows).
- [ ] **Progress tab shell** (`ProgressView.swift`) — If not fully aligned with [PROGRESS_REDESIGN.md](./PROGRESS_REDESIGN.md), schedule pass for segmented layout, filter sheet, and stat/exercise cards.
- [ ] **Habit detail** (`HabitDetailView.swift`) — No kinetic usage today; align with `HabitsView` patterns (Dashboard/Habits already reference kinetic styling).
- [ ] **Recovery / muscle detail** (`MuscleRecoveryCard.swift` — `MuscleRecoveryDetailCard` and related) — Standard `AppTypography`/`AppColors` cards; optional pass for staggered metrics (DESIGN §5 data grids) and container tiering.

---

## Main tabs & chrome (broader UI)

- [ ] **Workout (active session)** (`WorkoutView.swift`) — [WORKOUT_REDESIGN_IMPLEMENTATION.md](./WORKOUT_REDESIGN_IMPLEMENTATION.md) outlines header simplification, exercise navigation, rest integration, etc.; no kinetic hooks in file today—treat as a dedicated redesign track.
- [ ] **Settings & generation flows** — Any sheet reached from Templates header / `ContentView` should share glass bars, typography, and button tiers with DESIGN §5.
- [ ] **Shared sheets & pickers** — Audit `TemplateSelectionSheet`, generation settings, help overlays, and workout completion modals for the same token set.

---

## System-quality UI (from Templates redesign doc)

- [ ] **Dynamic Type** — Templates doc lists as not done; extend to detail sheets and editors.
- [ ] **Reduce Motion** — Respect `accessibilityReduceMotion` on sheet transitions and list animations.
- [ ] **iPad & landscape** — Capped widths + adaptive columns for bento/detail content ([TEMPLATES_REDESIGN.md](./Ascend/TEMPLATES_REDESIGN.md) limitations).
- [ ] **Async / background filtering** — Performance item for very large template lists (less pure UI, affects perceived smoothness).

---

## Verification (when closing the above)

- [ ] Light/dark parity on all updated detail surfaces.
- [ ] VoiceOver labels on new controls in sheets (especially kinetic custom buttons).
- [ ] Cross-link any finished work in [TEMPLATE_VIEW.md](./TEMPLATE_VIEW.md) §10 changelog and trim this file.

---

*Generated from DESIGN.md, TEMPLATE_VIEW.md, TEMPLATES_REDESIGN.md, PROGRESS_REDESIGN.md, WORKOUT_REDESIGN_IMPLEMENTATION.md, and a quick kinetic-usage scan (`TemplatesView`, `HabitsView`, `DashboardView` vs. most sheets and secondary tabs).*
