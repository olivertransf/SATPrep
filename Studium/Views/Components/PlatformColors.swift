//
//  PlatformColors.swift
//  Studium
//
//  Cross-platform Color extensions that replace UIKit-only Color initializers.
//  Use Color.systemGroupedBackground instead of Color(.systemGroupedBackground), etc.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    // MARK: - Grouped background hierarchy (UIColor.system*GroupedBackground)

    /// Main table / scrollview background (iOS grouped, macOS window).
    static var systemGroupedBackground: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemGroupedBackground)
        #endif
    }

    /// Standard content surface (raised cards on grouped screens).
    static var systemBackground: Color {
        #if os(macOS)
        Color(NSColor.textBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }

    /// Card / row background one level above the main background.
    static var secondarySystemGroupedBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemGroupedBackground)
        #endif
    }

    /// Tertiary grouped background (innermost inset group).
    static var tertiarySystemGroupedBackground: Color {
        #if os(macOS)
        Color(NSColor.underPageBackgroundColor)
        #else
        Color(UIColor.tertiarySystemGroupedBackground)
        #endif
    }

    // MARK: - Fill hierarchy

    /// Subtle fill for chips, badges, and interactive hits (iOS tertiarySystemFill).
    static var tertiarySystemFill: Color {
        #if os(macOS)
        Color.primary.opacity(0.06)
        #else
        Color(UIColor.tertiarySystemFill)
        #endif
    }

    // MARK: - Gray palette (iOS systemGray4 / 5 / 6)

    /// Slightly lighter gray — borders, disabled backgrounds.
    static var systemGray4: Color {
        #if os(macOS)
        Color.primary.opacity(0.22)
        #else
        Color(UIColor.systemGray4)
        #endif
    }

    /// Even lighter gray — progress bar tracks, subtle fills.
    static var systemGray5: Color {
        #if os(macOS)
        Color.primary.opacity(0.12)
        #else
        Color(UIColor.systemGray5)
        #endif
    }

    /// Near-invisible gray — very subtle backgrounds.
    static var systemGray6: Color {
        #if os(macOS)
        Color.primary.opacity(0.06)
        #else
        Color(UIColor.systemGray6)
        #endif
    }
}
