//
//  ReferenceEntryRow.swift
//  Studium
//

import SwiftUI

struct ReferenceEntryRow: View {
    let entry: ReferenceEntry
    let accentColor: Color

    @ViewBuilder
    private func referencePlainFormula(_ formula: String, accentColor: Color) -> some View {
        Text(formula)
            .font(.callout)
            .foregroundColor(accentColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .cornerRadius(10)
    }

    private var tagColor: Color {
        switch entry.tag {
        case .provided: return .green
        case .memorize: return .orange
        case .rule:     return .blue
        case .tip:      return .purple
        case .none:     return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let tag = entry.tag {
                    FilterBadge(text: tag.rawValue, accent: tagColor)
                }
            }

            // Apple platforms except macOS: prefer plain `formula` so Reference doesn’t spawn dozens of MathJax webviews.
            #if os(macOS)
            if let latex = entry.latex {
                MathFormulaView(latex: latex, accentColor: accentColor)
            } else if let formula = entry.formula {
                referencePlainFormula(formula, accentColor: accentColor)
            }
            #else
            if let latex = entry.latex, entry.formula == nil {
                MathFormulaView(latex: latex, accentColor: accentColor)
            } else if let formula = entry.formula {
                referencePlainFormula(formula, accentColor: accentColor)
            }
            #endif

            if let detail = entry.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, StudiumDesignSystem.spacingMD + 2)
        .padding(.vertical, StudiumDesignSystem.spacingMD)
    }
}
