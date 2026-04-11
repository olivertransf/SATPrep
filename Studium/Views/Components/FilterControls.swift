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
    static let continueCardWidth: CGFloat = 320
    /// Minimum height so title + progress + Resume / Delete row is not clipped.
    static let continueCardMinHeight: CGFloat = 256
}

/// Uppercase strip title (Continue, Filters, …).
struct FilterStripSectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font({
                #if os(macOS)
                MacStudiumDesign.sectionEyebrow
                #else
                Font.footnote.weight(.semibold)
                #endif
            }())
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
            .font({
                #if os(macOS)
                MacStudiumDesign.sidebarGroupTitle
                #else
                Font.subheadline.weight(.semibold)
                #endif
            }())
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
        .background(Color.secondarySystemGroupedBackground)
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

    private var chipMinHeight: CGFloat {
        #if os(macOS)
        MacStudiumDesign.filterChipMinHeight
        #else
        36
        #endif
    }

    var body: some View {
        Button(action: action) {
            Group {
                if fillsGridCell {
                    chipText.frame(maxWidth: .infinity, minHeight: chipMinHeight, alignment: .center)
                } else if let maxTextWidth {
                    chipText.frame(maxWidth: maxTextWidth, minHeight: chipMinHeight, alignment: .center)
                } else {
                    chipText.frame(minHeight: chipMinHeight, alignment: .center)
                }
            }
            .padding(.horizontal, {
                #if os(macOS)
                fillsGridCell ? MacStudiumDesign.filterChipHPadding : 14
                #else
                fillsGridCell ? 8 : 12
                #endif
            }())
            .padding(.vertical, {
                #if os(macOS)
                MacStudiumDesign.filterChipVPadding
                #else
                6
                #endif
            }())
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
            .font({
                #if os(macOS)
                Font.body.weight(.medium)
                #else
                Font.subheadline.weight(.medium)
                #endif
            }())
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .lineLimit(fillsGridCell ? 4 : 2)
            .minimumScaleFactor(0.88)
    }
}

/// Read-only chip for badges (quiz meta, reference tags).
struct FilterBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let accent: Color

    var body: some View {
        Text(text)
            .font({
                #if os(macOS)
                Font.subheadline.weight(.medium)
                #else
                Font.caption.weight(.medium)
                #endif
            }())
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, {
                #if os(macOS)
                12
                #else
                10
                #endif
            }())
            .padding(.vertical, {
                #if os(macOS)
                6
                #else
                5
                #endif
            }())
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font({
                            #if os(macOS)
                            Font.subheadline.weight(.semibold)
                            #else
                            Font.caption.weight(.semibold)
                            #endif
                        }())
                        .foregroundStyle(isSelected ? tint : .secondary)
                    Text(title)
                        .font({
                            #if os(macOS)
                            Font.subheadline.weight(.semibold)
                            #else
                            Font.caption.weight(.semibold)
                            #endif
                        }())
                        .foregroundStyle(.primary)
                }
                Text(subtitle)
                    .font({
                        #if os(macOS)
                        Font.caption.weight(.medium)
                        #else
                        Font.caption2
                        #endif
                    }())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: {
                #if os(macOS)
                MacStudiumDesign.orderChoiceMinHeight
                #else
                50
                #endif
            }(), alignment: .leading)
            .padding(.horizontal, {
                #if os(macOS)
                MacStudiumDesign.orderChoicePaddingH
                #else
                10
                #endif
            }())
            .padding(.vertical, {
                #if os(macOS)
                MacStudiumDesign.orderChoicePaddingV
                #else
                8
                #endif
            }())
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
        VStack(alignment: .leading, spacing: {
            #if os(macOS)
            MacStudiumDesign.continueCardSpacing
            #else
            12
            #endif
        }()) {
            Text(title)
                .font({
                    #if os(macOS)
                    MacStudiumDesign.continueCardTitle
                    #else
                    Font.title3.weight(.semibold)
                    #endif
                }())
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
                    #if os(macOS)
                    .controlSize(.regular)
                    #else
                    .controlSize(.small)
                    #endif
                Text("\(answered) of \(total) answered")
                    .font({
                        #if os(macOS)
                        MacStudiumDesign.continueCardMeta
                        #else
                        Font.body
                        #endif
                    }())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { onPlay() }

            HStack(spacing: 10) {
                Button(action: onPlay) {
                    Label("Resume", systemImage: "play.fill")
                        .font({
                            #if os(macOS)
                            Font.headline.weight(.semibold)
                            #else
                            Font.body.weight(.semibold)
                            #endif
                        }())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                #if os(macOS)
                .controlSize(.large)
                #endif

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Delete saved quiz")
            }
        }
        .padding({
            #if os(macOS)
            MacStudiumDesign.continueCardPadding
            #else
            18
            #endif
        }())
        #if os(macOS)
        .frame(width: MacStudiumDesign.continueCardWidth, alignment: .topLeading)
        #else
        .frame(width: FilterPanelMetrics.continueCardWidth, alignment: .topLeading)
        .frame(minHeight: FilterPanelMetrics.continueCardMinHeight, alignment: .topLeading)
        #endif
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                .strokeBorder(FilterStyle.chipBorder(selected: false, accent: .blue), lineWidth: FilterStyle.chipStrokeWidth)
        )
    }
}
