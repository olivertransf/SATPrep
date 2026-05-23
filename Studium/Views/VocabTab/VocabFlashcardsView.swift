//
//  VocabFlashcardsView.swift
//  Studium
//

import Combine
import SwiftUI

private enum VocabDeckKind: String, CaseIterable {
    case words = "Words"
    case roots = "Roots"
}

private enum WordSetFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case noun = "Nouns"
    case verb = "Verbs"
    case adjective = "Adjectives"
    case adverb = "Adverbs"
    case other = "Other"

    var id: String { rawValue }

    func matches(posKey: String) -> Bool {
        switch self {
        case .all: true
        case .noun: posKey == "noun"
        case .verb: posKey == "verb"
        case .adjective: posKey == "adj"
        case .adverb: posKey == "adverb"
        case .other: posKey == "other"
        }
    }
}

struct VocabFlashcardsView: View {
    @ObservedObject private var store = VocabFlashcardStore.shared
    @ObservedObject private var buckets = VocabBucketStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var deckKind: VocabDeckKind = .words
    @State private var studyBucket: VocabMemoryBucket = .learn
    @State private var wordSetFilter: WordSetFilter = .all
    @State private var position: Int = 0
    @State private var isFlipped = false
    @State private var manualOrder: [Int]? = nil

    private let accent = Color.accentColor

