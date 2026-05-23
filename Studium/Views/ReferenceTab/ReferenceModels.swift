//
//  ReferenceModels.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

// MARK: - Data Models

struct ReferenceEntry: Identifiable {
    /// Stable within a section (used for lists / webview identity).
    var id: String { title }
    let title: String
    /// Plain-text fallback (shown when latex is nil, or used for accessibility / code readability)
    let formula: String?
    /// Full HTML fragment containing LaTeX delimited with \[…\] for rendered display
    let latex: String?
    let detail: String?
    let tag: EntryTag?

    enum EntryTag: String {
        case provided = "On Test"
        case memorize = "Memorize"
        case rule     = "Rule"
        case tip      = "Strategy"
    }

    init(_ title: String, formula: String? = nil, latex: String? = nil, detail: String? = nil, tag: EntryTag? = nil) {
        self.title   = title
        self.formula = formula
        self.latex   = latex
        self.detail  = detail
        self.tag     = tag
    }
}

struct ReferenceSection: Identifiable {
    /// Stable across search rebuilds so expansion / selection don’t reset every keystroke.
    var id: String { title }
    let title: String
    let icon: String
    let color: Color
    let entries: [ReferenceEntry]
}

// MARK: - Math Formula View

/// Renders a LaTeX fragment using the existing HTMLContentView (MathJax pipeline).
struct MathFormulaView: View {
    let latex: String       // e.g. "\\[ A = \\pi r^2 \\]"
    let accentColor: Color

    var body: some View {
        HTMLContentView(
            htmlContent: latex,
            isScrollable: false,
            allowInteraction: false
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(StudiumDesignSystem.spacingSM)
        .background(Color.tertiarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
