//
//  PracticeFilterSheet.swift
//  Studium
//

import SwiftUI

/// Full filter panel (program, module, class, skill, difficulty, status, CB pool, order, limit).
struct PracticeFilterSheet: View {
    enum Mode {
        case practiceBrowse
        case startQuiz(onStart: (FilterOptions) -> Void)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager

    let mode: Mode
    @Binding var draft: PracticeFilterDraft

    private var previewFilters: FilterOptions { draft.filterOptions(forCount: true) }

    private var matchingCount: Int {
        questionLoader.getFilteredQuestionCount(filters: previewFilters, progressManager: progressManager)
    }

    private var effectiveCount: Int {
        if draft.useQuestionLimit, let limit = draft.questionLimit, limit > 0 {
            return min(limit, matchingCount)
        }
        return matchingCount
    }

    private var useWideFilterColumns: Bool {
        horizontalSizeClass == .regular
    }

    private var usesPhoneSheetLayout: Bool {
        #if os(iOS)
        StudiumDesignSystem.isPhone
        #else
        false
        #endif
    }

    private var chipGridColumns: [GridItem] {
        #if os(macOS)
        FilterPanelMetrics.filterChipGridColumns(columnCount: 4)
        #else
        if useWideFilterColumns {
            FilterPanelMetrics.filterChipGridColumns(columnCount: 3)
        } else {
            FilterPanelMetrics.sidebarChipColumns
        }
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: StudiumDesignSystem.spacingLG) {
                    questionCountCard
                    PracticeFilterPanel(draft: $draft, columns: chipGridColumns)
                }
                .padding(.horizontal, sheetHorizontalPadding)
                .padding(.top, StudiumDesignSystem.spacingMD)
                .padding(.bottom, StudiumDesignSystem.spacingXXL)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("Filters")
            .navInlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if case .startQuiz = mode, !usesPhoneSheetLayout {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Start \(effectiveCount)") { startQuiz() }
                            .fontWeight(.semibold)
                            .disabled(matchingCount == 0)
                    }
                }
            }
            #if os(iOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if usesPhoneSheetLayout, case .startQuiz = mode {
                    phoneSheetStartBar
                }
            }
            #endif
        }
        .environment(\.filterPanelDensity, .standard)
        .environment(\.filterPhoneSheetLayout, usesPhoneSheetLayout)
    }

    private var sheetHorizontalPadding: CGFloat {
        #if os(iOS)
        StudiumDesignSystem.isPhone
            ? StudiumDesignSystem.practiceMainPaddingH
            : StudiumDesignSystem.spacingLG
        #else
        StudiumDesignSystem.spacingLG
        #endif
    }

    private var questionCountCard: some View {
        FilterFormCard {
            VStack(spacing: StudiumDesignSystem.spacingXS) {
                Text("\(effectiveCount)")
                    .font(StudiumDesignSystem.statDigitFont)
                    .foregroundStyle(matchingCount > 0 ? Color.accentColor : .secondary)
                Text(effectiveCount == 1 ? "question available" : "questions available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, StudiumDesignSystem.spacingSM)
        }
    }

    #if os(iOS)
    private var phoneSheetStartBar: some View {
        StudiumPrimaryButton(
            title: "Start \(effectiveCount)",
            systemImage: "play.fill",
            isDisabled: matchingCount == 0,
            action: startQuiz
        )
        .padding(.horizontal, StudiumDesignSystem.practiceMainPaddingH)
        .padding(.vertical, StudiumDesignSystem.spacingSM)
        .background(.bar)
    }
    #endif

    private func startQuiz() {
        let filters = draft.filterOptions(forCount: false)
        if case .startQuiz(let onStart) = mode {
            onStart(filters)
        }
        dismiss()
    }
}

// MARK: - Shared filter panel (sidebar + sheet)

struct PracticeFilterPanel: View {
    @Environment(\.filterSidebarLayout) private var filterSidebarLayout

    @Binding var draft: PracticeFilterDraft
    let columns: [GridItem]

    @Environment(\.filterPhoneSheetLayout) private var filterPhoneSheetLayout

    private var gridColumns: [GridItem] {
        if filterSidebarLayout || filterPhoneSheetLayout {
            return FilterPanelMetrics.sidebarChipColumns
        }
        return columns
    }

    private var chipGridSpacing: CGFloat {
        if filterSidebarLayout { return FilterPanelMetrics.sidebarChipGridSpacing }
        if filterPhoneSheetLayout { return FilterPanelMetrics.phoneSheetChipGridSpacing }
        return FilterPanelMetrics.filterChipGridSpacing
    }

    var body: some View {
        FilterFormCard {
            FilterGroupBlock(title: "Difficulty", systemImage: "chart.bar", tint: .orange) {
                filterChipGrid {
                    difficultyChip("All", nil, .blue)
                    difficultyChip("Easy", "E", .green)
                    difficultyChip("Medium", "M", .orange)
                    difficultyChip("Hard", "H", .red)
                }
            }

            panelDivider

            FilterGroupBlock(title: "Answer status", systemImage: "checkmark.circle", tint: .green) {
                filterChipGrid {
                    ForEach(FilterOptions.AnswerStatus.allCases, id: \.self) { status in
                        FilterChipButton(
                            title: answerStatusLabel(status),
                            isSelected: draft.answerStatus == status,
                            accent: .blue,
                            fillsGridCell: true
                        ) {
                            draft.answerStatus = status
                        }
                    }
                }
            }

            panelDivider

            FilterGroupBlock(
                title: QuestionBankFilterLabels.cbVerifiedPoolGroupTitle,
                systemImage: "checkmark.seal.fill",
                tint: .teal
            ) {
                filterChipGrid {
                    FilterChipButton(
                        title: QuestionBankFilterLabels.cbVerifiedChipAll,
                        isSelected: draft.cbVerified == nil,
                        accent: .teal,
                        fillsGridCell: true
                    ) { draft.cbVerified = nil }
                    FilterChipButton(
                        title: QuestionBankFilterLabels.cbVerifiedChipOnly,
                        isSelected: draft.cbVerified == .onlyVerifiedOffCBPracticeTests,
                        accent: .teal,
                        fillsGridCell: true
                    ) {
                        draft.cbVerified = (draft.cbVerified == .onlyVerifiedOffCBPracticeTests)
                            ? nil
                            : .onlyVerifiedOffCBPracticeTests
                    }
                }
            }

            panelDivider

            FilterGroupBlock(title: "Question order", systemImage: "arrow.up.arrow.down", tint: .indigo) {
                filterChipGrid {
                    FilterChipButton(
                        title: "In order",
                        isSelected: !draft.shuffled,
                        accent: .indigo,
                        fillsGridCell: true
                    ) { draft.shuffled = false }
                    FilterChipButton(
                        title: "Shuffle",
                        isSelected: draft.shuffled,
                        accent: .indigo,
                        fillsGridCell: true
                    ) { draft.shuffled = true }
                }
            }

            panelDivider

            FilterGroupBlock(title: "Quiz size", systemImage: "number", tint: .blue) {
                Toggle("Limit question count", isOn: $draft.useQuestionLimit)
                    .font(.subheadline)
                    .tint(.accentColor)
                if draft.useQuestionLimit {
                    filterChipGrid {
                        ForEach([10, 20, 30, 50], id: \.self) { count in
                            FilterChipButton(
                                title: "\(count)",
                                isSelected: draft.questionLimit == count,
                                accent: .blue,
                                fillsGridCell: true
                            ) { draft.questionLimit = count }
                        }
                    }
                }
            }

            panelDivider

            Button {
                draft.reset()
            } label: {
                Label("Reset filters", systemImage: "arrow.counterclockwise")
                    .font(filterSidebarLayout ? .subheadline.weight(.medium) : .body)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .frame(minHeight: filterSidebarLayout ? StudiumDesignSystem.minTapTarget : nil)
        }
    }

    private var panelDivider: some View {
        Divider()
            .padding(.vertical, (filterSidebarLayout || filterPhoneSheetLayout) ? StudiumDesignSystem.spacingXS : 0)
    }

    private func answerStatusLabel(_ status: FilterOptions.AnswerStatus) -> String {
        switch status {
        case .all: return "All"
        case .unanswered: return "New"
        case .incorrect: return "Wrong"
        case .correct: return "Correct"
        }
    }

    private func difficultyChip(_ title: String, _ code: String?, _ accent: Color) -> some View {
        FilterChipButton(title: title, isSelected: draft.difficulty == code, accent: accent, fillsGridCell: true) {
            draft.difficulty = (draft.difficulty == code) ? nil : code
        }
    }

    private func filterChipGrid<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: chipGridSpacing) {
            content()
        }
    }
}

