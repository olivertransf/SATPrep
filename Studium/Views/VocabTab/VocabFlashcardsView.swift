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

    @State private var deckKind: VocabDeckKind = .words
    @State private var studyBucket: VocabMemoryBucket = .learn
    @State private var wordSetFilter: WordSetFilter = .all
    @State private var position: Int = 0
    @State private var isFlipped = false
    @State private var manualOrder: [Int]? = nil

    private let accent = Color.accentColor

    var body: some View {
        Group {
            if let err = store.loadError {
                ContentUnavailableView(
                    "Couldn’t load flashcards",
                    systemImage: "exclamationmark.triangle",
                    description: Text(err.localizedDescription)
                )
            } else if rowIndices.isEmpty {
                ContentUnavailableView(
                    "No cards here",
                    systemImage: "rectangle.on.rectangle",
                    description: Text(emptyDeckHint)
                )
            } else {
                flashcardContent
            }
        }
        .navigationTitle("Vocab")
        .navigationBarTitleDisplayMode(.large)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shuffleDeck()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .disabled(baseFilteredIndices.isEmpty)
            }
        }
    }

    private var emptyDeckHint: String {
        switch deckKind {
        case .words:
            "Try another part-of-speech set, switch Learn / Review / Known, or sort cards from another pile."
        case .roots:
            "Switch Learn / Review / Known, or classify roots from another pile."
        }
    }

    private var flashcardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Deck", selection: $deckKind) {
                    ForEach(VocabDeckKind.allCases, id: \.self) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .pickerStyle(.segmented)

                FilterStripSectionTitle(text: "Study pile")
                FilterFormCard {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(VocabMemoryBucket.allCases) { b in
                            FilterChipButton(
                                title: b.title,
                                isSelected: studyBucket == b,
                                accent: accent,
                                fillsGridCell: true
                            ) {
                                studyBucket = b
                            }
                        }
                    }
                }

                if deckKind == .words {
                    FilterStripSectionTitle(text: "Word type")
                    FilterFormCard {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                            ForEach(WordSetFilter.allCases) { f in
                                FilterChipButton(
                                    title: f.rawValue,
                                    isSelected: wordSetFilter == f,
                                    accent: accent,
                                    fillsGridCell: true
                                ) {
                                    wordSetFilter = f
                                }
                            }
                        }
                    }
                }

                HStack {
                    Text(progressLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        isFlipped.toggle()
                    }
                } label: {
                    currentCardFace
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 220)
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner))
                        .overlay(
                            RoundedRectangle(cornerRadius: FilterStyle.cardCorner)
                                .strokeBorder(FilterStyle.chipBorder(selected: false, accent: accent), lineWidth: FilterStyle.chipStrokeWidth)
                        )
                }
                .buttonStyle(.plain)

                Text("Tap card to flip")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)

                FilterStripSectionTitle(text: "Sort this card")
                FilterFormCard {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(VocabMemoryBucket.allCases) { b in
                            FilterChipButton(
                                title: b.title,
                                isSelected: currentCardBucket == b,
                                accent: accent,
                                fillsGridCell: true
                            ) {
                                moveCurrentCard(to: b)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        goToPrevious()
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canGoBack)

                    Button {
                        goToNext()
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .disabled(!canGoForward)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var progressLabel: String {
        let n = rowIndices.count
        let shown = n > 0 ? position + 1 : 0
        return "\(shown) / \(n)"
    }

    private var currentCardBucket: VocabMemoryBucket {
        guard position < rowIndices.count else { return .learn }
        let idx = rowIndices[position]
        switch deckKind {
        case .words:
            return buckets.wordBucket(for: store.words[idx].id)
        case .roots:
            return buckets.rootBucket(for: store.roots[idx].id)
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("WORD")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
                FilterBadge(text: partOfSpeechLabel(card.posKey), accent: accent.opacity(0.85))
            }
            Text(card.word)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
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
        VStack(spacing: 12) {
            Text("DEFINITION")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .multilineTextAlignment(.center)
            Text(card.definition)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
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
        VStack(spacing: 14) {
            Text("ROOT")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            Text(card.root)
                .font(.largeTitle.weight(.bold))
                .monospaced()
                .foregroundStyle(.primary)
            FilterBadge(text: card.origin, accent: accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rootBack(_ card: VocabRootCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEANING")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            Text(card.meaning)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            if !card.examples.isEmpty {
                Divider()
                Text("EXAMPLE WORDS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(card.examples, id: \.self) { ex in
                        Text("• \(ex)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

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
        case .words:
            "vocab.pos.w.\(wordSetFilter.rawValue).\(studyBucket.rawValue)"
        case .roots:
            "vocab.pos.r.\(studyBucket.rawValue)"
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
        if rowIndices.isEmpty {
            position = 0
            return
        }
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
        case .words:
            buckets.setWordBucket(id: store.words[idx].id, to: bucket)
        case .roots:
            buckets.setRootBucket(id: store.roots[idx].id, to: bucket)
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
