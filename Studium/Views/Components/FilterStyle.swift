//
//  FilterStyle.swift
//  Studium
//

import SwiftUI

enum FilterStyle {
    static let chipCorner: CGFloat = 8
    static let cardCorner: CGFloat = 12
    static let chipStrokeWidth: CGFloat = 1

    static func chipFill(selected: Bool, accent: Color, colorScheme: ColorScheme) -> Color {
        if selected {
            return accent.opacity(colorScheme == .dark ? 0.34 : 0.14)
        }
        return Color.tertiarySystemFill
    }

    static func orderCardFill(selected: Bool, accent: Color, colorScheme: ColorScheme) -> Color {
        if selected {
            return accent.opacity(colorScheme == .dark ? 0.30 : 0.11)
        }
        return Color.tertiarySystemFill
    }

    /// Visible in light and dark: accent when selected, subtle separator when not.
    static func chipBorder(selected: Bool, accent: Color) -> Color {
        selected ? accent.opacity(0.85) : Color.primary.opacity(0.12)
    }
}
