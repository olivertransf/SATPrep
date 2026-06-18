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

private struct FilterSidebarLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

private struct FilterPhoneSheetLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var filterPanelDensity: FilterPanelDensity {
        get { self[FilterPanelDensityKey.self] }
        set { self[FilterPanelDensityKey.self] = newValue }
    }

    /// Practice split-pane filter column (tighter chips, 2-column grid, roomier card).
    var filterSidebarLayout: Bool {
        get { self[FilterSidebarLayoutKey.self] }
        set { self[FilterSidebarLayoutKey.self] = newValue }
    }

    /// iPhone filter sheet — relaxed card padding and 2-column chips (not `.compact` density).
    var filterPhoneSheetLayout: Bool {
        get { self[FilterPhoneSheetLayoutKey.self] }
        set { self[FilterPhoneSheetLayoutKey.self] = newValue }
    }
}

// MARK: - Panel chrome

enum FilterPanelMetrics {
    static let formCardCorner: CGFloat = 12
    static let formCardCornerCompact: CGFloat = 10
    static let mainPanelCorner: CGFloat = 14
    static let formPadding: CGFloat = 12
    static let formPaddingCompact: CGFloat = 8

    /// Two equal columns for chip grids on narrow phone layouts.
    static var filterChipPairColumns: [GridItem] {
        filterChipGridColumns(columnCount: 2)
    }

    static let filterChipCardCorner: CGFloat = 10
    static let filterChipGridSpacing: CGFloat = 8
    static let sidebarChipGridSpacing: CGFloat = 10
    static let sidebarFormPadding: CGFloat = 16
    static let sidebarFormCorner: CGFloat = 14
    static let sidebarSectionSpacing: CGFloat = 18
    static let phoneSheetFormPadding: CGFloat = 16
    static let phoneSheetFormCorner: CGFloat = 14
    static let phoneSheetSectionSpacing: CGFloat = 16
    static let phoneSheetChipGridSpacing: CGFloat = 10
    /// Minimum cell width when fitting 3–4 columns in a filter panel.
    static let filterChipMinCellWidth: CGFloat = 84

    static var sidebarChipColumns: [GridItem] {
        filterChipGridColumns(columnCount: 2)
    }

    static func filterChipGridColumns(columnCount: Int) -> [GridItem] {
        let count = min(4, max(2, columnCount))
        return Array(repeating: GridItem(.flexible(), spacing: filterChipGridSpacing), count: count)
    }

    /// Picks 2–4 columns from available width (sidebar or sheet).
    static func filterChipGridColumns(forWidth width: CGFloat, maxColumns: Int = 4) -> [GridItem] {
        let spacing = filterChipGridSpacing
        let cell = filterChipMinCellWidth
        let count = min(maxColumns, max(2, Int((width + spacing) / (cell + spacing))))
        return filterChipGridColumns(columnCount: count)
    }
}

/// Uppercase strip title (Continue, Filters, …).
struct FilterStripSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudiumDesignSystem.sectionEyebrow)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Section headings (matches Practice filter groups)

struct FilterGroupHeading: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity
    @Environment(\.filterSidebarLayout) private var filterSidebarLayout
    @Environment(\.filterPhoneSheetLayout) private var filterPhoneSheetLayout

    let title: String
    let systemImage: String
    let tint: Color

    private var usesRelaxedFilterLayout: Bool { filterSidebarLayout || filterPhoneSheetLayout }

    private var titleFont: Font {
        if usesRelaxedFilterLayout { return .subheadline.weight(.semibold) }
        if filterPanelDensity == .compact { return .subheadline.weight(.semibold) }
        return StudiumDesignSystem.sidebarGroupTitle
    }

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(titleFont)
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
    @Environment(\.filterSidebarLayout) private var filterSidebarLayout
    @Environment(\.filterPhoneSheetLayout) private var filterPhoneSheetLayout

    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: () -> Content

    private var headingToContentSpacing: CGFloat {
        if filterSidebarLayout || filterPhoneSheetLayout { return StudiumDesignSystem.spacingSM }
        return filterPanelDensity == .compact ? 3 : 5
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.filterPanelDensity) private var filterPanelDensity
    @Environment(\.filterSidebarLayout) private var filterSidebarLayout
    @Environment(\.filterPhoneSheetLayout) private var filterPhoneSheetLayout

    var spacing: CGFloat = 8
    @ViewBuilder let content: () -> Content

    private var usesRelaxedFilterLayout: Bool { filterSidebarLayout || filterPhoneSheetLayout }

    private var cardPadding: CGFloat {
        if filterSidebarLayout { return FilterPanelMetrics.sidebarFormPadding }
        if filterPhoneSheetLayout { return FilterPanelMetrics.phoneSheetFormPadding }
        return filterPanelDensity == .compact ? FilterPanelMetrics.formPaddingCompact : FilterPanelMetrics.formPadding
    }

    private var cardCorner: CGFloat {
        if filterSidebarLayout { return FilterPanelMetrics.sidebarFormCorner }
        if filterPhoneSheetLayout { return FilterPanelMetrics.phoneSheetFormCorner }
        return filterPanelDensity == .compact ? FilterPanelMetrics.formCardCornerCompact : FilterPanelMetrics.formCardCorner
    }

    private var resolvedSpacing: CGFloat {
        if filterSidebarLayout { return FilterPanelMetrics.sidebarSectionSpacing }
        if filterPhoneSheetLayout { return FilterPanelMetrics.phoneSheetSectionSpacing }
        return spacing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: resolvedSpacing) {
            content()
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .strokeBorder(Color.studiumSeparator.opacity(colorScheme == .dark ? 0.55 : 0.85), lineWidth: 0.5)
        )
        .shadow(
            color: usesRelaxedFilterLayout ? FilterStyle.elevatedShadowColor(colorScheme: colorScheme) : .clear,
            radius: 3,
            y: 1
        )
    }
}

