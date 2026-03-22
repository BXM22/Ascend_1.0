//
//  KineticAdaptivePalette.swift
//  Ascend
//
//  M3-style kinetic tokens for **dark** (HTML wireframe) and **light** surfaces.
//  Inject from `ContentView` via `KineticAdaptivePalette.alignedWithAppColors(_)` so palette matches `AppColors`
//  (imported themes + per-key overrides). Prefer `@Environment(\.kineticPalette)` in views.
//

import SwiftUI

/// Shared kinetic chrome — workout session, Progress, Studio, Habits, Templates, exercise library.
struct KineticAdaptivePalette: Equatable {
    /// Canvas / screen base (alias: `surface` in legacy code).
    let background: Color
    let surfaceContainerLowest: Color
    let surfaceContainerLow: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let surfaceBright: Color

    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color

    let secondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color

    let tertiary: Color
    let onSurface: Color
    let onSurfaceVariant: Color

    let outline: Color
    let outlineVariant: Color
    let mutedChrome: Color

    /// Same as `background` — Progress / cards used both names.
    var surface: Color { background }

    /// Studio / Habits nav icon tone (alias of `mutedChrome`).
    var mutedNav: Color { mutedChrome }

    // MARK: - Resolve

    static func resolve(_ scheme: ColorScheme) -> KineticAdaptivePalette {
        switch scheme {
        case .light: return .light
        case .dark: return .dark
        @unknown default: return .dark
        }
    }

    /// Dark — original Tailwind / HTML kinetic spec.
    static let dark = KineticAdaptivePalette(
        background: Color(hex: "131313"),
        surfaceContainerLowest: Color(hex: "0e0e0e"),
        surfaceContainerLow: Color(hex: "1b1c1c"),
        surfaceContainerHigh: Color(hex: "2a2a2a"),
        surfaceContainerHighest: Color(hex: "353535"),
        surfaceBright: Color(hex: "393939"),
        primary: Color(hex: "9cd0d3"),
        onPrimary: Color(hex: "003739"),
        primaryContainer: Color(hex: "3c6e71"),
        onPrimaryContainer: Color(hex: "bbeef1"),
        secondary: Color(hex: "a8cbe7"),
        secondaryContainer: Color(hex: "2a4c65"),
        onSecondaryContainer: Color(hex: "9abdd9"),
        tertiary: Color(hex: "c6c6c6"),
        onSurface: Color(hex: "e4e2e1"),
        onSurfaceVariant: Color(hex: "c0c8c8"),
        outline: Color(hex: "8a9293"),
        outlineVariant: Color(hex: "404849"),
        mutedChrome: Color(hex: "d9d9d9")
    )

    /// Light — lifted neutrals, same accent family, readable contrast on white/off-white.
    static let light = KineticAdaptivePalette(
        background: Color(hex: "f4f4f5"),
        surfaceContainerLowest: Color(hex: "ffffff"),
        surfaceContainerLow: Color(hex: "ececec"),
        surfaceContainerHigh: Color(hex: "e2e2e0"),
        surfaceContainerHighest: Color(hex: "d6d6d4"),
        surfaceBright: Color(hex: "cbcbc9"),
        primary: Color(hex: "2d6d70"),
        onPrimary: Color(hex: "ffffff"),
        primaryContainer: Color(hex: "a8d4d7"),
        onPrimaryContainer: Color(hex: "0d2220"),
        secondary: Color(hex: "3d5a80"),
        secondaryContainer: Color(hex: "d9e7f2"),
        onSecondaryContainer: Color(hex: "1a3a52"),
        tertiary: Color(hex: "5c5c5c"),
        onSurface: Color(hex: "1c1b1f"),
        onSurfaceVariant: Color(hex: "45474c"),
        outline: Color(hex: "6b7280"),
        outlineVariant: Color(hex: "c4c7c7"),
        mutedChrome: Color(hex: "5c5c5c")
    )
}

// MARK: - Environment (injected from `ContentView` via `effectiveColorScheme`)

private struct KineticPaletteKey: EnvironmentKey {
    static let defaultValue: KineticAdaptivePalette = .dark
}

extension EnvironmentValues {
    /// Resolved kinetic M3 palette for the active appearance (light / dark).
    var kineticPalette: KineticAdaptivePalette {
        get { self[KineticPaletteKey.self] }
        set { self[KineticPaletteKey.self] = newValue }
    }
}

// MARK: - Align with AppColors (custom palette + overrides)

extension KineticAdaptivePalette {
    /// Kinetic tokens driven by `AppColors` so imported palettes, `UIColorCustomization` keys, and light/dark all stay in sync.
    static func alignedWithAppColors(_ colorScheme: ColorScheme) -> KineticAdaptivePalette {
        _ = colorScheme // Reserved for future slot-based resolution; `AppColors` already resolves from traits + overrides.
        return KineticAdaptivePalette(
            background: AppColors.background,
            surfaceContainerLowest: AppColors.secondary,
            surfaceContainerLow: AppColors.input,
            surfaceContainerHigh: AppColors.card,
            surfaceContainerHighest: AppColors.card,
            surfaceBright: AppColors.muted,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.primaryGradientStart,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.accent,
            secondaryContainer: AppColors.secondaryContainer,
            onSecondaryContainer: AppColors.onSecondaryContainer,
            tertiary: AppColors.tertiary,
            onSurface: AppColors.foreground,
            onSurfaceVariant: AppColors.mutedForeground,
            outline: AppColors.border,
            outlineVariant: AppColors.outlineVariant,
            mutedChrome: AppColors.mutedForeground
        )
    }
}
