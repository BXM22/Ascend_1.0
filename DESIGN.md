# Design System Document

## 1. Overview & Creative North Star

### The Creative North Star: "The Kinetic Atelier"

This design system moves away from the "gamified" aesthetic typical of fitness apps, instead embracing the feel of a high-end, precision-engineered private studio. It is characterized by **"The Kinetic Atelier"**—a space where physical performance meets architectural quietude.

The system rejects the "template" look of standard grids and heavy borders. Instead, we use intentional asymmetry, overlapping elements, and high-contrast typography scales to create an editorial experience. The goal is to make the user feel like they are interacting with a premium piece of performance equipment, where every pixel is deliberate and every transition feels fluid yet authoritative.

---

## 2. Colors & Tonal Logic

The palette is rooted in deep, masculine tones balanced by clinical, engineered accents.

### Color Roles

- **Primary (`#9cd0d3` / `#3c6e71`):** Represents action and precision. Use for primary call-to-actions and active states.
- **Secondary (`#a8cbe7` / `#284b63`):** Used for analytical data, progress indicators, and subtle focus.
- **Surface (`#131313` / `#353535`):** The foundation. It creates a "recessed" environment that makes content pop.
- **Tertiary/Neutral (`#d9d9d9`):** Used for high-readability body text and subtle instructional elements.

### The "No-Line" Rule

Standard 1px solid borders are strictly prohibited for sectioning. Boundaries must be defined solely through:

1. **Background Color Shifts:** Placing a `surface-container-low` card against a `surface` background.
2. **Negative Space:** Using the Spacing Scale (specifically `8` and `10`) to separate logical groups.
3. **Tonal Transitions:** Moving from a solid color to a subtle gradient.

### Surface Hierarchy & Nesting

Think of the UI as layers of physical materials.

