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

    @AppStorage("studium_vocab_shuffle_mode") private var shuffleMode = false
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
        .navAdaptiveTitle()
        .onAppear {
            if shuffleMode, manualOrder == nil {
                applyDeckOrder(resetPosition: false)
            }
            restorePosition()
            validateManualOrder()
            clampPosition()
        }
        .onChange(of: deckKind) { _, _ in
            applyDeckOrder(resetPosition: true)
        }
        .onChange(of: studyBucket) { _, _ in
            applyDeckOrder(resetPosition: true)
        }
        .onChange(of: wordSetFilter) { _, _ in
            guard deckKind == .words else { return }
            applyDeckOrder(resetPosition: true)
        }
        .onChange(of: shuffleMode) { _, _ in
            applyDeckOrder(resetPosition: true)
        }
        .onChange(of: store.words.count) { _, _ in
            applyDeckOrder(resetPosition: false)
            clampPosition()
        }
        .onChange(of: store.roots.count) { _, _ in
            applyDeckOrder(resetPosition: false)
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
                    cardOrderSection
                }
                .padding(20)
            }
            .frame(width: 240)
            .background(Color.secondarySystemGroupedBackground)

            Divider()

            // Right main: card + sort + nav (controls stay visible when pile is empty)
            ScrollView {
                VStack(spacing: 20) {
                    if rowIndices.isEmpty {
                        emptyDeckCard
                    } else {
                        progressAndCardSection
                        sortSection
                        navButtons
                    }
                }
                .padding(24)
                .readableContentFrame(maxWidth: 680)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
        }
        .background(Color.systemGroupedBackground)
    }

    // MARK: - Narrow layout (iPhone)

    private var narrowLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
                deckPickerSection
                phoneStudyPilePicker
                if deckKind == .words { phoneWordTypePicker }
                cardOrderSection
                if rowIndices.isEmpty {
                    emptyDeckCard
                } else {
                    progressAndCardSection
                    phoneSortSection
                    navButtons
                }
            }
            .padding(.horizontal, StudiumDesignSystem.spacingMD)
            .padding(.bottom, 20)
            .readableContentFrame(maxWidth: LayoutMetrics.vocabReadableMaxWidth)
        }
        .background(Color.systemGroupedBackground)
    }

    /// iPhone + iPad: persistent shuffle mode (not one-shot).
    private var cardOrderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Card order")
            FilterFormCard {
                HStack(spacing: 8) {
                    FilterChipButton(
                        title: "In order",
                        isSelected: !shuffleMode,
                        accent: accent,
                        fillsGridCell: true
                    ) { shuffleMode = false }
                    FilterChipButton(
                        title: "Shuffle",
                        isSelected: shuffleMode,
                        accent: accent,
                        fillsGridCell: true
                    ) { shuffleMode = true }
                    .disabled(baseFilteredIndices.count < 2)
                }
            }
        }
    }

    /// iPhone: segmented pile picker without extra card chrome.
    private var phoneStudyPilePicker: some View {
        Picker("Study pile", selection: $studyBucket) {
            ForEach(VocabMemoryBucket.allCases) { b in
                Text(b.title).tag(b)
            }
        }
        .pickerStyle(.segmented)
    }

    /// iPhone: horizontal chip strip for word type.
    private var phoneWordTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WordSetFilter.allCases) { f in
                    FilterChipButton(
                        title: f.rawValue,
                        isSelected: wordSetFilter == f,
                        accent: accent,
                        fillsGridCell: false
                    ) { wordSetFilter = f }
                }
            }
        }
    }

    /// iPhone: segmented bucket picker below the flashcard.
    private var phoneSortSection: some View {
        Picker("Move card to", selection: phoneSortBucketBinding) {
            Text("Learn").tag(VocabMemoryBucket.learn)
            Text("Review").tag(VocabMemoryBucket.review)
            Text("Mastered").tag(VocabMemoryBucket.known)
        }
        .pickerStyle(.segmented)
    }

    private var phoneSortBucketBinding: Binding<VocabMemoryBucket> {
        Binding(
            get: { currentCardBucket },
            set: { moveCurrentCard(to: $0) }
        )
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

    private var progressAndCardSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(progressLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if shuffleMode, rowIndices.count > 1 {
                    Text("· Shuffled")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }
                Spacer()
                if isWide {
                    Text("Space or tap to flip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
            } label: {
                currentCardFace
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: isWide ? 380 : 220)
                    .padding(isWide ? 24 : 20)
                    .background(Color.systemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: FilterStyle.cardCorner, style: .continuous)
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
                if isWide {
                    Label("Previous", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                } else {
                    Image(systemName: "chevron.left")
                }
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .buttonStyle(.bordered)
            .controlSize(isWide ? .large : .regular)
            .disabled(!canGoBack)
            .accessibilityLabel("Previous card")

            Button { goToNext() } label: {
                if isWide {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .buttonStyle(.borderedProminent)
            .controlSize(isWide ? .large : .regular)
            .tint(accent)
            .disabled(!canGoForward)
            .accessibilityLabel("Next card")
        }
    }

    private var emptyDeckCard: some View {
        VStack(spacing: StudiumDesignSystem.spacingMD) {
            HStack {
                Text(progressLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            VStack(spacing: StudiumDesignSystem.spacingSM) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)
                Text("No cards in this pile")
                    .font(.headline)
                Text(emptyDeckHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: isWide ? 280 : 160)
            .padding(isWide ? 24 : 16)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: FilterStyle.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FilterStyle.cardCorner, style: .continuous)
                    .strokeBorder(Color.studiumBorder.opacity(0.6), lineWidth: FilterStyle.chipStrokeWidth)
            )

            pileSwitcherHint
        }
    }

    @ViewBuilder
    private var pileSwitcherHint: some View {
        if isWide {
            widePileSwitcherHint
        } else {
            phoneStudyPilePicker
                .padding(.top, StudiumDesignSystem.spacingSM)
        }
    }

    private var widePileSwitcherHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Try another pile")
            FilterFormCard {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                    ForEach(VocabMemoryBucket.allCases.filter { $0 != studyBucket }) { b in
                        FilterChipButton(
                            title: b.title,
                            isSelected: false,
                            accent: accent,
                            fillsGridCell: true
                        ) { studyBucket = b }
                    }
                }
            }
        }
    }

    private var emptyDeckHint: String {
        if !isWide {
            return "Try another pile or word type above."
        }
        switch deckKind {
        case .words:
            return "Try another part-of-speech set, switch Learn / Review / Known, or sort cards from another pile."
        case .roots:
            return "Switch Learn / Review / Known, or classify roots from another pile."
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
        guard let m = manualOrder, Set(m) != base else { return }
        if shuffleMode, base.count > 1 {
            manualOrder = baseFilteredIndices.sorted().shuffled()
        } else {
            manualOrder = nil
        }
    }

    private func applyDeckOrder(resetPosition: Bool) {
        let base = baseFilteredIndices.sorted()
        if shuffleMode, base.count > 1 {
            manualOrder = base.shuffled()
        } else {
            manualOrder = nil
        }
        if resetPosition {
            position = 0
            persistPosition()
            isFlipped = false
        } else {
            validateManualOrder()
        }
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
        let leavingPile = bucket != studyBucket

        switch deckKind {
        case .words: buckets.setWordBucket(id: store.words[idx].id, to: bucket)
        case .roots: buckets.setRootBucket(id: store.roots[idx].id, to: bucket)
        }

        isFlipped = false

        if leavingPile {
            let newBase = baseFilteredIndices.sorted()
            if shuffleMode, newBase.count > 1 {
                manualOrder = newBase.shuffled()
            } else {
                manualOrder = nil
            }
            position = min(position, max(0, newBase.count - 1))
        } else if position + 1 < rowIndices.count {
            position += 1
        } else if rowIndices.count > 1 {
            if shuffleMode {
                manualOrder = baseFilteredIndices.sorted().shuffled()
            }
            position = 0
        }

        persistPosition()
    }
}

#Preview {
    NavigationStack {
        VocabFlashcardsView()
    }
}
