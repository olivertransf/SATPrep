//
//  PlatformColors.swift
//  Studium
//
//  Semantic colors aligned with `studium-web/src/index.css` (Sync-style palette).
//  Asset names: StudiumBg, StudiumCard, StudiumSurface, StudiumFillTertiary, StudiumBorder.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    // MARK: - Grouped background hierarchy (matches web --bg / --card / --surface)

    /// Main screen background (`--bg`).
    static var systemGroupedBackground: Color {
        Color("StudiumBg")
    }

    /// Primary raised surface (`--card` on web; also used like systemBackground).
    static var systemBackground: Color {
        Color("StudiumCard")
    }

    /// Secondary grouped surface (`--card` in dark, white in light).
    static var secondarySystemGroupedBackground: Color {
        Color("StudiumCard")
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
        #if os(macOS)
        Color("StudiumBorder")
        #else
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.141, green: 0.141, blue: 0.141, alpha: 1)
                : UIColor(red: 0.78, green: 0.78, blue: 0.82, alpha: 1)
        })
        #endif
    }

    /// Tracks, subtle pills.
    static var systemGray5: Color {
        #if os(macOS)
        Color("StudiumBorder").opacity(0.85)
        #else
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
                : UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
        })
        #endif
    }

    /// Very subtle fills.
    static var systemGray6: Color {
        #if os(macOS)
        Color("StudiumFillTertiary")
        #else
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        })
        #endif
    }
}