- **Base Layer:** `surface` (#131313) or `surface-dim`.
- **Primary Content Containers:** `surface-container-highest` (#353535).
- **Nested Elements:** Within a container, use `surface-container-low` to create "inset" areas for secondary data (like heart rate stats within a workout card).

### The Glass & Gradient Rule

To achieve a "high-end engineered" feel, floating navigation bars and modal overlays must use **Glassmorphism**.

- **Formula:** Surface color at 60–80% opacity + `backdrop-blur` (16px to 24px).
- **Signature Texture:** For hero CTAs, use a subtle linear gradient (45°) transitioning from `secondary_container` to `primary_container`. This provides a visual "soul" that feels more dynamic than flat color.

---

## 3. Typography

**Font Family:** Manrope (Sharp, Modern, Geometric).

- **Display (Large/Medium):** Used for high-impact metrics (e.g., "320 kcal"). Use `-2%` letter spacing to give it a tight, "machined" look.
- **Headline:** Used for section titles. These should be set in Semi-Bold to provide an authoritative anchor to the layout.
- **Title:** Used for card headings. Keep these concise and prioritize hierarchy over length.
- **Body:** Set in `tertiary` (#d9d9d9) for readability. Ensure a high line-height (1.5×) to maintain the "editorial" breathing room.
- **Labels:** Used for metadata. These can be all-caps with `+5%` letter spacing to distinguish them from interactive text.

The typography hierarchy conveys brand identity by prioritizing "The Metric" (Display) and "The Instruction" (Headline), reflecting the app's focus on engineering results.

---

## 4. Elevation & Depth

We achieve hierarchy through **Tonal Layering** rather than shadows or structural lines.

### The Layering Principle

Depth is created by "stacking" container tiers.

- **High Importance:** Place a `surface-bright` or `surface-container-highest` element on top of `surface-container-lowest`. This creates a natural "lift."

### Ambient Shadows

When an element must float (e.g., a Floating Action Button or a Modal), use **Ambient Shadows**:

- **Blur:** 40px–60px.
- **Opacity:** 4%–8%.
- **Color:** Use a tinted version of `on-surface` (#e4e2e1) rather than pure black. This mimics natural light reflecting off a dark surface.

### The "Ghost Border" Fallback

If a border is required for accessibility (e.g., an inactive input field), use a **Ghost Border**:

- **Token:** `outline-variant`.
- **Opacity:** 15% max.
- **Rule:** Never use 100% opaque borders; they disrupt the "Kinetic Atelier" flow.

---

## 5. Components

### Buttons

- **Primary:** Gradient-fill using `primary` to `primary_container`. Roundedness: `full`. No border.
- **Secondary:** Surface-fill (`secondary_container`) with `on_secondary_container` text.
- **Tertiary:** Text-only, using `secondary` color, paired with a small chevron icon for directionality.

### Cards & Lists

- **Rule:** Forbid divider lines.
- **Implementation:** Separate list items using `spacing-2` or `spacing-3`. Use `surface-container-highest` for the card background and `xl` (1.5rem) corner radius.
- **Asymmetry:** Experiment with placing large-scale typography (Display-sm) in the top-right corner of a card, slightly overlapping the card padding for a custom, editorial look.

### Input Fields

- **Resting State:** `surface-container-low` background with a `ghost border`.
- **Focus State:** 1px `primary` border with a subtle 4px `primary` outer glow (8% opacity).
- **Shape:** `md` (0.75rem) roundedness to contrast with the "full" roundness of buttons.

### Specialized Fitness Components

- **Progress Rings:** Use `primary` for the active track and `surface-container-highest` for the empty track. Use a "glow" effect on the progress head using a 10px blur of the `primary` color.
- **Data Grids:** Avoid 2×2 grids. Use staggered layouts where one metric (e.g., "Duration") takes up 60% width, and two smaller metrics (e.g., "BPM", "Steps") stack vertically at 40% width.

---

## 6. Do's and Don'ts

### Do

- **Do** prioritize white space. If in doubt, add more padding (Spacing 8+).
- **Do** use `primary` sparingly. It is a "laser pointer," not a bucket of paint.
- **Do** ensure all text on `surface` backgrounds uses `on_surface` or `tertiary` for a minimum 4.5:1 contrast ratio.

### Don't

- **Don't** use pure black (#000000). Use the Jet (#353535) and Surface (#131313) tokens to maintain tonal depth.
- **Don't** use standard "Drop Shadows." They feel dated and "cheap." Use Tonal Layering or Ambient Shadows.
- **Don't** use sharp corners. The fitness experience should feel ergonomic; stick to the `md`, `lg`, and `xl` roundedness tokens.
- **Don't** crowd the screen with dividers. Let the background color shifts do the work.

---

## Appendix: Ascend implementation map

Doc names use kebab/snake_case; Swift uses `AppColors` and related types.

| Doc token | Swift / notes |
|-----------|-----------------|
| `primary` / `primary_container` | `AppColors.primary`, `primaryContainer`, `primaryDim`; gradients: `LinearGradient.primaryGradient` |
| `secondary` (brand) | `AppColors.accent`, `brandSecondary`, `secondaryContainer` — not `AppColors.secondary` (neutral chrome) |
| `surface`, `surface-container-highest`, `surface-container-low` | `surface`, `surfaceContainerHighest`, `surfaceContainerLow` / `surfaceContainerHigh` |
| `surface-dim` / `surface-bright` | Map to `surface` + container steps until dedicated tokens exist |
| `on_surface`, `tertiary` | `foreground`, `onSurface`, `tertiary`; boosted dark-mode body: `BrandHex.textOnDark` / `textMutedOnDark` in `AppColors.swift` |
| `outline-variant` | `AppColors.outlineVariant` |
| Spacing `2` / `3` / `8` / `10` (doc) | `AppSpacing.spacing2`, `.spacing3`, `.spacing8`, `.spacing10`; radii: `.radiusMD` (12), `.radiusLG`, `.radiusXL` (24) |
| Typography (Manrope) | Bundled TTFs in `Ascend/Resources/Fonts/` + `Info.plist` `UIAppFonts`. `AppTypography` uses Manrope; Display/Label tracking + body line height: `View` helpers in `Typography.swift` (`kineticDisplayTracking`, `kineticLabelTracking`, `kineticBodyLineHeight`) |
| Glassmorphism | `KineticGlassBackground`, `.kineticGlassBarSurface()` in `KineticComponents.swift` (tinted surface + `.ultraThinMaterial`) |
| Hero CTA 45° gradient | `LinearGradient.heroCTA` — `secondaryContainer` → `primaryContainer`, bottomLeading → topTrailing |
| Ambient shadow tint | `KineticElevation.ambientTint` / `ambientShadow(radius:opacity:)` |

Canonical hex values live in `BrandHex` inside `Ascend/Theme/AppColors.swift`.