struct PracticeFilterDraft: Equatable {
    var program: String?
    var module: String?
    var primaryClass: String?
    var skillDesc: String?
    var difficulty: String?
    var answerStatus: FilterOptions.AnswerStatus = .all
    var cbVerified: FilterOptions.CBVerifiedInactiveFilter?
    var shuffled: Bool = true
    var questionLimit: Int?
    var useQuestionLimit: Bool = false

    func filterOptions(forCount: Bool) -> FilterOptions {
        FilterOptions(
            program: program,
            module: module,
            primaryClassCdDesc: primaryClass,
            skillDesc: skillDesc,
            difficulty: difficulty,
            answerStatus: answerStatus,
            isBluebook: nil,
            cbVerifiedInactive: cbVerified,
            shuffled: forCount ? false : shuffled,
            questionLimit: useQuestionLimit ? questionLimit : nil
        )
    }

    func conceptFilterOptions() -> FilterOptions {
        FilterOptions(
            module: nil,
            primaryClassCdDesc: nil,
            skillDesc: skillDesc,
            difficulty: difficulty,
            answerStatus: answerStatus,
            isBluebook: nil,
            cbVerifiedInactive: cbVerified,
            shuffled: false,
            questionLimit: nil
        )
    }

    mutating func reset() {
        program = nil
        module = nil
        primaryClass = nil
        skillDesc = nil
        difficulty = nil
        answerStatus = .all
        cbVerified = nil
        shuffled = true
        questionLimit = nil
        useQuestionLimit = false
    }

    var summaryParts: [String] {
        var parts: [String] = []
        if let skillDesc { parts.append(skillDesc) }
        if let difficulty {
            switch difficulty {
            case "E": parts.append("Easy")
            case "M": parts.append("Medium")
            case "H": parts.append("Hard")
            default: parts.append(difficulty)
            }
        }
        switch answerStatus {
        case .unanswered: parts.append("New")
        case .incorrect: parts.append("Wrong")
        case .correct: parts.append("Correct")
        case .all: break
        }
        if cbVerified == .onlyVerifiedOffCBPracticeTests {
            parts.append("CB verified")
        }
        if shuffled { parts.append("Shuffle") }
        return parts
    }
}
