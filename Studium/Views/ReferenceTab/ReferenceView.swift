//
//  ReferenceView.swift
//  Studium
//

import SwiftUI

struct ReferenceView: View {
    @State private var selectedSubject = 0
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
    @State private var viewportWidth: CGFloat = 0

    private var isTwoColumn: Bool { viewportWidth >= 700 }

    private var currentSections: [ReferenceSection] {
        selectedSubject == 0 ? ReferenceSection.mathSections : ReferenceSection.rwSections
    }

    private func filtered(_ sections: [ReferenceSection]) -> [ReferenceSection] {
        guard !searchText.isEmpty else { return sections }
        return sections.compactMap { section in
            let hits = section.entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText)
                || (entry.formula?.localizedCaseInsensitiveContains(searchText) ?? false)
                || (entry.detail?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            guard !hits.isEmpty else { return nil }
            return ReferenceSection(title: section.title, icon: section.icon, color: section.color, entries: hits)
        }
    }

    private var filteredSections: [ReferenceSection] { filtered(currentSections) }
    private var filteredMathSections: [ReferenceSection] { filtered(ReferenceSection.mathSections) }
    private var filteredRWSections: [ReferenceSection] { filtered(ReferenceSection.rwSections) }

    var body: some View {
        NavigationStack {
            referenceMainScrollLayout
        }
        .navigationTitle("Reference")
        .navLargeTitle()
        .trackViewportWidth($viewportWidth)
        .onChange(of: searchText) { _, new in
            if !new.isEmpty {
                var t = Transaction()
                t.animation = nil
                withTransaction(t) {
                    if isTwoColumn {
                        expandedSections = Set(
                            (filteredMathSections + filteredRWSections).map(\.id)
                        )
                    } else {
                        expandedSections = Set(filteredSections.map(\.id))
                    }
                }
            }
        }
    }

    /// In-column search (same width as list/cards). `.searchable` on the tab often pins to the sidebar on iPad.
    private var referenceSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
            TextField("Search formulas and rules…", text: $searchText)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.secondary.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search formulas and rules")
    }

    /// Chip strip + search + card accordion (shared on iOS, iPad, and macOS).
    private var referenceMainScrollLayout: some View {
        VStack(spacing: 0) {
            if !isTwoColumn {
                subjectChipStrip
                    .padding(.horizontal, referenceChipStripHorizontalPadding)
                    .padding(.vertical, referenceChipStripVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondarySystemGroupedBackground)
                    .onChange(of: selectedSubject) { _, _ in expandedSections.removeAll() }
            }

            referenceSearchBar
                .padding(.horizontal, referenceChipStripHorizontalPadding)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondarySystemGroupedBackground)

            if isTwoColumn {
                twoColumnScrollLayout
            } else {
                singleColumnScrollLayout
            }
        }
    }

    private var singleColumnScrollLayout: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredSections) { section in
                    sectionCard(section)
                }
                if filteredSections.isEmpty {
                    ContentUnavailableView {
                        Label("No matches", systemImage: "magnifyingglass")
                    } description: {
                        Text(searchText.isEmpty ? "Choose Math or Reading & Writing." : "Nothing matches \"\(searchText)\".")
                    }
                    .padding(.top, 24)
                }
            }
            .padding(referenceListOuterPadding)
            .readableContentFrame(maxWidth: LayoutMetrics.referenceReadableMaxWidth, alignment: .leading)
        }
        .background(Color.systemGroupedBackground)
    }

    private var twoColumnScrollLayout: some View {
        ScrollView {
            HStack(alignment: .top, spacing: referenceListOuterPadding) {
                referenceColumn(
                    title: "Math",
                    icon: "function",
                    sections: filteredMathSections
                )
                referenceColumn(
                    title: "Reading & Writing",
                    icon: "text.alignleft",
                    sections: filteredRWSections
                )
            }
            .padding(referenceListOuterPadding)
        }
        .background(Color.systemGroupedBackground)
    }

    private func referenceColumn(title: String, icon: String, sections: [ReferenceSection]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.bottom, 2)
            if sections.isEmpty {
                ContentUnavailableView {
                    Label("No matches", systemImage: "magnifyingglass")
                } description: {
                    Text("Nothing matches \"\(searchText)\".")
                }
                .padding(.top, 24)
            } else {
                ForEach(sections) { section in
                    sectionCard(section)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func sectionCard(_ section: ReferenceSection) -> some View {
        ReferenceSectionCard(
            section: section,
            isExpanded: expandedSections.contains(section.id),
            onToggle: {
                withAnimation(.easeOut(duration: 0.2)) {
                    if expandedSections.contains(section.id) {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            }
        )
    }

    private var referenceChipStripHorizontalPadding: CGFloat {
        StudiumDesignSystem.practiceMainPaddingH
    }

    private var referenceChipStripVerticalPadding: CGFloat { 12 }

    private var referenceListOuterPadding: CGFloat {
        StudiumDesignSystem.practiceMainPaddingH
    }

    private var subjectChipStrip: some View {
        HStack(spacing: 8) {
            FilterChipButton(title: "Math", isSelected: selectedSubject == 0, accent: .blue, fillsGridCell: true) {
                selectedSubject = 0
            }
            FilterChipButton(title: "Reading & Writing", isSelected: selectedSubject == 1, accent: .blue, fillsGridCell: true) {
                selectedSubject = 1
            }
        }
    }
}
