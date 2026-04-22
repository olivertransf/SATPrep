//
//  FilterControls.swift
//  Studium
//

import SwiftUI

// MARK: - Density (Practice sidebar + filter sheet share compact “web” layout)

enum FilterPanelDensity: Hashable {
    case standard
    case compact
}

private struct FilterPanelDensityKey: EnvironmentKey {
    static let defaultValue: FilterPanelDensity = .standard
}

extension EnvironmentValues {
    var filterPanelDensity: FilterPanelDensity {
        get { self[FilterPanelDensityKey.self] }
        set { self[FilterPanelDensityKey.self] = newValue }
    }
}

// MARK: - Panel chrome

enum FilterPanelMetrics {
    static let formCardCorner: CGFloat = 12
    static let formCardCornerCompact: CGFloat = 10
    static let mainPanelCorner: CGFloat = 14
    static let formPadding: CGFloat = 12
    static let formPaddingCompact: CGFloat = 8

    /// Two equal columns for chip grids (difficulty, status, source rows).
    static var filterChipPairColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
    }
}

/// Uppercase strip title (Continue, Filters, …).
struct FilterStripSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(MacStudiumDesign.sectionEyebrow)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Section headings (matches Practice filter groups)

struct FilterGroupHeading: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity

    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(filterPanelDensity == .compact ? .subheadline.weight(.semibold) : MacStudiumDesign.sidebarGroupTitle)
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
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

struct FilterGroupBlock<Content: View>: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity

    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: () -> Content

    private var headingToContentSpacing: CGFloat {
        filterPanelDensity == .compact ? 3 : 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: headingToContentSpacing) {
            FilterGroupHeading(title: title, systemImage: systemImage, tint: tint)
            content()
        }
    }
}

/// Grouped card used across Filter sheet sections (and can wrap practice-style blocks).
struct FilterFormCard<Content: View>: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity

    var spacing: CGFloat = 8
    @ViewBuilder let content: () -> Content

    private var cardPadding: CGFloat {
        filterPanelDensity == .compact ? FilterPanelMetrics.formPaddingCompact : FilterPanelMetrics.formPadding
    }

    private var cardCorner: CGFloat {
        filterPanelDensity == .compact ? FilterPanelMetrics.formCardCornerCompact : FilterPanelMetrics.formCardCorner
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner))
    }
}

// MARK: - Chips

struct FilterChipButton: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity

    let title: String
    let isSelected: Bool
    let accent: Color
    /// Full width inside LazyVGrid rows; intrinsic width in horizontal chip strips.
    var fillsGridCell: Bool = false
    var maxTextWidth: CGFloat? = nil
    let action: () -> Void

    private var isCompact: Bool { filterPanelDensity == .compact }
    private var hPad: CGFloat { isCompact ? 8 : 10 }
    private var vPad: CGFloat { isCompact ? 4 : 5 }
    private var chipFont: Font { .caption.weight(.semibold) }

    var body: some View {
        Button(action: action) {
            chipLabel
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .background(isSelected ? accent : .clear)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(
                    isSelected ? accent : Color.studiumBorder,
                    lineWidth: FilterStyle.chipStrokeWidth
                ))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var chipLabel: some View {
        let text = Text(title)
            .font(chipFont)
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .lineLimit(fillsGridCell ? 4 : 2)
            .minimumScaleFactor(0.88)

        if fillsGridCell {
            text.frame(maxWidth: .infinity, alignment: .center)
        } else if let maxTextWidth {
            text.frame(maxWidth: maxTextWidth, alignment: .center)
        } else {
            text
        }
    }
}

/// Read-only chip for badges (quiz meta, reference tags).
struct FilterBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let accent: Color

    var body: some View {
        Text(text)
            .font(Font.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
    @Environment(\.filterPanelDensity) private var filterPanelDensity

    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    private var isCompact: Bool { filterPanelDensity == .compact }

    private var orderMinHeight: CGFloat {
        let base = MacStudiumDesign.orderChoiceMinHeight
        return isCompact ? max(40, base - 10) : base
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                HStack(spacing: 5) {
                    Image(systemName: systemImage)
                        .font(isCompact ? .caption.weight(.semibold) : Font.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? tint : .secondary)
                    Text(title)
                        .font(isCompact ? .caption.weight(.semibold) : Font.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Text(subtitle)
                    .font(isCompact ? .caption2.weight(.medium) : Font.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: orderMinHeight, alignment: .leading)
            .padding(.horizontal, max(8, MacStudiumDesign.orderChoicePaddingH - (isCompact ? 2 : 0)))
            .padding(.vertical, max(6, MacStudiumDesign.orderChoicePaddingV - (isCompact ? 2 : 0)))
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
        VStack(alignment: .leading, spacing: MacStudiumDesign.continueCardSpacing) {
            Text(title)
                .font(MacStudiumDesign.continueCardTitle)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture { onPlay() }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progress)
                    .tint(Color.accentColor)
                    .controlSize(.regular)
                Text("\(answered) of \(total) answered")
                    .font(MacStudiumDesign.continueCardMeta)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { onPlay() }

            HStack(spacing: 10) {
                Button(action: onPlay) {
                    Label("Resume", systemImage: "play.fill")
                        .font(MacStudiumDesign.continueResumeButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(MacStudiumDesign.primaryCTAControlSize)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Delete saved quiz")
            }
        }
        .padding(MacStudiumDesign.continueCardPadding)
        .frame(width: MacStudiumDesign.continueCardWidth, alignment: .topLeading)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                .strokeBorder(FilterStyle.chipBorder(selected: false, accent: .blue), lineWidth: FilterStyle.chipStrokeWidth)
        )
    }
}
