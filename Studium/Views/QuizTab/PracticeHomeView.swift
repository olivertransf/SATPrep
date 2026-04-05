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

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var quizStateManager: QuizStateManager

    var onStartQuiz: (FilterOptions) -> Void
    var onResumeQuiz: (QuizState) -> Void

    // MARK: Filter state
    @State private var selectedModule: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var selectedSource: FilterOptions.BluebookFilter? = nil
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
            shuffled: false,
            questionLimit: nil
        )
    }

    private var totalCount: Int {
        conceptCategories.reduce(0) { $0 + $1.count }
    }

    var body: some View {
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
        .background(Color(.systemGroupedBackground))
        // Recompute concept data whenever any filter changes
        .task(id: conceptFilters) {
            await recomputeConcepts()
        }
        .onAppear {
            quizStateManager.loadAllQuizStates()
        }
    }

    // MARK: - Background concept computation

    private func recomputeConcepts() async {
        isComputingConcepts = true
        let filters = conceptFilters
        let ql = questionLoader
        let pm = progressManager

        let categories: [ConceptCategory] = await Task.detached(priority: .userInitiated) {
            let questions = ql.getFilteredQuestions(filters: filters, progressManager: pm)

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

        conceptCategories = categories
        isComputingConcepts = false
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

    // MARK: - Filter Panel

    /// Two-column filter layout (Module + Difficulty | Source + Answer status) on iPad / regular width.
    private var useWideFilterColumns: Bool {
        horizontalSizeClass == .regular
    }

    private var chipGridColumns: [GridItem] {
        if useWideFilterColumns {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(minimum: 96), spacing: 8),
            GridItem(.flexible(minimum: 96), spacing: 8)
        ]
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterStripSectionTitle(text: "Filters")

            if useWideFilterColumns {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 12) {
                        moduleFilterSection
                        difficultyFilterSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        sourceFilterSection
                        answerStatusFilterSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    moduleFilterSection
                    difficultyFilterSection
                    sourceFilterSection
                    answerStatusFilterSection
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.mainPanelCorner))
    }

    private var moduleFilterSection: some View {
        FilterGroupBlock(title: "Module", systemImage: "square.stack.3d.up", tint: .blue) {
            LazyVGrid(columns: chipGridColumns, alignment: .leading, spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedModule == nil, accent: .blue, fillsGridCell: true) {
                    selectedModule = nil
                }
                ForEach(questionLoader.getAvailableModules(), id: \.self) { mod in
                    FilterChipButton(
                        title: moduleLabel(mod),
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

    private var difficultyFilterSection: some View {
        FilterGroupBlock(title: "Difficulty", systemImage: "chart.bar", tint: .orange) {
            LazyVGrid(columns: chipGridColumns, alignment: .leading, spacing: 6) {
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

    private var sourceFilterSection: some View {
        FilterGroupBlock(title: "Source", systemImage: "books.vertical", tint: .purple) {
            LazyVGrid(columns: chipGridColumns, alignment: .leading, spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedSource == nil, accent: .purple, fillsGridCell: true) {
                    selectedSource = nil
                }
                FilterChipButton(title: "Bluebook", isSelected: selectedSource == .bluebook, accent: .purple, fillsGridCell: true) {
                    selectedSource = (selectedSource == .bluebook) ? nil : .bluebook
                }
                FilterChipButton(title: "Other", isSelected: selectedSource == .notBluebook, accent: .purple, fillsGridCell: true) {
                    selectedSource = (selectedSource == .notBluebook) ? nil : .notBluebook
                }
            }
        }
    }

    private var answerStatusFilterSection: some View {
        FilterGroupBlock(title: "Answer status", systemImage: "checkmark.circle", tint: .green) {
            LazyVGrid(columns: chipGridColumns, alignment: .leading, spacing: 6) {
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

    // MARK: - Practice All Row

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
                    shuffled: randomOrder
                ))
            } label: {
                Text("Practice All")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(totalCount > 0 ? Color.blue : Color(.systemGray4))
                    .foregroundColor(.white)
                    .cornerRadius(22)
            }
            .disabled(totalCount == 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Concept Browser

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
                                    shuffled: randomOrder
                                ))
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func startQuiz(filters: FilterOptions) {
        onStartQuiz(filters)
    }

    private func moduleLabel(_ module: String) -> String {
        switch module.lowercased() {
        case "math": return "Math"
        case "reading and writing": return "Reading & Writing"
        default: return module.capitalized
        }
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
            // Header row
            HStack(spacing: 12) {
                // Left: title + count — tap to expand
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.id)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { onToggle() }

                FilterChipButton(title: "Practice", isSelected: true, accent: .blue, fillsGridCell: false) {
                    onPracticeCategory()
                }

                // Chevron
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .onTapGesture { onToggle() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Skills list (expanded)
            if isExpanded {
                Divider().padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(category.skills) { skill in
                        Button { onPracticeSkill(skill.id) } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 6, height: 6)

                                Text(skill.id)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                FilterBadge(text: "\(skill.count)", accent: .gray)

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if skill.id != category.skills.last?.id {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.mainPanelCorner))
    }
}
