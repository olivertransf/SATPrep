//
//  ViewExtensions.swift
//  Studium
//
//  Cross-platform wrappers for iOS-only SwiftUI modifiers.
//  Apply these instead of the raw UIKit-only modifiers so the app compiles
//  and runs correctly on macOS.
//

import SwiftUI

// MARK: - Cross-platform toolbar placements

extension ToolbarItemPlacement {
    /// Leading navigation bar placement on iOS; cancellation-action position on macOS.
    static var navLeading: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarLeading
        #else
        .cancellationAction
        #endif
    }

    /// Trailing navigation bar placement on iOS; primary-action position on macOS.
    static var navTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .navigationBarTrailing
        #else
        .primaryAction
        #endif
    }
}

extension View {

    // MARK: - Navigation bar title display mode (iOS only)

    /// Large title on iOS; no-op on macOS (titles are always inline in the toolbar).
    func navLargeTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    /// Inline title on iOS; no-op on macOS.
    func navInlineTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Large title on iPad/Mac; inline on iPhone.
    @ViewBuilder
    func navAdaptiveTitle() -> some View {
        #if os(iOS)
        if StudiumDesignSystem.isPhone {
            self.navigationBarTitleDisplayMode(.inline)
        } else {
            self.navigationBarTitleDisplayMode(.large)
        }
        #else
        self
        #endif
    }

    // MARK: - Text input (iOS only)

    /// Disables auto-capitalisation on iOS; no-op on macOS (not applicable).
    func autocapitalizationOff() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    // MARK: - Sheet presentation detents (iOS 16+, no-op on macOS)

    /// Restricts a sheet to medium/large detents on iOS; sheets are full-height on macOS.
    func presentationDetentsMediumLarge() -> some View {
        #if os(iOS)
        self.presentationDetents([.medium, .large])
        #else
        self
        #endif
    }

    // MARK: - Scrollview background clearing (iOS only)

    /// Removes the default scrollview background tint injected by some iOS list styles.
    func clearScrollBackground() -> some View {
        #if os(iOS)
        self.scrollContentBackground(.hidden)
        #else
        self
        #endif
    }
}
