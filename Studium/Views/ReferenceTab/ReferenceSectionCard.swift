//
//  ReferenceSectionCard.swift
//  Studium
//

import SwiftUI

struct ReferenceSectionCard: View {
    let section: ReferenceSection
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.subheadline)
                        .foregroundColor(section.color)
                        .frame(width: 30, height: 30)
                        .background(section.color.opacity(0.12))
                        .cornerRadius(8)

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(section.entries.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.systemGray5)
                        .cornerRadius(8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
