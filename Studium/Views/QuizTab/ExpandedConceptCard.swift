//
//  ExpandedConceptCard.swift
//  Studium
//

import SwiftUI

struct ExpandedConceptCard: View {
    let category: ConceptCategory
    var accentColor: Color = .accentColor
    let onPractice: () -> Void
    let onPracticeSkill: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: StudiumDesignSystem.spacingMD) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 40, height: 40)
                    .background(accentColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingXS) {
                    Text(category.id)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(StudiumDesignSystem.spacingLG)

            Divider()

            VStack(spacing: 0) {
                ForEach(category.skills) { skill in
                    Button { onPracticeSkill(skill.id) } label: {
                        HStack(spacing: StudiumDesignSystem.spacingMD) {
                            Text(skill.id)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(skill.count)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, StudiumDesignSystem.spacingLG)
                        .padding(.vertical, StudiumDesignSystem.spacingMD)
                        .frame(minHeight: StudiumDesignSystem.minTapTarget, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if skill.id != category.skills.last?.id {
                        Divider().padding(.leading, StudiumDesignSystem.spacingLG)
                    }
                }
            }

            Divider()

            Button(action: onPractice) {
                Label("Practice category", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(StudiumDesignSystem.primaryCTAControlSize)
            .padding(StudiumDesignSystem.spacingLG)
        }
        .studiumElevatedCard(padding: 0)
    }
}
