//
//  PracticeHomeView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

// MARK: - Concept data model (computed off main thread)

struct ConceptCategory: Identifiable {
    let id: String // primaryClassCdDesc
    let count: Int
    let skills: [ConceptSkill]
}

struct ConceptSkill: Identifiable {
    let id: String // skillDesc
    let count: Int
}

// MARK: - PracticeHomeView

struct PracticeHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Measured from the root; drives macOS wide vs compact and column count.
    @State private var viewportWidth: CGFloat = 1200

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var quizStateManager: QuizStateManager

    var onStartQuiz: (FilterOptions) -> Void
    var onResumeQuiz: (QuizState) -> Void

    // MARK: Filter state
    @State private var selectedModule: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var selectedSource: FilterOptions.BluebookFilter? = nil
    @State private var selectedCBVerified: FilterOptions.CBVerifiedInactiveFilter? = nil
    @State private var selectedAnswerStatus: FilterOptions.AnswerStatus = .all
    /// When true, questions are shuffled when starting practice (random order).
    @State private var randomOrder: Bool = true

    // MARK: UI state
    @State private var expandedCategories: Set<String> = []
    @State private var conceptCategories: [ConceptCategory] = []
    @State private var isComputingConcepts = false

    // MARK: - Filters used for concept data (no shuffle/limit)
    private var conceptFilters: FilterOptions {
        FilterOptions(
            module: selectedModule,
            difficulty: selectedDifficulty,
            answerStatus: selectedAnswerStatus,
            isBluebook: selectedSource,
            cbVerifiedInactive: selectedCBVerified,
            shuffled: false,
            questionLimit: nil
        )
    }

    private var totalCount: Int {
        conceptCategories.reduce(0) { $0 + $1.count }
    }

    // MARK: - Wide layout detection

    private var isWideLayout: Bool {
        #if os(macOS)
        return viewportWidth >= LayoutMetrics.macWideBreakpoint
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    private var wideConceptColumnCount: Int {
        guard isWideLayout else { return 2 }
        if viewportWidth >= LayoutMetrics.macTripleColumnBreakpoint { return 3 }
        return 2
    }

    /// Wide concept grid only; matches Mac spacing on iPad regular and macOS.
    private var conceptGridColumnSpacing: CGFloat {
        MacStudiumDesign.conceptGridSpacing
    }

    private var wideConceptGridColumns: [GridItem] {
        let spacing = conceptGridColumnSpacing
        return (0..<wideConceptColumnCount).map { _ in
            GridItem(.flexible(), spacing: spacing, alignment: .top)
        }
    }

    /// Single-column chip layout for the macOS filter sidebar.
    private var sidebarChipGridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8)]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if isWideLayout {
                widePaneLayout
            } else {
                compactLayout
            }
        }
        .background(Color.systemGroupedBackground)
        .trackViewportWidth($viewportWidth)
        .task(id: conceptFilters) {
            await recomputeConcepts()
        }
        .onAppear {
            quizStateManager.loadAllQuizStates()
        }
    }

    // MARK: - Wide (macOS / iPad regular) Layout

    private var widePaneLayout: some View {
        widePracticeSplitLayout
    }

    /// Saved-quiz strip for macOS and iPad regular (shared shell).
    private var wideLayoutContinueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FilterStripSectionTitle(text: "Continue")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(quizStateManager.savedQuizzes.prefix(5)) { quiz in
                        let answered = quiz.answerStates.values.filter { $0.hasSubmitted }.count
                        let total = quiz.questionIds.count
                        ContinueSavedQuizCard(
                            title: quiz.filterDescription(),
                            answered: answered,
                            total: total,
                            onPlay: { onResumeQuiz(quiz) },
                            onDelete: { quizStateManager.deleteQuizState(id: quiz.id) }
                        )
                    }
                }
            }
        }
    }

    /// Same split shell on macOS and iPad regular: fixed filter column, full-width browse column.
    private var widePracticeSplitLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: MacStudiumDesign.practiceSidebarSectionSpacing) {
                    FilterStripSectionTitle(text: "Filters")
                    sidebarFilterPanel
                    Divider()
                        .padding(.vertical, 6)
                    sidebarPracticeRow
                }
                .padding(MacStudiumDesign.practiceSidebarPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: MacStudiumDesign.practiceSidebarWidth)
            .background(Color.secondarySystemGroupedBackground)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: MacStudiumDesign.practiceMainSectionSpacing) {
                    if !quizStateManager.savedQuizzes.isEmpty {
                        wideLayoutContinueSection
                    }
                    practiceBrowseHeader
                    wideConceptGrid
                }
                .padding(.horizontal, MacStudiumDesign.practiceMainPaddingH)
                .padding(.top, MacStudiumDesign.practiceMainPaddingTop)
                .padding(.bottom, MacStudiumDesign.practiceMainPaddingBottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
        }
    }

    private var practiceBrowseHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Browse by Concept")
                .font(MacStudiumDesign.browsePageTitle)
            if isComputingConcepts {
                Text("Loading…")
                    .font(MacStudiumDesign.browsePageSubtitle)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(totalCount) question\(totalCount == 1 ? "" : "s") available")
                    .font(MacStudiumDesign.browsePageSubtitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Wide Concept Grid (always expanded, 2 columns)

    private var wideConceptGrid: some View {
        Group {
            if isComputingConcepts && conceptCategories.isEmpty {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Counting questions…")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if conceptCategories.isEmpty {
                Text("No questions match the current filters.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            } else {
                LazyVGrid(
                    columns: wideConceptGridColumns,
                    alignment: .leading,
                    spacing: conceptGridColumnSpacing
                ) {
                    ForEach(conceptCategories) { category in
                        ExpandedConceptCard(
                            category: category,
                            onPractice: {
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            },
                            onPracticeSkill: { skill in
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    skillDesc: skill,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }
        }
    }

    // MARK: - Compact (iPhone) Layout

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Saved quizzes strip (if any)
                if !quizStateManager.savedQuizzes.isEmpty {
                    savedQuizzesStrip
                }

                // Filter panel
                filterPanel
                    .padding(.horizontal)

                // Count + practice CTA
                practiceAllRow
                    .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Concept browser
                conceptBrowser
                    .padding(.bottom, 24)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Background concept computation

    private func recomputeConcepts() async {
        isComputingConcepts = true
        let filters = conceptFilters
        let verifiedIds = questionLoader.cbVerifiedNotOnPracticeTestIds
        let snapshot = await MainActor.run {
            (questions: questionLoader.questions, progress: progressManager.progress)
        }

        let categories: [ConceptCategory] = await Task.detached(priority: .userInitiated) {
            let questions = filters.filteredQuestions(
                from: snapshot.questions,
                progress: snapshot.progress,
                cbVerifiedNotOnPracticeTestIds: verifiedIds
            )

            var catDict: [String: [String: Int]] = [:]
            for q in questions {
                catDict[q.primaryClassCdDesc, default: [:]][q.skillDesc, default: 0] += 1
            }

            return catDict
                .map { cat, skillDict in
                    ConceptCategory(
                        id: cat,
                        count: skillDict.values.reduce(0, +),
                        skills: skillDict
                            .map { ConceptSkill(id: $0.key, count: $0.value) }
                            .sorted { $0.count > $1.count }
                    )
                }
                .sorted { $0.count > $1.count }
        }.value

        await MainActor.run {
            conceptCategories = categories
            isComputingConcepts = false
        }
    }

    // MARK: - Stat Tile (sidebar)

    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Saved Quizzes Strip

    private var savedQuizzesStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            FilterStripSectionTitle(text: "Continue")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(quizStateManager.savedQuizzes.prefix(5)) { quiz in
                        let answered = quiz.answerStates.values.filter { $0.hasSubmitted }.count
                        let total = quiz.questionIds.count
                        ContinueSavedQuizCard(
                            title: quiz.filterDescription(),
                            answered: answered,
                            total: total,
                            onPlay: { onResumeQuiz(quiz) },
                            onDelete: { quizStateManager.deleteQuizState(id: quiz.id) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Sidebar Filter Panel (wide layout, single-column groups)

    private var sidebarFilterPanel: some View {
        VStack(alignment: .leading, spacing: MacStudiumDesign.practiceSidebarSectionSpacing) {
            if questionLoader.getAvailablePrograms().count == 1,
               let program = questionLoader.getAvailablePrograms().first {
                VStack(alignment: .leading, spacing: 4) {
                    FilterSubgroupLabel(text: QuestionBankFilterLabels.assessmentGroupTitle)
                    Text(program)
                        .font(MacStudiumDesign.sidebarGroupTitle)
                        .foregroundStyle(.secondary)
                }
            }
            moduleFilterSection(columns: sidebarChipGridColumns)
            difficultyFilterSection(columns: sidebarChipGridColumns)
            sourceFilterSection(columns: sidebarChipGridColumns)
            answerStatusFilterSection(columns: sidebarChipGridColumns)

            FilterGroupBlock(title: "Question order", systemImage: "arrow.up.arrow.down", tint: .indigo) {
                VStack(spacing: 8) {
                    FilterOrderChoiceButton(
                        title: "In order",
                        subtitle: "Same sequence",
                        systemImage: "list.number",
                        isSelected: !randomOrder,
                        tint: .indigo
                    ) {
                        randomOrder = false
                    }
                    FilterOrderChoiceButton(
                        title: "Random",
                        subtitle: "Shuffled each session",
                        systemImage: "shuffle",
                        isSelected: randomOrder,
                        tint: .indigo
                    ) {
                        randomOrder = true
                    }
                }
            }
        }
    }

    // MARK: - Sidebar Practice CTA (wide layout)

    private var sidebarPracticeRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isComputingConcepts {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.regular)
                    Text("Loading…")
                        .font(MacStudiumDesign.continueCardMeta)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalCount)")
                        .font(MacStudiumDesign.practiceAllSidebarCount)
                        .foregroundStyle(totalCount > 0 ? Color.primary : Color.secondary)
                    Text(totalCount == 1 ? "question matches filters" : "questions match filters")
                        .font(MacStudiumDesign.practiceAllSidebarLabel)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                startQuiz(filters: FilterOptions(
                    module: selectedModule,
                    difficulty: selectedDifficulty,
                    answerStatus: selectedAnswerStatus,
                    isBluebook: selectedSource,
                    cbVerifiedInactive: selectedCBVerified,
                    shuffled: randomOrder
                ))
            } label: {
                Label("Practice All (\(totalCount))", systemImage: "play.fill")
                    .font(MacStudiumDesign.practiceAllSidebarButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(totalCount == 0)
        }
    }

    // MARK: - Filter Panel (compact layout)

    private var useWideFilterColumns: Bool {
        horizontalSizeClass == .regular
    }

    private var chipGridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 80), spacing: 6),
            GridItem(.flexible(minimum: 80), spacing: 6)
        ]
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterStripSectionTitle(text: "Filters")

            if useWideFilterColumns {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 12) {
                        moduleFilterSection(columns: chipGridColumns)
                        difficultyFilterSection(columns: chipGridColumns)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        sourceFilterSection(columns: chipGridColumns)
                        answerStatusFilterSection(columns: chipGridColumns)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    moduleFilterSection(columns: chipGridColumns)
                    difficultyFilterSection(columns: chipGridColumns)
                    sourceFilterSection(columns: chipGridColumns)
                    answerStatusFilterSection(columns: chipGridColumns)
                }
            }

            FilterGroupBlock(title: "Question order", systemImage: "arrow.up.arrow.down", tint: .indigo) {
                HStack(spacing: 8) {
                    FilterOrderChoiceButton(
                        title: "In order",
                        subtitle: "Same sequence each time",
                        systemImage: "list.number",
                        isSelected: !randomOrder,
                        tint: .indigo
                    ) {
                        randomOrder = false
                    }
                    FilterOrderChoiceButton(
                        title: "Random",
                        subtitle: "Shuffled each session",
                        systemImage: "shuffle",
                        isSelected: randomOrder,
                        tint: .indigo
                    ) {
                        randomOrder = true
                    }
                }
            }
        }
        .padding(12)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.mainPanelCorner))
    }

    private func moduleFilterSection(columns: [GridItem]) -> some View {
        FilterGroupBlock(title: QuestionBankFilterLabels.sectionSubgroup, systemImage: "square.stack.3d.up", tint: .blue) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedModule == nil, accent: .blue, fillsGridCell: true) {
                    selectedModule = nil
                }
                ForEach(questionLoader.getAvailableModules(), id: \.self) { mod in
                    FilterChipButton(
                        title: QuestionBankFilterLabels.sectionChipTitle(module: mod),
                        isSelected: selectedModule == mod,
                        accent: .blue,
                        fillsGridCell: true
                    ) {
                        selectedModule = (selectedModule == mod) ? nil : mod
                    }
                }
            }
        }
    }

    private func difficultyFilterSection(columns: [GridItem]) -> some View {
        FilterGroupBlock(title: "Difficulty", systemImage: "chart.bar", tint: .orange) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedDifficulty == nil, accent: .blue, fillsGridCell: true) {
                    selectedDifficulty = nil
                }
                FilterChipButton(title: "Easy", isSelected: selectedDifficulty == "E", accent: .green, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "E") ? nil : "E"
                }
                FilterChipButton(title: "Medium", isSelected: selectedDifficulty == "M", accent: .orange, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "M") ? nil : "M"
                }
                FilterChipButton(title: "Hard", isSelected: selectedDifficulty == "H", accent: .red, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "H") ? nil : "H"
                }
            }
        }
    }

    private func sourceFilterSection(columns: [GridItem]) -> some View {
        FilterGroupBlock(title: QuestionBankFilterLabels.practiceTestsGroupTitle, systemImage: "books.vertical", tint: .purple) {
            VStack(alignment: .leading, spacing: 8) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                    FilterChipButton(title: QuestionBankFilterLabels.practiceTestsAll, isSelected: selectedSource == nil, accent: .purple, fillsGridCell: true) {
                        selectedSource = nil
                    }
                    FilterChipButton(title: QuestionBankFilterLabels.practiceTestsOnly, isSelected: selectedSource == .bluebook, accent: .purple, fillsGridCell: true) {
                        selectedSource = (selectedSource == .bluebook) ? nil : .bluebook
                    }
                    FilterChipButton(title: QuestionBankFilterLabels.excludeActiveShort, isSelected: selectedSource == .notBluebook, accent: .purple, fillsGridCell: true) {
                        selectedSource = (selectedSource == .notBluebook) ? nil : .notBluebook
                    }
                }
                Text(QuestionBankFilterLabels.practiceTestsHelp)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(questionLoader.bluebookTaggingExplanation)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().padding(.vertical, 4)

                FilterSubgroupLabel(text: QuestionBankFilterLabels.cbVerifiedPoolTitle)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                    FilterChipButton(title: QuestionBankFilterLabels.cbVerifiedPoolAny, isSelected: selectedCBVerified == nil, accent: .purple, fillsGridCell: true) {
                        selectedCBVerified = nil
                    }
                    FilterChipButton(
                        title: QuestionBankFilterLabels.cbVerifiedPoolOnly,
                        isSelected: selectedCBVerified == .onlyVerifiedOffCBPracticeTests,
                        accent: .purple,
                        fillsGridCell: true
                    ) {
                        selectedCBVerified = (selectedCBVerified == .onlyVerifiedOffCBPracticeTests) ? nil : .onlyVerifiedOffCBPracticeTests
                    }
                }
                Text(QuestionBankFilterLabels.cbVerifiedPoolHelp)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(questionLoader.cbVerifiedSidecarExplanation)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func answerStatusFilterSection(columns: [GridItem]) -> some View {
        FilterGroupBlock(title: "Answer status", systemImage: "checkmark.circle", tint: .green) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedAnswerStatus == .all, accent: .green, fillsGridCell: true) {
                    selectedAnswerStatus = .all
                }
                FilterChipButton(title: "New", isSelected: selectedAnswerStatus == .unanswered, accent: .green, fillsGridCell: true) {
                    selectedAnswerStatus = (selectedAnswerStatus == .unanswered) ? .all : .unanswered
                }
                FilterChipButton(title: "Wrong", isSelected: selectedAnswerStatus == .incorrect, accent: .red, fillsGridCell: true) {
                    selectedAnswerStatus = (selectedAnswerStatus == .incorrect) ? .all : .incorrect
                }
                FilterChipButton(title: "Correct", isSelected: selectedAnswerStatus == .correct, accent: .green, fillsGridCell: true) {
                    selectedAnswerStatus = (selectedAnswerStatus == .correct) ? .all : .correct
                }
            }
        }
    }

    // MARK: - Practice All Row (compact layout)

    private var practiceAllRow: some View {
        HStack {
            if isComputingConcepts {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(totalCount > 0 ? .primary : .secondary)
                    Text(totalCount == 1 ? "question" : "questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                startQuiz(filters: FilterOptions(
                    module: selectedModule,
                    difficulty: selectedDifficulty,
                    answerStatus: selectedAnswerStatus,
                    isBluebook: selectedSource,
                    cbVerifiedInactive: selectedCBVerified,
                    shuffled: randomOrder
                ))
            } label: {
                Text("Practice All")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(totalCount > 0 ? Color.blue : Color.systemGray4)
                    .foregroundColor(.white)
                    .cornerRadius(22)
            }
            .disabled(totalCount == 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Concept Browser (compact layout)

    private var conceptBrowser: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Browse by Concept")
                    .font(.headline)
                Spacer()
                if !expandedCategories.isEmpty {
                    Button("Collapse All") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            expandedCategories.removeAll()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)

            conceptCardList
        }
    }

    // MARK: - Concept Grid (wide layout — 2 adaptive columns)

    private var conceptGrid: some View {
        Group {
            if isComputingConcepts && conceptCategories.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Counting questions…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else if conceptCategories.isEmpty {
                Text("No questions match the current filters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12, alignment: .top),
                        GridItem(.flexible(), spacing: 12, alignment: .top)
                    ],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(conceptCategories) { category in
                        ConceptGridCard(
                            category: category,
                            onPractice: {
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            },
                            onPracticeSkill: { skill in
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    skillDesc: skill,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                }
            }
        }
    }

    // MARK: - Concept Card List (shared between layouts)

    private var conceptCardList: some View {
        Group {
            if isComputingConcepts && conceptCategories.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Counting questions…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)

            } else if conceptCategories.isEmpty {
                Text("No questions match the current filters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)

            } else {
                VStack(spacing: 8) {
                    ForEach(conceptCategories) { category in
                        ConceptCategoryCard(
                            category: category,
                            isExpanded: expandedCategories.contains(category.id),
                            onToggle: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    if expandedCategories.contains(category.id) {
                                        expandedCategories.remove(category.id)
                                    } else {
                                        expandedCategories.insert(category.id)
                                    }
                                }
                            },
                            onPracticeCategory: {
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            },
                            onPracticeSkill: { skill in
                                startQuiz(filters: FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    skillDesc: skill,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: selectedSource,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func startQuiz(filters: FilterOptions) {
        onStartQuiz(filters)
    }

}

// MARK: - Concept Category Card

struct ConceptCategoryCard: View {
    let category: ConceptCategory
    let isExpanded: Bool
    let onToggle: () -> Void
    let onPracticeCategory: () -> Void
    let onPracticeSkill: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.id)
                        .font({
                            #if os(macOS)
                            MacStudiumDesign.conceptCategoryTitle
                            #else
                            Font.body.weight(.semibold)
                            #endif
                        }())
                        .foregroundColor(.primary)
                    Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                        .font({
                            #if os(macOS)
                            MacStudiumDesign.conceptCategoryCount
                            #else
                            Font.subheadline
                            #endif
                        }())
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { onToggle() }

                Button(action: onPracticeCategory) {
                    Text("Practice")
                        .font({
                            #if os(macOS)
                            Font.headline.weight(.semibold)
                            #else
                            Font.subheadline.weight(.semibold)
                            #endif
                        }())
                        .padding(.horizontal, {
                            #if os(macOS)
                            16
                            #else
                            14
                            #endif
                        }())
                        .padding(.vertical, {
                            #if os(macOS)
                            8
                            #else
                            7
                            #endif
                        }())
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                #if os(macOS)
                .controlSize(.large)
                #endif

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font({
                        #if os(macOS)
                        Font.subheadline.weight(.semibold)
                        #else
                        Font.footnote.weight(.semibold)
                        #endif
                    }())
                    .foregroundColor(.secondary)
                    .frame(width: 28)
                    .contentShape(Rectangle())
                    .onTapGesture { onToggle() }
            }
            .padding(.horizontal, {
                #if os(macOS)
                MacStudiumDesign.conceptCardPaddingH
                #else
                18
                #endif
            }())
            .padding(.vertical, {
                #if os(macOS)
                14
                #else
                16
                #endif
            }())

            if isExpanded {
                Divider()
                    .padding(.horizontal, {
                        #if os(macOS)
                        MacStudiumDesign.conceptCardPaddingH
                        #else
                        18
                        #endif
                    }())

                VStack(spacing: 0) {
                    ForEach(category.skills) { skill in
                        Button { onPracticeSkill(skill.id) } label: {
                            HStack(spacing: 12) {
                                Text(skill.id)
                                    .font({
                                        #if os(macOS)
                                        MacStudiumDesign.conceptSkillTitle
                                        #else
                                        Font.subheadline
                                        #endif
                                    }())
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(skill.count)")
                                    .font({
                                        #if os(macOS)
                                        MacStudiumDesign.conceptSkillCount
                                        #else
                                        Font.subheadline.monospacedDigit()
                                        #endif
                                    }())
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, {
                                #if os(macOS)
                                MacStudiumDesign.conceptSkillRowVPadding
                                #else
                                12
                                #endif
                            }())
                            .padding(.horizontal, {
                                #if os(macOS)
                                MacStudiumDesign.conceptCardPaddingH
                                #else
                                24
                                #endif
                            }())
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if skill.id != category.skills.last?.id {
                            Divider().padding(.leading, {
                                #if os(macOS)
                                MacStudiumDesign.conceptCardPaddingH
                                #else
                                24
                                #endif
                            }())
                        }
                    }
                }
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: {
            #if os(macOS)
            MacStudiumDesign.conceptCardCorner
            #else
            14
            #endif
        }()))
    }
}

// MARK: - Expanded Concept Card (wide layout — always expanded, big card)

/// Wide-layout concept card (macOS + iPad regular): shared compact typography.
struct ExpandedConceptCard: View {
    let category: ConceptCategory
    let onPractice: () -> Void
    let onPracticeSkill: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.id)
                    .font(MacStudiumDesign.conceptCategoryTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                    .font(MacStudiumDesign.conceptCategoryCount)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 72, alignment: .topLeading)
            .padding(.horizontal, MacStudiumDesign.conceptCardPaddingH)
            .padding(.top, MacStudiumDesign.conceptCardHeaderTop)
            .padding(.bottom, MacStudiumDesign.conceptCardHeaderBottom)

            Divider()
                .padding(.horizontal, MacStudiumDesign.conceptCardPaddingH)

            VStack(spacing: 0) {
                ForEach(category.skills) { skill in
                    Button { onPracticeSkill(skill.id) } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(skill.id)
                                .font(MacStudiumDesign.conceptSkillTitle)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(skill.count)")
                                .font(MacStudiumDesign.conceptSkillCount)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 28, alignment: .trailing)
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, MacStudiumDesign.conceptSkillRowVPadding)
                        .padding(.horizontal, MacStudiumDesign.conceptCardPaddingH)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if skill.id != category.skills.last?.id {
                        Divider().padding(.leading, MacStudiumDesign.conceptCardPaddingH)
                    }
                }
            }

            Button(action: onPractice) {
                Label("Practice this category", systemImage: "play.fill")
                    .font(MacStudiumDesign.conceptPrimaryButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MacStudiumDesign.conceptPracticeButtonVPadding)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(MacStudiumDesign.conceptFooterPadding)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacStudiumDesign.conceptCardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: MacStudiumDesign.conceptCardCorner)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Concept Grid Card (wide layout)

struct ConceptGridCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let category: ConceptCategory
    let onPractice: () -> Void
    let onPracticeSkill: (String) -> Void

    private let maxVisibleSkills = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 3) {
                Text(category.id)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 56, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Skill rows
            VStack(spacing: 0) {
                ForEach(category.skills.prefix(maxVisibleSkills)) { skill in
                    Button { onPracticeSkill(skill.id) } label: {
                        HStack(spacing: 8) {
                            Text(skill.id)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(skill.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 9)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if skill.id != category.skills.prefix(maxVisibleSkills).last?.id {
                        Divider().padding(.leading, 16)
                    }
                }

                if category.skills.count > maxVisibleSkills {
                    Divider().padding(.leading, 16)
                    Text("+ \(category.skills.count - maxVisibleSkills) more skills")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
            }

            // Practice button
            Button(action: onPractice) {
                Text("Practice")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(12)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.mainPanelCorner))
    }
}
