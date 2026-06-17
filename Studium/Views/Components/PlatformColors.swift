//
//  PlatformColors.swift
//  Studium
//
//  Semantic colors aligned with `studium-web/src/index.css` (Sync-style palette).
//  Asset names: StudiumBg, StudiumCard, StudiumSurface, StudiumFillTertiary, StudiumBorder.
//

import SwiftUI

extension Color {
    // MARK: - Grouped background hierarchy (matches web --bg / --card / --surface)
    // Asset catalog also exposes `studiumBorder` and `studiumSectionRW` as generated symbols.

    /// Main screen background (`--bg`).
    static var systemGroupedBackground: Color {
        Color("StudiumBg")
    }

    /// Primary raised surface (`--card` on web; also used like systemBackground).
    static var systemBackground: Color {
        Color("StudiumCard")
    }

    /// Raised card on grouped background (`--card`).
    static var secondarySystemGroupedBackground: Color {
        Color("StudiumCard")
    }

    /// Muted secondary label.
    static var studiumMuted: Color {
        Color.secondary
    }

    /// Hairline separators and chip outlines.
    static var studiumSeparator: Color {
        studiumBorder
    }

    /// Tertiary inset surface (`--surface`).
    static var tertiarySystemGroupedBackground: Color {
        Color("StudiumSurface")
    }

    // MARK: - Fill hierarchy

    /// Unselected chip / subtle fill (`--input` on web).
    static var tertiarySystemFill: Color {
        Color("StudiumFillTertiary")
    }

    // MARK: - Gray palette (tuned to sit on Studium backgrounds)

    /// Borders, disabled chrome.
    static var systemGray4: Color {
        Color("StudiumBorder")
    }

    /// Tracks, subtle pills.
    static var systemGray5: Color {
        Color("StudiumFillTertiary")
    }

    /// Very subtle fills.
    static var systemGray6: Color {
        Color("StudiumFillTertiary")
    }
}
