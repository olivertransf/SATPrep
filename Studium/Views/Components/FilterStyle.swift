//
//  FilterStyle.swift
//  Studium
//

import SwiftUI

enum FilterStyle {
    static let chipCorner: CGFloat = StudiumDesignSystem.radiusChip
    static let cardCorner: CGFloat = StudiumDesignSystem.radiusCard
    static let chipStrokeWidth: CGFloat = 1

    static func chipFill(selected: Bool, accent: Color, colorScheme: ColorScheme) -> Color {
        if selected {
            return accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
        }
        return Color.tertiarySystemFill
    }

    static func orderCardFill(selected: Bool, accent: Color, colorScheme: ColorScheme) -> Color {
        if selected {
            return accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
        }
        return Color.tertiarySystemFill
    }

    /// Visible in light and dark: accent when selected, web `--border` when not.
    static func chipBorder(selected: Bool, accent: Color) -> Color {
        selected ? accent.opacity(0.45) : Color.studiumBorder
    }

    /// Tinted icon badge background (Home quick-start, reference section icons).
    static func iconBadgeFill(tint: Color, colorScheme: ColorScheme) -> Color {
        tint.opacity(colorScheme == .dark ? 0.22 : 0.10)
    }

    /// Subtle card elevation — matches web `.studium-card` shadow.
    static func elevatedShadowColor(colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.32)
        }
        return Color(red: 0.059, green: 0.090, blue: 0.165).opacity(0.07)
    }
}
