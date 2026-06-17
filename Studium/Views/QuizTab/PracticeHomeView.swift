//
//  PracticeHomeView.swift
//  Studium
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ConceptCategory: Identifiable {
    let id: String
    let count: Int
    let skills: [ConceptSkill]
}

struct ConceptSkill: Identifiable {
    let id: String
    let count: Int
}

struct PracticeHomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewportWidth: CGFloat = 0
    @State private var filterDraft = PracticeFilterDraft()
    @State private var showFilterSheet = false
    @State private var showEmptyQuizAlert = false

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var quizStateManager: QuizStateManager

    var initialModule: String? = nil
    var onConsumeModulePreset: (() -> Void)? = nil

    var onStartQuiz: (FilterOptions) -> Void
    var onResumeQuiz: (QuizState) -> Void

    @State private var conceptCategories: [ConceptCategory] = []
    @State private var isComputingConcepts = false

    private var useWideSplit: Bool {
        viewportWidth >= LayoutMetrics.macWideBreakpoint
    }

    private var conceptFilters: FilterOptions {
        filterDraft.conceptFilterOptions()
    }

    private var totalCount: Int { conceptCategories.reduce(0) { $0 + $1.count } }

    private var matchingQuizCount: Int {
        questionLoader.getFilteredQuestionCount(
            filters: filterDraft.filterOptions(forCount: false),
            progressManager: progressManager
        )
    }

    private var conceptColumnCount: Int {
        if viewportWidth >= LayoutMetrics.macTripleColumnBreakpoint { return 3 }
        if viewportWidth >= 640 { return 2 }
        return 1
    }

    private var conceptGridColumns: [GridItem] {
        (0..<conceptColumnCount).map { _ in
            GridItem(.flexible(), spacing: StudiumDesignSystem.spacingLG, alignment: .top)
        }
    }

    var body: some View {
        Group {
            if let error = questionLoader.error {
                StudiumEmptyState(
                    title: "Could not load questions",
                    message: error.localizedDescription,
                    systemImage: "exclamationmark.triangle",
                    primaryActionTitle: "Retry",
                    primaryAction: { questionLoader.reload() }
                )
            } else if questionLoader.isLoading && questionLoader.questions.isEmpty {
                StudiumEmptyState(
                    title: "Loading question bank",
                    message: nil,
                    systemImage: "arrow.down.circle"
                )
                .overlay { ProgressView() }
            } else if useWideSplit {
                widePracticeSplitLayout
            } else {
                compactPracticeLayout
            }
        }
        .background(Color.systemGroupedBackground)
        .trackViewportWidth($viewportWidth)
        .task(id: conceptFilters) { await recomputeConcepts() }
        .onAppear {
            quizStateManager.loadAllQuizStates()
            applyModulePresetIfNeeded()
        }
        .onChange(of: initialModule) { _, _ in applyModulePresetIfNeeded() }
        .sheet(isPresented: $showFilterSheet) {
            PracticeFilterSheet(
                questionLoader: questionLoader,
                progressManager: progressManager,
                mode: .startQuiz(onStart: onStartQuiz),
                draft: $filterDraft
            )
            #if os(iOS)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            #endif
        }
        .alert("No questions match", isPresented: $showEmptyQuizAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Adjust filters and try again.")
        }
        #if os(iOS)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !useWideSplit, !StudiumDesignSystem.isPhone {
                phoneStickyStartBar
            }
        }
        #endif
    }

    // MARK: - Wide layout

    private var widePracticeSplitLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            practiceFilterSidebar
            Divider()
            practiceMainColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebarWidth: CGFloat {
        #if os(iOS)
        StudiumDesignSystem.isPad ? StudiumDesignSystem.practiceSidebarWidthIPad : StudiumDesignSystem.practiceSidebarWidth
        #else
        StudiumDesignSystem.practiceSidebarWidth
        #endif
    }

    private var practiceFilterSidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
                .padding(.horizontal, StudiumDesignSystem.practiceSidebarHeaderPadding)
                .padding(.top, StudiumDesignSystem.practiceSidebarHeaderPadding)
                .padding(.bottom, StudiumDesignSystem.spacingSM)

            ScrollView {
                PracticeFilterPanel(draft: $filterDraft, columns: sidebarChipGridColumns)
                    .padding(.horizontal, StudiumDesignSystem.practiceSidebarPadding)
                    .padding(.bottom, StudiumDesignSystem.spacingLG)
            }

            sidebarFooter
        }
        .frame(width: sidebarWidth)
        .frame(maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
        .environment(\.filterSidebarLayout, true)
        .environment(\.filterPanelDensity, .standard)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            Text("Filters")
                .font(.title2.weight(.semibold))
            HStack(spacing: StudiumDesignSystem.spacingSM) {
                Text("\(matchingQuizCount)")
                    .font(StudiumDesignSystem.statDigitFont)
                    .foregroundStyle(matchingQuizCount > 0 ? Color.accentColor : .secondary)
                Text(matchingQuizCount == 1 ? "question matches" : "questions match")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Divider()
            StudiumPrimaryButton(
                title: "Start \(matchingQuizCount)",
                systemImage: "play.fill",
                isDisabled: matchingQuizCount == 0
            ) {
                startQuizFromDraft()
            }
            .padding(StudiumDesignSystem.practiceSidebarFooterPadding)
        }
        .background(Color.systemBackground)
        .studiumTopEdgeShadow()
    }

    private var sidebarChipGridColumns: [GridItem] {
        FilterPanelMetrics.sidebarChipColumns
    }

    // MARK: - Compact layout

    private var compactPracticeLayout: some View {
        VStack(spacing: 0) {
            compactFilterHeader
            Divider()
            practiceMainColumn
        }
    }

    private var compactFilterHeader: some View {
        HStack(alignment: .center, spacing: StudiumDesignSystem.spacingMD) {
            Button {
                showFilterSheet = true
            } label: {
                if StudiumDesignSystem.isPhone {
                    HStack(spacing: StudiumDesignSystem.spacingSM) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                        Text("Filters")
                            .font(.subheadline.weight(.semibold))
                        if matchingQuizCount > 0 {
                            Text("\(matchingQuizCount)")
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                } else {
                    HStack(spacing: StudiumDesignSystem.spacingSM) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("\(matchingQuizCount)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(matchingQuizCount > 0 ? Color.accentColor : .secondary)
                                    .monospacedDigit()
                                Text(matchingQuizCount == 1 ? "question" : "questions")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(filterSummaryLine)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filters, \(matchingQuizCount) matching")

            #if os(iOS)
            if StudiumDesignSystem.isPhone {
                phoneHeaderStartButton
            }
            #endif
        }
        .padding(.horizontal, StudiumDesignSystem.practiceMainPaddingH)
        .padding(.vertical, StudiumDesignSystem.spacingSM)
        .background(Color.systemBackground)
    }

    private var phoneHeaderStartButton: some View {
        Button(action: startQuizFromDraft) {
            Image(systemName: "play.fill")
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .disabled(matchingQuizCount == 0)
        .accessibilityLabel(matchingQuizCount > 0 ? "Start \(matchingQuizCount) questions" : "Start quiz")
    }

    private var filterSummaryLine: String {
        let parts = filterDraft.summaryParts
        return parts.isEmpty ? "All questions · tap to filter" : parts.joined(separator: " · ")
    }

    private var phoneStickyStartBar: some View {
        StudiumPrimaryButton(
            title: matchingQuizCount > 0 ? "Start \(matchingQuizCount)" : "Start",
            systemImage: "play.fill",
            isDisabled: matchingQuizCount == 0,
            action: startQuizFromDraft
        )
        .padding(.horizontal, StudiumDesignSystem.practicePhoneStickyBarPadding)
        .padding(.vertical, StudiumDesignSystem.spacingSM)
        .background(.bar)
    }

    // MARK: - Main column

    private var practiceMainColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StudiumDesignSystem.practiceMainSectionSpacing) {
                if !quizStateManager.savedQuizzes.isEmpty {
                    continueSection
                }
                browseTitleRow
                conceptSkillPicker
                conceptCardsGrid
            }
            .padding(.horizontal, StudiumDesignSystem.practiceMainPaddingH)
            .padding(.top, StudiumDesignSystem.practiceMainPaddingTop)
            .padding(.bottom, phoneMainBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .environment(\.filterPhoneSheetLayout, !useWideSplit && StudiumDesignSystem.isPhone)
        #endif
    }

    private var phoneMainBottomPadding: CGFloat {
        #if os(iOS)
        if useWideSplit || StudiumDesignSystem.isPhone {
            return StudiumDesignSystem.practiceMainPaddingBottom
        }
        return StudiumDesignSystem.practiceMainPaddingBottom + 56
        #else
        StudiumDesignSystem.practiceMainPaddingBottom
        #endif
    }

    private var usePhoneContinueCards: Bool {
        #if os(iOS)
        StudiumDesignSystem.isPhone && !useWideSplit
        #else
        false
        #endif
    }

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            FilterStripSectionTitle(text: "Continue")
            if usePhoneContinueCards {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: StudiumDesignSystem.spacingMD) {
                        ForEach(quizStateManager.savedQuizzes.prefix(3)) { quiz in
                            continueCard(for: quiz, phoneLayout: true)
                                .frame(width: 260)
                        }
                    }
                }
            } else {
                continueHorizontalScroll
            }
        }
    }

    private var continueHorizontalScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: StudiumDesignSystem.spacingMD) {
                ForEach(quizStateManager.savedQuizzes.prefix(5)) { quiz in
                    continueCard(for: quiz)
                }
            }
        }
    }

    private func continueCard(for quiz: QuizState, phoneLayout: Bool = false) -> some View {
        let answered = quiz.answerStates.values.filter { $0.hasSubmitted }.count
        return ContinueSavedQuizCard(
            title: quiz.filterDescription(),
            answered: answered,
            total: quiz.questionIds.count,
            usePhoneLayout: phoneLayout,
            onPlay: { onResumeQuiz(quiz) },
            onDelete: { quizStateManager.deleteQuizState(id: quiz.id) }
        )
    }

    private var browseTitleRow: some View {
        StudiumSectionHeader(
            title: StudiumDesignSystem.isPhone ? "Concepts" : "Browse by concept",
            subtitle: StudiumDesignSystem.isPhone
                ? (isComputingConcepts ? "Updating…" : "\(totalCount) Qs")
                : (isComputingConcepts ? "Updating counts…" : "\(totalCount) questions")
        )
    }

    private var conceptSkillOptions: [String] {
        questionLoader.getAvailableSkillDescs(for: nil, primaryClass: nil)
    }

    private var conceptSkillPicker: some View {
        let skillPickerMinHeight: CGFloat = StudiumDesignSystem.isPhone
            ? StudiumDesignSystem.filterSidebarChipMinHeight
            : StudiumDesignSystem.filterChipMinHeight

        return Group {
            #if os(iOS)
            if StudiumDesignSystem.isPhone && !useWideSplit {
                phoneSkillPicker(minHeight: skillPickerMinHeight)
            } else {
                skillPickerCard(minHeight: skillPickerMinHeight)
            }
            #else
            skillPickerCard(minHeight: skillPickerMinHeight)
            #endif
        }
    }

    private func phoneSkillPicker(minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingXS) {
            Text("Skill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            skillPickerControl(minHeight: minHeight)
        }
    }

    private func skillPickerCard(minHeight: CGFloat) -> some View {
        FilterFormCard(spacing: StudiumDesignSystem.spacingSM) {
            FilterGroupBlock(title: "Skill", systemImage: "target", tint: Color.accentColor) {
                skillPickerControl(minHeight: minHeight)
            }
        }
    }

    private func skillPickerControl(minHeight: CGFloat) -> some View {
        Picker(selection: $filterDraft.skillDesc) {
            Text("All skills").tag(Optional<String>.none)
            ForEach(conceptSkillOptions, id: \.self) { skill in
                Text(skill).tag(Optional(skill))
            }
        } label: {
            HStack(spacing: StudiumDesignSystem.spacingSM) {
                Text(filterDraft.skillDesc ?? "All skills")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, StudiumDesignSystem.filterChipHPadding)
            .padding(.vertical, StudiumDesignSystem.filterChipVPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: FilterPanelMetrics.filterChipCardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FilterPanelMetrics.filterChipCardCorner, style: .continuous)
                    .strokeBorder(Color.studiumBorder, lineWidth: FilterStyle.chipStrokeWidth)
            )
        }
        .labelsHidden()
    }

    private var conceptCardsGrid: some View {
        let accentColors = phoneConceptAccents
        return Group {
            if isComputingConcepts && conceptCategories.isEmpty {
                VStack(spacing: StudiumDesignSystem.spacingMD) {
                    ProgressView()
                    Text("Counting questions…")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if conceptCategories.isEmpty {
                StudiumEmptyState(
                    title: "No questions match",
                    message: "Change filters to see concept cards.",
                    systemImage: "line.3.horizontal.decrease.circle",
                    primaryActionTitle: "Filters",
                    primaryAction: { showFilterSheet = true }
                )
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: conceptGridColumns, alignment: .leading, spacing: StudiumDesignSystem.conceptGridSpacing) {
                    ForEach(Array(conceptCategories.enumerated()), id: \.element.id) { index, category in
                        ExpandedConceptCard(
                            category: category,
                            accentColor: accentColors[index % accentColors.count],
                            onPractice: { startConceptQuiz(categoryId: category.id) },
                            onPracticeSkill: { skill in startConceptQuiz(categoryId: category.id, skill: skill) }
                        )
                    }
                }
            }
        }
    }

    private var phoneConceptAccents: [Color] {
        #if os(iOS)
        if StudiumDesignSystem.isPhone && !useWideSplit {
            return Array(repeating: Color.accentColor, count: 4)
        }
        #endif
        return [.blue, .indigo, .purple, .teal]
    }

    private func startQuizFromDraft() {
        let filters = filterDraft.filterOptions(forCount: false)
        let count = questionLoader.getFilteredQuestionCount(filters: filters, progressManager: progressManager)
        guard count > 0 else {
            showEmptyQuizAlert = true
            return
        }
        onStartQuiz(filters)
    }

    private func startConceptQuiz(categoryId: String, skill: String? = nil) {
        var f = filterDraft.conceptFilterOptions()
        f.primaryClassCdDesc = categoryId
        f.skillDesc = skill
        f.shuffled = filterDraft.shuffled
        onStartQuiz(f)
    }

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

    private func applyModulePresetIfNeeded() {
        guard let module = initialModule else { return }
        filterDraft.module = module
        onConsumeModulePreset?()
    }
}
