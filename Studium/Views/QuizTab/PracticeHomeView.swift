//
//  PracticeHomeView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Flow layout for filter groups

private struct FilterFlowLayout: Layout {
    var hSpacing: CGFloat = 16
    var vSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        compute(subviews: subviews, width: proposal.width ?? 0).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = compute(subviews: subviews, width: bounds.width)
        for (subview, origin) in zip(subviews, result.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func compute(subviews: Subviews, width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for subview in subviews {
            let sz = subview.sizeThatFits(.unspecified)
            guard sz.width > 0 else { origins.append(.zero); continue }
            if x > 0 && x + sz.width > width {
                y += rowH + vSpacing; x = 0; rowH = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += sz.width + hSpacing
            rowH = max(rowH, sz.height)
        }
        return (CGSize(width: width, height: y + rowH), origins)
    }
}

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
    @State private var viewportWidth: CGFloat = 0

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var quizStateManager: QuizStateManager

    var onStartQuiz: (FilterOptions) -> Void
    var onResumeQuiz: (QuizState) -> Void

    // MARK: Filter state
    @State private var selectedModule: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var selectedCBVerified: FilterOptions.CBVerifiedInactiveFilter? = nil
    @State private var selectedAnswerStatus: FilterOptions.AnswerStatus = .all
    @State private var randomOrder: Bool = true

    // MARK: UI state
    @State private var conceptCategories: [ConceptCategory] = []
    @State private var isComputingConcepts = false

    private var conceptFilters: FilterOptions {
        FilterOptions(
            module: selectedModule,
            difficulty: selectedDifficulty,
            answerStatus: selectedAnswerStatus,
            isBluebook: nil,
            cbVerifiedInactive: selectedCBVerified,
            shuffled: false,
            questionLimit: nil
        )
    }

    private var totalCount: Int { conceptCategories.reduce(0) { $0 + $1.count } }

    private var conceptColumnCount: Int {
        if viewportWidth >= LayoutMetrics.macTripleColumnBreakpoint { return 3 }
        if viewportWidth >= 640 { return 2 }
        return 1
    }

    private var conceptGridColumns: [GridItem] {
        (0..<conceptColumnCount).map { _ in
            GridItem(.flexible(), spacing: MacStudiumDesign.conceptGridSpacing, alignment: .top)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            filterBarSection
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: MacStudiumDesign.practiceMainSectionSpacing) {
                    if !quizStateManager.savedQuizzes.isEmpty {
                        continueSection
                    }
                    browseTitleRow
                    conceptCardsGrid
                }
                .padding(.horizontal, MacStudiumDesign.practiceMainPaddingH)
                .padding(.top, MacStudiumDesign.practiceMainPaddingTop)
                .padding(.bottom, MacStudiumDesign.practiceMainPaddingBottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.systemGroupedBackground)
        .trackViewportWidth($viewportWidth)
        .task(id: conceptFilters) { await recomputeConcepts() }
        .onAppear { quizStateManager.loadAllQuizStates() }
    }

    // MARK: - Filter bar

    private var filterBarSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FilterFlowLayout(hSpacing: 18, vSpacing: 8) {
                if questionLoader.getAvailableModules().count > 1 {
                    filterGroup("Section") {
                        FilterChipButton(title: "All", isSelected: selectedModule == nil, accent: .blue) { selectedModule = nil }
                        ForEach(questionLoader.getAvailableModules(), id: \.self) { mod in
                            FilterChipButton(
                                title: QuestionBankFilterLabels.sectionChipTitle(module: mod),
                                isSelected: selectedModule == mod,
                                accent: .blue
                            ) { selectedModule = selectedModule == mod ? nil : mod }
                        }
                    }
                }
                filterGroup("Difficulty") {
                    FilterChipButton(title: "All",    isSelected: selectedDifficulty == nil, accent: .blue)   { selectedDifficulty = nil }
                    FilterChipButton(title: "Easy",   isSelected: selectedDifficulty == "E", accent: .green)  { selectedDifficulty = selectedDifficulty == "E" ? nil : "E" }
                    FilterChipButton(title: "Medium", isSelected: selectedDifficulty == "M", accent: .orange) { selectedDifficulty = selectedDifficulty == "M" ? nil : "M" }
                    FilterChipButton(title: "Hard",   isSelected: selectedDifficulty == "H", accent: .red)    { selectedDifficulty = selectedDifficulty == "H" ? nil : "H" }
                }
                filterGroup("Status") {
                    FilterChipButton(title: "All",     isSelected: selectedAnswerStatus == .all,        accent: .blue)  { selectedAnswerStatus = .all }
                    FilterChipButton(title: "New",     isSelected: selectedAnswerStatus == .unanswered, accent: .blue)  { selectedAnswerStatus = selectedAnswerStatus == .unanswered ? .all : .unanswered }
                    FilterChipButton(title: "Wrong",   isSelected: selectedAnswerStatus == .incorrect,  accent: .red)   { selectedAnswerStatus = selectedAnswerStatus == .incorrect  ? .all : .incorrect }
                    FilterChipButton(title: "Correct", isSelected: selectedAnswerStatus == .correct,    accent: .green) { selectedAnswerStatus = selectedAnswerStatus == .correct    ? .all : .correct }
                }
                filterGroup("Source") {
                    FilterChipButton(
                        title: QuestionBankFilterLabels.cbVerifiedChipOnly,
                        isSelected: selectedCBVerified == .onlyVerifiedOffCBPracticeTests,
                        accent: .purple
                    ) { selectedCBVerified = selectedCBVerified == .onlyVerifiedOffCBPracticeTests ? nil : .onlyVerifiedOffCBPracticeTests }
                }
            }
            .padding(.bottom, 10)

            Divider()

            HStack(spacing: 8) {
                Button {
                    selectedModule = nil
                    selectedDifficulty = nil
                    selectedAnswerStatus = .all
                    selectedCBVerified = nil
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)

                Button { randomOrder.toggle() } label: {
                    Label(randomOrder ? "Shuffle" : "In Order",
                          systemImage: randomOrder ? "shuffle" : "list.number")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(randomOrder ? .accentColor : nil)

                Spacer()

                Button {
                    onStartQuiz(FilterOptions(
                        module: selectedModule,
                        difficulty: selectedDifficulty,
                        answerStatus: selectedAnswerStatus,
                        isBluebook: nil,
                        cbVerifiedInactive: selectedCBVerified,
                        shuffled: randomOrder
                    ))
                } label: {
                    Label("Start \(totalCount)", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(totalCount == 0)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, MacStudiumDesign.practiceMainPaddingH)
        .padding(.vertical, 12)
        .background(Color.secondarySystemGroupedBackground)
    }

    private func filterGroup<Content: View>(_ label: String, @ViewBuilder chips: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .fixedSize()
            chips()
        }
    }

    // MARK: - Continue section

    private var continueSection: some View {
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

    // MARK: - Browse header

    private var browseTitleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Browse by Concept")
                .font(MacStudiumDesign.browsePageTitle)
            Spacer()
            Group {
                if isComputingConcepts {
                    ProgressView().controlSize(.small)
                } else {
                    Text("\(totalCount) question\(totalCount == 1 ? "" : "s")")
                        .font(MacStudiumDesign.browsePageSubtitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Concept cards

    private var conceptCardsGrid: some View {
        let spacing = MacStudiumDesign.conceptGridSpacing
        let accentColors: [Color] = [.blue, .indigo, .purple, .teal]
        return Group {
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
                LazyVGrid(columns: conceptGridColumns, alignment: .leading, spacing: spacing) {
                    ForEach(Array(conceptCategories.enumerated()), id: \.element.id) { index, category in
                        ExpandedConceptCard(
                            category: category,
                            accentColor: accentColors[index % accentColors.count],
                            onPractice: {
                                onStartQuiz(FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: nil,
                                    cbVerifiedInactive: selectedCBVerified,
                                    shuffled: randomOrder
                                ))
                            },
                            onPracticeSkill: { skill in
                                onStartQuiz(FilterOptions(
                                    module: selectedModule,
                                    primaryClassCdDesc: category.id,
                                    skillDesc: skill,
                                    difficulty: selectedDifficulty,
                                    answerStatus: selectedAnswerStatus,
                                    isBluebook: nil,
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
}

// MARK: - Expanded Concept Card

/// Concept card used in both split-pane and compact practice layouts.
struct ExpandedConceptCard: View {
    let category: ConceptCategory
    var accentColor: Color = .blue
    let onPractice: () -> Void
    let onPracticeSkill: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent top stripe (matching web design)
            Rectangle()
                .fill(accentColor)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.id)
                    .font(MacStudiumDesign.conceptCategoryTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(category.count) question\(category.count == 1 ? "" : "s")")
                    .font(MacStudiumDesign.conceptCategoryCount)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: MacStudiumDesign.conceptCardHeaderMinHeight, alignment: .topLeading)
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
            .controlSize(MacStudiumDesign.primaryCTAControlSize)
            .padding(MacStudiumDesign.conceptFooterPadding)
        }
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: MacStudiumDesign.conceptCardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: MacStudiumDesign.conceptCardCorner)
                .strokeBorder(Color.studiumBorder.opacity(0.65), lineWidth: 1)
        )
    }
}
