//
//  FilterControls.swift
//  Studium
//

import SwiftUI

// MARK: - Panel chrome

enum FilterPanelMetrics {
    static let formCardCorner: CGFloat = 12
    static let mainPanelCorner: CGFloat = 14
    static let formPadding: CGFloat = 12
    /// Wide enough for title + play/trash icon column.
    static let continueCardWidth: CGFloat = 216
    static let continueCardHeight: CGFloat = 140
}

/// Uppercase strip title (Continue, Filters, …).
struct FilterStripSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Section headings (matches Practice filter groups)

struct FilterGroupHeading: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .labelStyle(.titleAndIcon)
            .tint(tint)
    }
}

/// Small gray label above a chip row (e.g. "Module", "Skill").
struct FilterSubgroupLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
    }
}

struct FilterGroupBlock<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            FilterGroupHeading(title: title, systemImage: systemImage, tint: tint)
            content()
        }
    }
}

/// Grouped card used across Filter sheet sections (and can wrap practice-style blocks).
struct FilterFormCard<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(FilterPanelMetrics.formPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.formCardCorner))
    }
}

// MARK: - Chips

struct FilterChipButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let isSelected: Bool
    let accent: Color
    /// Full width inside LazyVGrid rows; intrinsic width in horizontal chip strips.
    var fillsGridCell: Bool = false
    var maxTextWidth: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if fillsGridCell {
                    chipText.frame(maxWidth: .infinity, minHeight: 32, alignment: .center)
                } else if let maxTextWidth {
                    chipText.frame(maxWidth: maxTextWidth, minHeight: 32, alignment: .center)
                } else {
                    chipText.frame(minHeight: 32, alignment: .center)
                }
            }
            .padding(.horizontal, fillsGridCell ? 8 : 12)
            .padding(.vertical, 6)
            .background(FilterStyle.chipFill(selected: isSelected, accent: accent, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: FilterStyle.chipCorner))
            .overlay(
                RoundedRectangle(cornerRadius: FilterStyle.chipCorner)
                    .strokeBorder(
                        FilterStyle.chipBorder(selected: isSelected, accent: accent),
                        lineWidth: FilterStyle.chipStrokeWidth
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var chipText: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .lineLimit(fillsGridCell ? 4 : 2)
            .minimumScaleFactor(0.82)
    }
}

/// Read-only chip for badges (quiz meta, reference tags).
struct FilterBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let accent: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(FilterStyle.chipFill(selected: true, accent: accent, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: FilterStyle.chipCorner))
            .overlay(
                RoundedRectangle(cornerRadius: FilterStyle.chipCorner)
                    .strokeBorder(
                        FilterStyle.chipBorder(selected: true, accent: accent),
                        lineWidth: FilterStyle.chipStrokeWidth
                    )
            )
    }
}

// MARK: - Order choice pair (question order)

struct FilterOrderChoiceButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? tint : .secondary)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(FilterStyle.orderCardFill(selected: isSelected, accent: tint, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
            .overlay(
                RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                    .strokeBorder(
                        FilterStyle.chipBorder(selected: isSelected, accent: tint),
                        lineWidth: FilterStyle.chipStrokeWidth
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Continue / saved quiz strip

struct ContinueSavedQuizCard: View {
    let title: String
    let answered: Int
    let total: Int
    let onPlay: () -> Void
    let onDelete: () -> Void

    private var progress: Double {
        total > 0 ? Double(answered) / Double(total) : 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.88)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)

                ProgressView(value: progress)
                    .tint(Color.accentColor)

                Text("\(answered)/\(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onTapGesture { onPlay() }

            VStack(spacing: 2) {
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Resume quiz")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body.weight(.medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color(.systemRed))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete saved quiz")
            }
        }
        .padding(10)
        .frame(width: FilterPanelMetrics.continueCardWidth, height: FilterPanelMetrics.continueCardHeight, alignment: .topLeading)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                .strokeBorder(FilterStyle.chipBorder(selected: false, accent: .blue), lineWidth: FilterStyle.chipStrokeWidth)
        )
    }
}
