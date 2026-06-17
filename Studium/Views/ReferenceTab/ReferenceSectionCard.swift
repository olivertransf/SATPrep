//
//  ReferenceSectionCard.swift
//  Studium
//

import SwiftUI

struct ReferenceSectionCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let section: ReferenceSection
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.subheadline)
                        .foregroundStyle(section.color)
                        .frame(width: 30, height: 30)
                        .background(FilterStyle.iconBadgeFill(tint: section.color, colorScheme: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(section.entries.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.tertiarySystemFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(StudiumDesignSystem.spacingMD + 2)
                .frame(minHeight: StudiumDesignSystem.minTapTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(section.title), \(section.entries.count) entries")
            .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")

            if isExpanded {
                Divider().padding(.horizontal, 14)
                ForEach(section.entries) { entry in
                    ReferenceEntryRow(entry: entry, accentColor: section.color)
                    if entry.id != section.entries.last?.id {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
        }
        .studiumElevatedCard(padding: 0, cornerRadius: StudiumDesignSystem.radiusCard)
    }
}
