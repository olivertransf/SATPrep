//
//  LayoutMetrics.swift
//  Studium
//
//  Shared breakpoints and preference keys for adaptive layouts (especially macOS window resizing).
//

import SwiftUI

enum LayoutMetrics {
    /// Below this width, Practice and Quiz use the compact shell (iPhone-style). Same threshold on iOS, iPad, and macOS.
    static let macWideBreakpoint: CGFloat = 900
    /// Extra-wide practice grid adds a third concept column.
    static let macTripleColumnBreakpoint: CGFloat = 1320
    /// Centered reading column for settings / stats on every platform.
    static let settingsReadableMaxWidth: CGFloat = 680
    /// Centered column for reference scroll content.
    static let referenceReadableMaxWidth: CGFloat = 860
    /// Centered column for vocab flashcards.
    static let vocabReadableMaxWidth: CGFloat = 760

    // Practice sidebar / quiz pane spacing on macOS: see `MacStudiumDesign`.

    /// Readable max width for quiz question column from the measured pane width (split or full-width).
    static func quizQuestionColumnMaxWidth(paneWidth: CGFloat) -> CGFloat {
        guard paneWidth > 0 else { return 680 }
        let usable = paneWidth - 32
        return max(280, min(920, usable))
    }
}

// MARK: - Viewport width (Practice home, etc.)

struct ViewportWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}

// MARK: - Quiz detail pane width (macOS split / single column)

struct QuizDetailPaneWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}

extension View {
    /// Reports the view’s bounds width upward via preference (use on a view that fills the window width).
    func trackViewportWidth(_ width: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: ViewportWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(ViewportWidthKey.self) { w in
            if w > 0 { width.wrappedValue = w }
        }
    }

    /// Measures this view’s width (e.g. a `ScrollView` filling a split pane) for quiz column sizing.
    func trackQuizDetailPaneWidth(_ width: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: QuizDetailPaneWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(QuizDetailPaneWidthKey.self) { w in
            if w > 0 { width.wrappedValue = w }
        }
    }

    /// Centers content with a maximum width (macOS and iPad regular benefit most).
    func readableContentFrame(maxWidth: CGFloat, alignment: Alignment = .center) -> some View {
        frame(maxWidth: maxWidth, alignment: alignment)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}