    private var isWide: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    var body: some View {
        Group {
            if let err = store.loadError {
                ContentUnavailableView(
                    "Couldn't load flashcards",
                    systemImage: "exclamationmark.triangle",
                    description: Text(err.localizedDescription)
                )
            } else {
                if isWide {
                    wideLayout
                } else {
                    narrowLayout
                }
            }
        }
        .navigationTitle("Vocab")
        .navLargeTitle()
        .onAppear {
            restorePosition()
            validateManualOrder()
            clampPosition()
        }
        .onChange(of: deckKind) { _, _ in
            manualOrder = nil
            restorePosition()
            clampPosition()
            isFlipped = false
        }
        .onChange(of: studyBucket) { _, _ in
            manualOrder = nil
            restorePosition()
            clampPosition()
            isFlipped = false
        }
        .onChange(of: wordSetFilter) { _, _ in
            guard deckKind == .words else { return }
            manualOrder = nil
            restorePosition()
            clampPosition()
            isFlipped = false
        }
        .onChange(of: store.words.count) { _, _ in
            manualOrder = nil
            clampPosition()
        }
        .onChange(of: store.roots.count) { _, _ in
            manualOrder = nil
            clampPosition()
        }
        .onReceive(buckets.objectWillChange) { _ in
            validateManualOrder()
            clampPosition()
        }
        .onKeyPress(.leftArrow)  { goToPrevious(); return .handled }
        .onKeyPress(.rightArrow) { goToNext();     return .handled }
        .onKeyPress(.space) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { isFlipped.toggle() }
            return .handled
        }
    }

    // MARK: - Wide layout (iPad regular / macOS)

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left sidebar: deck controls + filters
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    deckPickerSection
                    studyPileSection
                    if deckKind == .words { wordTypeSection }
                    shuffleButton
                }
                .padding(20)
            }
            .frame(width: 240)
            .background(Color.secondarySystemGroupedBackground)

            Divider()

            // Right main: card + sort + nav
            if rowIndices.isEmpty {
                emptyDeckView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        progressAndCardSection
                        sortSection
                        navButtons
                    }
                    .padding(24)
                    .readableContentFrame(maxWidth: 680)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.systemGroupedBackground)
            }
        }
        .background(Color.systemGroupedBackground)
    }

    // MARK: - Narrow layout (iPhone)

    private var narrowLayout: some View {
        Group {
            if rowIndices.isEmpty {
                emptyDeckView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        deckPickerSection
                        studyPileSection
                        if deckKind == .words { wordTypeSection }
                        progressAndCardSection
                        sortSection
                        navButtons
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .readableContentFrame(maxWidth: LayoutMetrics.vocabReadableMaxWidth)
                }
                .background(Color.systemGroupedBackground)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { shuffleDeck() } label: {
                            Label("Shuffle", systemImage: "shuffle")
                        }
                        .disabled(baseFilteredIndices.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Section components

    private var deckPickerSection: some View {
        Picker("Deck", selection: $deckKind) {
            ForEach(VocabDeckKind.allCases, id: \.self) { k in
                Text(k.rawValue).tag(k)
            }
        }
        .pickerStyle(.segmented)
    }

    private var studyPileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Study pile")
            FilterFormCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                    ForEach(VocabMemoryBucket.allCases) { b in
                        FilterChipButton(
                            title: b.title,
                            isSelected: studyBucket == b,
                            accent: accent,
                            fillsGridCell: true
                        ) { studyBucket = b }
                    }
                }
            }
        }
    }

    private var wordTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Word type")
            FilterFormCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(WordSetFilter.allCases) { f in
                        FilterChipButton(
                            title: f.rawValue,
                            isSelected: wordSetFilter == f,
                            accent: accent,
                            fillsGridCell: true
                        ) { wordSetFilter = f }
                    }
                }
            }
        }
    }

    private var shuffleButton: some View {
        Button { shuffleDeck() } label: {
            Label("Shuffle", systemImage: "shuffle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(baseFilteredIndices.isEmpty)
    }

    private var progressAndCardSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(progressLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Space or tap to flip")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
            } label: {
                currentCardFace
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isWide ? 380 : 280)
                    .padding(24)
                    .background(Color.secondarySystemGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
                    .overlay(
                        RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                            .strokeBorder(FilterStyle.chipBorder(selected: false, accent: accent), lineWidth: FilterStyle.chipStrokeWidth)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var sortSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Sort this card")
            FilterFormCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 10) {
                    ForEach(VocabMemoryBucket.allCases) { b in
                        FilterChipButton(
                            title: b.title,
                            isSelected: currentCardBucket == b,
                            accent: accent,
                            fillsGridCell: true
                        ) { moveCurrentCard(to: b) }
                    }
                }
            }
        }
    }

    private var navButtons: some View {
        HStack(spacing: 12) {
            Button { goToPrevious() } label: {
                Label("Previous", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!canGoBack)

            Button { goToNext() } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.titleAndIcon)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(accent)
            .disabled(!canGoForward)
        }
    }

    private var emptyDeckView: some View {
        ContentUnavailableView(
            "No cards here",
            systemImage: "rectangle.on.rectangle",
            description: Text(emptyDeckHint)
        )
    }

    private var emptyDeckHint: String {
        switch deckKind {
        case .words:
            "Try another part-of-speech set, switch Learn / Review / Known, or sort cards from another pile."
        case .roots:
            "Switch Learn / Review / Known, or classify roots from another pile."
        }
    }

    // MARK: - Card faces

    private var progressLabel: String {
        let n = rowIndices.count
        let shown = n > 0 ? position + 1 : 0
        return "\(shown) / \(n)"
    }

    private var currentCardBucket: VocabMemoryBucket {
        guard position < rowIndices.count else { return .learn }
        let idx = rowIndices[position]
        switch deckKind {
        case .words: return buckets.wordBucket(for: store.words[idx].id)
        case .roots: return buckets.rootBucket(for: store.roots[idx].id)
        }
    }

    @ViewBuilder
    private var currentCardFace: some View {
        switch deckKind {
        case .words:
            let idx = rowIndices[position]
            wordCardView(store.words[idx])
        case .roots:
            let idx = rowIndices[position]
            rootCardView(store.roots[idx])
        }
    }

    @ViewBuilder
    private func wordCardView(_ card: VocabWordCard) -> some View {
        ZStack {
            wordFront(card)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
            wordBack(card)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
    }

    private func wordFront(_ card: VocabWordCard) -> some View {
        ZStack(alignment: .top) {
            Text(card.word)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack(alignment: .top) {
                Text("WORD")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                FilterBadge(text: partOfSpeechLabel(card.posKey), accent: accent.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func partOfSpeechLabel(_ key: String) -> String {
        switch key {
        case "noun": return "Noun"
        case "verb": return "Verb"
        case "adj": return "Adj"
        case "adverb": return "Adv"
        default: return "Other"
        }
    }

    private func wordBack(_ card: VocabWordCard) -> some View {
        ZStack(alignment: .top) {
            Text(card.definition)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack {
                Text("DEFINITION")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func rootCardView(_ card: VocabRootCard) -> some View {
        ZStack {
            rootFront(card)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
            rootBack(card)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
    }

    private func rootFront(_ card: VocabRootCard) -> some View {
        ZStack(alignment: .top) {
            Text(card.root)
                .font(.largeTitle.weight(.bold))
                .monospaced()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack(alignment: .top) {
                Text("ROOT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                FilterBadge(text: card.origin, accent: accent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rootBack(_ card: VocabRootCard) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 12) {
                Text(card.meaning)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                if !card.examples.isEmpty {
                    Divider()
                    Text("EXAMPLE WORDS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 4) {
                        ForEach(card.examples, id: \.self) { ex in
                            Text(ex)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            HStack {
                Text("MEANING")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Index helpers

    private var baseFilteredIndices: [Int] {
        switch deckKind {
        case .words:
            return store.words.indices.filter { idx in
                let w = store.words[idx]
                guard wordSetFilter.matches(posKey: w.posKey) else { return false }
                return buckets.wordBucket(for: w.id) == studyBucket
            }
        case .roots:
            return store.roots.indices.filter { idx in
                buckets.rootBucket(for: store.roots[idx].id) == studyBucket
            }
        }
    }

    private var rowIndices: [Int] {
        let base = baseFilteredIndices.sorted()
        guard let m = manualOrder, Set(m) == Set(base) else { return base }
        return m
    }

    private var canGoBack: Bool { position > 0 }
    private var canGoForward: Bool { position + 1 < rowIndices.count }

    private var sessionStorageKey: String {
        switch deckKind {
        case .words: "vocab.pos.w.\(wordSetFilter.rawValue).\(studyBucket.rawValue)"
        case .roots: "vocab.pos.r.\(studyBucket.rawValue)"
        }
    }

    private func validateManualOrder() {
        let base = Set(baseFilteredIndices)
        if let m = manualOrder, Set(m) != base { manualOrder = nil }
    }

    private func shuffleDeck() {
        let base = baseFilteredIndices.sorted()
        manualOrder = base.shuffled()
        position = 0
        persistPosition()
        isFlipped = false
    }

    private func restorePosition() {
        let saved = UserDefaults.standard.integer(forKey: sessionStorageKey)
        position = max(0, min(saved, max(0, rowIndices.count - 1)))
    }

    private func persistPosition() {
        UserDefaults.standard.set(position, forKey: sessionStorageKey)
    }

    private func clampPosition() {
        if rowIndices.isEmpty { position = 0; return }
        if position >= rowIndices.count {
            position = max(0, rowIndices.count - 1)
            persistPosition()
        }
    }

    private func goToPrevious() {
        guard canGoBack else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isFlipped = false }
        position -= 1
        persistPosition()
    }

    private func goToNext() {
        guard canGoForward else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isFlipped = false }
        position += 1
        persistPosition()
    }

    private func moveCurrentCard(to bucket: VocabMemoryBucket) {
        guard position < rowIndices.count else { return }
        let idx = rowIndices[position]
        switch deckKind {
        case .words: buckets.setWordBucket(id: store.words[idx].id, to: bucket)
        case .roots: buckets.setRootBucket(id: store.roots[idx].id, to: bucket)
        }
        manualOrder = nil
        let newBase = baseFilteredIndices.sorted()
        position = min(position, max(0, newBase.count - 1))
        isFlipped = false
        persistPosition()
    }
}

#Preview {
    NavigationStack {
        VocabFlashcardsView()
    }
}