// MARK: - Chips

struct FilterChipButton: View {
    @Environment(\.filterPanelDensity) private var filterPanelDensity
    @Environment(\.filterSidebarLayout) private var filterSidebarLayout
    @Environment(\.filterPhoneSheetLayout) private var filterPhoneSheetLayout

    let title: String
    let isSelected: Bool
    let accent: Color
    /// Full width inside LazyVGrid rows; intrinsic width in horizontal chip strips.
    var fillsGridCell: Bool = false
    var maxTextWidth: CGFloat? = nil
    let action: () -> Void

    private var isCompact: Bool { filterPanelDensity == .compact }
    private var hPad: CGFloat {
        if fillsGridCell {
            if filterSidebarLayout || filterPhoneSheetLayout { return StudiumDesignSystem.spacingSM }
            return isCompact ? 6 : StudiumDesignSystem.filterChipHPadding
        }
        return isCompact ? 8 : 10
    }
    private var vPad: CGFloat {
        if fillsGridCell {
            if filterSidebarLayout { return 9 }
            if filterPhoneSheetLayout { return StudiumDesignSystem.spacingSM }
            return isCompact ? 8 : StudiumDesignSystem.filterChipVPadding
        }
        return isCompact ? 4 : 5
    }
    private var chipFont: Font {
        if fillsGridCell && (filterSidebarLayout || filterPhoneSheetLayout) {
            return .footnote.weight(.semibold)
        }
        return fillsGridCell ? .footnote.weight(.semibold) : .caption.weight(.semibold)
    }
    private var gridMinHeight: CGFloat {
        guard fillsGridCell else { return 0 }
        if filterSidebarLayout { return StudiumDesignSystem.filterSidebarChipMinHeight }
        if filterPhoneSheetLayout { return StudiumDesignSystem.filterSidebarChipMinHeight }
        return StudiumDesignSystem.filterChipMinHeight
    }

    var body: some View {
        Button(action: action) {
            Group {
                if fillsGridCell {
                    chipLabel
                        .padding(.horizontal, hPad)
                        .padding(.vertical, vPad)
                        .frame(maxWidth: .infinity, minHeight: gridMinHeight)
                } else {
                    chipLabel
                        .padding(.horizontal, hPad)
                        .padding(.vertical, vPad)
                }
            }
            .background(isSelected ? accent : Color.systemBackground)
            .clipShape(chipShape)
            .overlay(chipShape.strokeBorder(
                isSelected ? accent : Color.studiumBorder,
                lineWidth: FilterStyle.chipStrokeWidth
            ))
        }
        .buttonStyle(.plain)
    }

    private var chipShape: RoundedRectangle {
        if fillsGridCell {
            RoundedRectangle(cornerRadius: FilterPanelMetrics.filterChipCardCorner, style: .continuous)
        } else {
            RoundedRectangle(cornerRadius: 999, style: .continuous)
        }
    }

    @ViewBuilder
    private var chipLabel: some View {
        let text = Text(title)
            .font(chipFont)
            .multilineTextAlignment(.center)
            .foregroundStyle(isSelected ? Color.white : (fillsGridCell ? Color.primary : Color.secondary))
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
        let base = StudiumDesignSystem.orderChoiceMinHeight
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
            .padding(.horizontal, max(8, StudiumDesignSystem.orderChoicePaddingH - (isCompact ? 2 : 0)))
            .padding(.vertical, max(6, StudiumDesignSystem.orderChoicePaddingV - (isCompact ? 2 : 0)))
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
    let tags: [String]
    let answered: Int
    let total: Int
    let onPlay: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var progress: Double {
        total > 0 ? Double(answered) / Double(total) : 0
    }

    private var title: String {
        guard let firstTag = tags.first else { return "Practice set" }
        if firstTag == "All Questions" { return "All practice" }
        return firstTag
    }

    private var subtitle: String {
        let detailTags = Array(tags.dropFirst())
        if detailTags.isEmpty { return "Mixed SAT practice" }
        return detailTags.prefix(2).joined(separator: " · ")
    }

    private var supportingTags: [String] {
        Array(tags.dropFirst(3).prefix(3))
    }

    private var titleIcon: String {
        title == "Math" ? "function" : (title == "Reading & Writing" ? "text.book.closed" : "square.grid.2x2")
    }

    private var tint: Color {
        title == "Reading & Writing" ? .studiumSectionRW : .accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            HStack(alignment: .center, spacing: StudiumDesignSystem.spacingMD) {
                StudiumIconBadge(systemImage: titleIcon, tint: tint, size: 38, cornerRadius: 10)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    showDeleteConfirm = true
                }

                Spacer(minLength: 0)

                resumeButton
            }

            if !supportingTags.isEmpty {
                tagRow
            }

            ProgressView(value: progress)
                .tint(tint)
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
        .studiumElevatedCard(padding: StudiumDesignSystem.spacingMD, showsShadow: false)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete this saved quiz?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Swipe left or long press details to delete")
    }

    private var resumeButton: some View {
        Button(action: onPlay) {
            Text("Resume")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 2)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(StudiumDesignSystem.primaryCTAControlSize)
        .fixedSize()
    }

    private var tagRow: some View {
        HStack(spacing: 6) {
            ForEach(supportingTags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            showDeleteConfirm = true
        }
    }
}
