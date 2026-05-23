//
//  QuizView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct QuizView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    let questions: [Question]
    @Binding var filters: FilterOptions
    @Binding var savedQuestionIds: [String]
    @Binding var currentQuizId: String?
    var resumeIssue: String? = nil
    var onEndQuiz: (() -> Void)? = nil

    @State private var currentIndex = 0

    private let quizStateManager = QuizStateManager.shared
    @State private var selectedAnswerId: String?
    @State private var freeResponseText: String = ""
    @State private var hasSubmitted = false
    @State private var showExplanation = false
    @State private var passageSplitFraction: Double = UserDefaults.standard.object(forKey: "studium-passage-split-pct") as? Double ?? 0.5
    @State private var mathSplitFraction: Double = UserDefaults.standard.object(forKey: "studium-math-desmos-split-pct") as? Double ?? 0.4
    @State private var showQuestionJumper = false
    @AppStorage("htmlFontSize") private var htmlFontSize: Double = 16.0
    @AppStorage("passageFontSize") private var passageFontSize: Double = 17.0
    @State private var showFontSizePopover = false
    @State private var strikeoutModeEnabled = false
    @State private var struckOutOptionIds: Set<String> = []
    @State private var highlightModeEnabled = false
    /// macOS: measured from the question `ScrollView` / split pane for adaptive column width.
    @State private var quizDetailPaneWidth: CGFloat = 720
    /// iOS / iPad: measured from the quiz root so split-pane matches Practice at the same width threshold.
    @State private var quizViewportWidth: CGFloat = 0

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var isFreeResponse: Bool {
        currentQuestion?.content.displayAnswerOptions.isEmpty == true
    }

    /// macOS always split; iOS / iPad use the same width threshold as Practice (`LayoutMetrics.macWideBreakpoint`).
    private var useSplitPaneQuizLayout: Bool {
        #if os(macOS)
        true
        #else
        quizViewportWidth >= LayoutMetrics.macWideBreakpoint
        #endif
    }

    private var questionContentBlockSpacing: CGFloat {
        useSplitPaneQuizLayout ? StudiumDesignSystem.quizBlockSpacing : StudiumDesignSystem.spacingXL
    }

    /// Passage HTML body scale in the webview (split-pane and single-column share Mac baseline).
    private var passageHTMLFontPoints: CGFloat { CGFloat(passageFontSize) }

    /// Stem, explanation, answer rows: optional bump on iPad single-column only.
    private var quizBlockHTMLFontOverride: CGFloat? {
        #if os(iOS)
        useSplitPaneQuizLayout ? nil : (horizontalSizeClass == .regular ? 17 : nil)
        #else
        nil
        #endif
    }

    @ViewBuilder
    private func quizHorizontalPaddingIOS<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        #if os(iOS)
        if useSplitPaneQuizLayout {
            content()
        } else {
            content().padding(.horizontal)
        }
        #else
        content()
        #endif
    }

    private var answeredCount: Int {
        guard let quizId = currentQuizId,
              let state = quizStateManager.loadQuizState(id: quizId) else { return 0 }
        return state.answerStates.values.filter { $0.hasSubmitted }.count
    }

    private var correctCount: Int {
        guard let quizId = currentQuizId,
              let state = quizStateManager.loadQuizState(id: quizId) else { return 0 }
        return state.answerStates.values.filter { $0.isCorrect == true }.count
    }

    private var usePhoneBottomBar: Bool {
        #if os(iOS)
        !useSplitPaneQuizLayout
        #else
        false
        #endif
    }

    private var quizToolbarLeadingPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .navigation
        #else
        .topBarLeading
        #endif
    }

    private var quizToolbarTrailingPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    var body: some View {
        Group {
            if questions.isEmpty {
                emptyStateView
            } else if let question = currentQuestion {
                questionView(question: question)
            }
        }
        .trackViewportWidth($quizViewportWidth)
        .navigationTitle("Quiz")
        .navInlineTitle()
        .toolbar {
            ToolbarItem(placement: quizToolbarLeadingPlacement) {
                Button(action: saveAndExit) {
                    Label("Save & Exit", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .accessibilityLabel("Save and exit quiz")
            }
            ToolbarItemGroup(placement: quizToolbarTrailingPlacement) {
                Button {
                    highlightModeEnabled.toggle()
                } label: {
                    Image(systemName: "highlighter")
                        .symbolVariant(highlightModeEnabled ? .fill : .none)
                }
                .accessibilityLabel(highlightModeEnabled ? "Highlight mode on" : "Highlight text")
                .accessibilityHint("Select passage or question text to highlight")
                .tint(highlightModeEnabled ? .accentColor : nil)

                Button {
                    NotificationCenter.default.post(name: .studiumClearQuizHighlights, object: nil)
                } label: {
                    Image(systemName: "eraser")
                }
                .accessibilityLabel("Clear highlights")
                .help("Remove all highlights on this question")

                Button {
                    strikeoutModeEnabled.toggle()
                } label: {
                    Image(systemName: "strikethrough")
                        .symbolVariant(strikeoutModeEnabled ? .fill : .none)
                }
                .accessibilityLabel(strikeoutModeEnabled ? "Cross-out mode on" : "Cross out answers")
                .accessibilityHint("Tap choices to eliminate them before submitting")
                .tint(strikeoutModeEnabled ? .accentColor : nil)
                .disabled(hasSubmitted)

                Button {
                    showFontSizePopover = true
                } label: {
                    Image(systemName: "textformat.size")
                }
                .accessibilityLabel("Text size")
                .popover(isPresented: $showFontSizePopover, arrowEdge: .top) {
                    fontSizePopover
                }
            }
        }
        .sheet(isPresented: $showQuestionJumper) {
            questionJumperSheet
                .presentationDetentsMediumLarge()
        }
        #if os(iOS)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if usePhoneBottomBar, !questions.isEmpty, currentQuestion != nil {
                phoneQuizBottomBar
            }
        }
        #endif
        // Keyboard shortcuts (iOS 17+ / macOS 14+)
        .onKeyPress(.leftArrow)  { previousQuestion(); return .handled }
        .onKeyPress(.rightArrow) { nextQuestion();     return .handled }
        .onKeyPress(.return) {
            if !hasSubmitted { submitAnswer() }
            return .handled
        }
        .environment(\.studiumTextHighlightingEnabled, highlightModeEnabled)
        .onAppear {
            if let quizId = currentQuizId,
               let savedState = quizStateManager.loadQuizState(id: quizId),
               savedState.questionIds == questions.map({ $0.questionId }),
               savedState.hasActiveQuiz {
                currentIndex = min(savedState.currentIndex, questions.count - 1)
                if let question = currentQuestion,
                   let answerState = savedState.answerStates[question.questionId] {
                    selectedAnswerId = answerState.selectedAnswerId
                    hasSubmitted = answerState.hasSubmitted
                    showExplanation = answerState.hasSubmitted
                    if question.content.displayAnswerOptions.isEmpty {
                        freeResponseText = answerState.selectedAnswerId ?? ""
                    }
                }
            }
            if let question = currentQuestion {
                progressManager.markSeen(questionId: question.questionId)
            }
            saveQuizState()
        }
    }

    private var fontSizePopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Font Size")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .center)

            fontSizeRow(label: "Content", value: $htmlFontSize, min: 13, max: 22)

            if useSplitPaneQuizLayout {
                Divider()
                fontSizeRow(label: "Passage", value: $passageFontSize, min: 13, max: 22)
            }

            Button("Reset") {
                htmlFontSize = 16
                passageFontSize = 17
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        #if os(macOS)
        .frame(minWidth: 200)
        #endif
    }

    private func fontSizeRow(label: String, value: Binding<Double>, min minVal: Double, max maxVal: Double) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 52, alignment: .leading)
            Spacer()
            Button {
                value.wrappedValue = Swift.max(minVal, value.wrappedValue - 1)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue <= minVal)

            Text("\(Int(value.wrappedValue)) pt")
                .font(.body.monospacedDigit())
                .frame(minWidth: 44)

            Button {
                value.wrappedValue = Swift.min(maxVal, value.wrappedValue + 1)
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(value.wrappedValue >= maxVal)
        }
    }

    private var emptyStateView: some View {
        StudiumEmptyState(
            title: resumeIssue != nil ? "Cannot resume quiz" : "No questions in this quiz",
            message: resumeIssue ?? "Try adjusting filters before starting a new quiz.",
            systemImage: "exclamationmark.triangle",
            primaryActionTitle: "End quiz",
            primaryAction: { onEndQuiz?() },
        )
    }

    private var phoneQuizBottomBar: some View {
        QuizBottomBar(
            canGoPrevious: currentIndex > 0,
            canGoNext: currentIndex < questions.count - 1,
            showSubmit: !hasSubmitted,
            nextLabel: currentIndex < questions.count - 1 ? "Next" : "Finish",
            onPrevious: { _ = previousQuestion() },
            onSubmit: submitAnswer,
            onNext: {
                if hasSubmitted {
                    if currentIndex < questions.count - 1 {
                        _ = nextQuestion()
                    } else {
                        saveAndExit()
                    }
                }
            }
        )
    }

    // MARK: - Question Jumper

    private var questionJumperSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        let questionId = questions[index].questionId
                        let answerState: QuestionAnswerState? = {
                            guard let quizId = currentQuizId,
                                  let state = quizStateManager.loadQuizState(id: quizId) else { return nil }
                            return state.answerStates[questionId]
                        }()

                        Button {
                            saveCurrentQuestionState()
                            currentIndex = index
                            restoreQuestionState()
                            if let question = currentQuestion {
                                progressManager.markSeen(questionId: question.questionId)
                            }
                            saveQuizState()
                            showQuestionJumper = false
                        } label: {
                            Text("\(index + 1)")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: StudiumDesignSystem.minTapTarget)
                                .background(questionJumperColor(index: index, answerState: answerState))
                                .foregroundStyle(index == currentIndex ? Color.white : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: FilterStyle.chipCorner))
                                .overlay(
                                    RoundedRectangle(cornerRadius: FilterStyle.chipCorner)
                                        .strokeBorder(
                                            index == currentIndex
                                                ? Color.clear
                                                : Color.primary.opacity(0.12),
                                            lineWidth: FilterStyle.chipStrokeWidth
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Jump to Question")
            .navInlineTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showQuestionJumper = false }
                }
            }
        }
    }

    private func questionJumperColor(index: Int, answerState: QuestionAnswerState?) -> Color {
        if index == currentIndex {
            return Color.accentColor
        }
        guard let state = answerState, state.hasSubmitted else {
            return Color.tertiarySystemFill
        }
        return state.isCorrect == true
            ? Color.green.opacity(colorScheme == .dark ? 0.32 : 0.22)
            : Color.red.opacity(colorScheme == .dark ? 0.32 : 0.22)
    }

    // MARK: - Question View

    private func questionView(question: Question) -> some View {
        VStack(spacing: 0) {
            progressHeader

            if useSplitPaneQuizLayout {
                // Do NOT wrap in GeometryReader — it can report zero size during
                // the initial layout pass of a split column, collapsing WKWebView widths.
                splitPaneQuestionLayout(question: question)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    iOSQuestionScrollView(question: question, geometry: geometry)
                }
            }
        }
    }

    // MARK: - Split-pane layout (macOS + iPad regular)

    /// Questions with a stimulus get passage left, question + answers right (SAT-style).
    /// Math questions get Desmos calculator left, question right.
    /// Uses flexible HStack sizing (no GeometryReader) to avoid zero-width collapse on first layout.
    @ViewBuilder
    private func splitPaneQuestionLayout(question: Question) -> some View {
        let hasStimulus = question.content.displayStimulus != nil
        let isMath = question.module.lowercased() == "math"
        let columnMax = LayoutMetrics.quizQuestionColumnMaxWidth(paneWidth: quizDetailPaneWidth)

        if hasStimulus && !isMath {
            SplitPaneView(fraction: $passageSplitFraction, persistKey: "studium-passage-split-pct") {
                // Left pane — passage
                ScrollView {
                    if let stimulus = question.content.displayStimulus {
                        QuizReadingBlock(
                            title: "Passage",
                            systemImage: "text.book.closed",
                            html: stimulus,
                            fontSizeOverride: passageHTMLFontPoints,
                            profile: .passage,
                            compactHTML: false
                        )
                        .padding(.horizontal, StudiumDesignSystem.quizPanePaddingH)
                        .padding(.vertical, StudiumDesignSystem.quizPanePaddingV)
                    }
                }
                .background(Color.systemGroupedBackground)
            } right: {
                // Right pane — question + answers + nav
                ScrollView {
                    questionAndAnswersContent(question: question)
                        .padding(.vertical, StudiumDesignSystem.quizPanePaddingV)
                        .padding(.horizontal, StudiumDesignSystem.quizPanePaddingH)
                        .frame(maxWidth: columnMax)
                        .frame(maxWidth: .infinity)
                }
                .trackQuizDetailPaneWidth($quizDetailPaneWidth)
            }
        } else if isMath {
            SplitPaneView(fraction: $mathSplitFraction, persistKey: "studium-math-desmos-split-pct") {
                // Left pane — Desmos graphing calculator
                DesmosCalculatorView()
            } right: {
                // Right pane — question + answers + nav (+ inline stimulus if present)
                ScrollView {
                    questionAndAnswersContent(question: question, inlineStimulus: question.content.displayStimulus)
                        .padding(.vertical, StudiumDesignSystem.quizPanePaddingV)
                        .padding(.horizontal, StudiumDesignSystem.quizPanePaddingH)
                        .frame(maxWidth: columnMax)
                        .frame(maxWidth: .infinity)
                }
                .trackQuizDetailPaneWidth($quizDetailPaneWidth)
            }
        } else {
            ScrollView {
                questionAndAnswersContent(question: question)
                    .padding(.top, StudiumDesignSystem.quizPanePaddingV)
                    .padding(.horizontal, StudiumDesignSystem.quizPanePaddingH)
                    .frame(maxWidth: columnMax)
                    .frame(maxWidth: .infinity)
            }
            .trackQuizDetailPaneWidth($quizDetailPaneWidth)
        }
    }

    // MARK: - iOS single-column layout

    private func iOSQuestionScrollView(question: Question, geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingXL) {
                questionMetaBadges(question: question)

                if let stimulus = question.content.displayStimulus {
                    QuizReadingBlock(
                        title: "Passage",
                        systemImage: "text.book.closed",
                        html: stimulus,
                        fontSizeOverride: passageHTMLFontPoints,
                        profile: .passage,
                        compactHTML: false
                    )
                }

                questionAndAnswersContent(question: question)
            }
            .padding(.horizontal, StudiumDesignSystem.spacingLG)
            .padding(.vertical, StudiumDesignSystem.spacingLG)
            .frame(maxWidth: min(geometry.size.width, StudiumDesignSystem.readableMaxWidth))
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color.systemGroupedBackground)
    }

    // MARK: - Shared question + answers content

    @ViewBuilder
    private func questionAndAnswersContent(question: Question, inlineStimulus: String? = nil) -> some View {
        let answerOptions = question.content.displayAnswerOptions

        VStack(alignment: .leading, spacing: questionContentBlockSpacing) {
            if useSplitPaneQuizLayout {
                questionMetaBadges(question: question)
            }

            // Inline stimulus (used for math questions where Desmos occupies the left pane)
            if let stimulus = inlineStimulus {
                QuizReadingBlock(
                    title: "Passage",
                    systemImage: "text.book.closed",
                    html: stimulus,
                    fontSizeOverride: passageHTMLFontPoints,
                    profile: .passage,
                    compactHTML: false
                )
            }

            if let stem = question.content.displayStem {
                QuizReadingBlock(
                    title: "Question",
                    systemImage: "questionmark.circle",
                    html: stem,
                    fontSizeOverride: quizBlockHTMLFontOverride,
                    profile: .quizFigures,
                    compactHTML: true
                )
            }

            if !answerOptions.isEmpty {
                VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
                    Text("Answer choices")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
                        ForEach(Array(answerOptions.enumerated()), id: \.element.id) { index, option in
                            let label = option.label ?? String(Character(UnicodeScalar(65 + index)!))
                            let isCorrect = question.content.displayCorrectAnswer.contains { answer in
                                answer.uppercased() == label.uppercased() || answer.uppercased() == option.id.uppercased()
                            }
                            answerOptionView(
                                option: option,
                                index: index,
                                question: question,
                                isSelected: selectedAnswerId == option.id,
                                isCorrect: isCorrect,
                                showResult: hasSubmitted
                            )
                        }
                    }
                }
            } else {
                freeResponseInputView(question: question)
            }

            if !hasSubmitted {
                let canSubmit = answerOptions.isEmpty
                    ? !freeResponseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    : selectedAnswerId != nil
                Button(action: submitAnswer) {
                    Text("Submit answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: StudiumDesignSystem.minTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .modifier(QuizSplitPaneLargeControlSize(enabled: useSplitPaneQuizLayout))
                .disabled(!canSubmit)
            } else {
                resultBanner(question: question)
            }

            if showExplanation {
                if let rationale = question.content.displayRationale {
                    QuizReadingBlock(
                        title: "Explanation",
                        systemImage: "lightbulb.fill",
                        html: rationale,
                        fontSizeOverride: quizBlockHTMLFontOverride,
                        profile: .quizFigures,
                        compactHTML: true
                    )
                } else {
                    Text("No written explanation is included for this item.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .studiumElevatedCard()
                }
            }

            if !usePhoneBottomBar {
                navigationButtons
                    .padding(.top, StudiumDesignSystem.spacingSM)
            }
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(useSplitPaneQuizLayout ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: StudiumDesignSystem.spacingSM) {
            StudiumProgressBar(
                fraction: Double(currentIndex + 1) / Double(max(questions.count, 1))
            )
            .padding(.horizontal, useSplitPaneQuizLayout ? StudiumDesignSystem.quizProgressHeaderPaddingH : StudiumDesignSystem.spacingLG)

            HStack {
                Button {
                    showQuestionJumper = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Question \(currentIndex + 1) of \(questions.count)")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        if let qid = currentQuestion?.questionId {
                            Text(qid)
                                .font(StudiumDesignSystem.questionIdFont)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .frame(minHeight: StudiumDesignSystem.minTapTarget, alignment: .leading)

                Spacer()

                if answeredCount > 0 {
                    HStack(spacing: StudiumDesignSystem.spacingMD) {
                        Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                        Label("\(answeredCount - correctCount)", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, useSplitPaneQuizLayout ? StudiumDesignSystem.quizProgressHeaderPaddingH : StudiumDesignSystem.spacingLG)

            if strikeoutModeEnabled && !hasSubmitted {
                Text("Tap answer choices to cross them out.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, useSplitPaneQuizLayout ? StudiumDesignSystem.quizProgressHeaderPaddingH : StudiumDesignSystem.spacingLG)
            }

            if highlightModeEnabled {
                Text("Select text to highlight. Highlights stay until you clear them or change questions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, useSplitPaneQuizLayout ? StudiumDesignSystem.quizProgressHeaderPaddingH : StudiumDesignSystem.spacingLG)
            }
        }
        .padding(.vertical, StudiumDesignSystem.spacingSM)
    }

    // MARK: - Question Meta Badges

    private func questionMetaBadges(question: Question) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                FilterBadge(text: question.module.capitalized, accent: .blue)
                FilterBadge(text: difficultyLabel(question.difficulty), accent: difficultyColor(question.difficulty))
                FilterBadge(text: question.primaryClassCdDesc, accent: .purple)
                if question.content.displayAnswerOptions.isEmpty {
                    FilterBadge(text: "Grid-In", accent: .teal)
                }
            }
        }
    }

    private func difficultyLabel(_ d: String) -> String {
        switch d {
        case "E": return "Easy"
        case "M": return "Medium"
        case "H": return "Hard"
        default: return d
        }
    }

    private func difficultyColor(_ d: String) -> Color {
        switch d {
        case "E": return .green
        case "M": return .orange
        case "H": return .red
        default: return .gray
        }
    }

    // MARK: - Free Response Input

    private func freeResponseInputView(question: Question) -> some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
            Label("Your answer", systemImage: "pencil")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: StudiumDesignSystem.spacingMD) {
                TextField("e.g. 5, 1/2, 3.14", text: $freeResponseText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(hasSubmitted)
                    .autocorrectionDisabled()
                    .autocapitalizationOff()
                    .font(.body)

                if hasSubmitted {
                    let isCorrect = getCurrentQuestionCorrectness() == true
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                        .font(.title2)
                }
            }

            if !hasSubmitted {
                Text("Fractions, decimals, and whole numbers are accepted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .studiumElevatedCard()
    }

    // MARK: - Result Banner

    private func resultBanner(question: Question) -> some View {
        let isCorrect = getCurrentQuestionCorrectness() == true
        return HStack {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                if !isCorrect {
                    let correctLabels = question.content.displayCorrectAnswer.joined(separator: ", ")
                    Text("Answer: \(correctLabels)")
                        .font(.subheadline)
                }
            }
            Spacer()
        }
        .padding()
        .background(isCorrect ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
        .foregroundColor(isCorrect ? .green : .red)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func answerOptionContent(option: AnswerOption) -> some View {
        if QuizOptionContent.needsHTMLRendering(option.content) {
            HTMLContentView(
                htmlContent: option.content,
                isScrollable: false,
                allowInteraction: false,
                compact: true,
                fontSizeOverride: quizBlockHTMLFontOverride,
                contentProfile: .quizFigures
            )
            .frame(minWidth: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
        } else {
            Text(QuizOptionContent.plainText(from: option.content))
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Answer Option

    private func toggleStrikeout(for optionId: String) {
        if struckOutOptionIds.contains(optionId) {
            struckOutOptionIds.remove(optionId)
        } else {
            struckOutOptionIds.insert(optionId)
            if selectedAnswerId == optionId {
                selectedAnswerId = nil
            }
        }
    }

    private func answerOptionView(
        option: AnswerOption,
        index: Int,
        question: Question,
        isSelected: Bool,
        isCorrect: Bool,
        showResult: Bool
    ) -> some View {
        let label = option.label ?? String(Character(UnicodeScalar(65 + index)!))
        let isStruckOut = struckOutOptionIds.contains(option.id)

        let borderColor: Color = {
            if showResult && isCorrect { return .green }
            if showResult && isSelected && !isCorrect { return .red }
            if isSelected { return .blue }
            return Color.systemGray4
        }()

        let bgColor: Color = {
            if showResult && isCorrect { return .green.opacity(0.10) }
            if showResult && isSelected && !isCorrect { return .red.opacity(0.10) }
            if isSelected { return .blue.opacity(0.08) }
            return Color.systemBackground
        }()

        return Button(action: {
            guard !hasSubmitted else { return }
            if strikeoutModeEnabled {
                toggleStrikeout(for: option.id)
            } else if !isStruckOut {
                selectedAnswerId = option.id
            }
        }) {
            HStack(alignment: .top, spacing: useSplitPaneQuizLayout ? 16 : 12) {
                Text(label)
                    .font(useSplitPaneQuizLayout ? Font.body.weight(.bold) : Font.subheadline.weight(.bold))
                    .strikethrough(isStruckOut && !showResult, color: .secondary)
                    .frame(
                        width: useSplitPaneQuizLayout ? 40 : 32,
                        height: useSplitPaneQuizLayout ? 40 : 32,
                        alignment: .center
                    )
                    .background(isSelected ? (showResult ? (isCorrect ? Color.green : Color.red) : Color.blue) : Color.systemGray5)
                    .foregroundColor(isSelected ? .white : .primary)
                    .clipShape(Circle())

                answerOptionContent(option: option)
                    .overlay {
                        if isStruckOut && !showResult {
                            Rectangle()
                                .fill(Color.primary.opacity(0.5))
                                .frame(height: 1.5)
                        }
                    }

                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(useSplitPaneQuizLayout ? Font.title2 : Font.title3)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(useSplitPaneQuizLayout ? Font.title2 : Font.title3)
                    }
                }
            }
            .padding(StudiumDesignSystem.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: StudiumDesignSystem.radiusCard, style: .continuous)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: StudiumDesignSystem.radiusCard, style: .continuous)
                            .stroke(borderColor, lineWidth: isSelected || (showResult && isCorrect) ? 2 : 0.5)
                    )
            )
            .opacity(isStruckOut && !showResult ? 0.55 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(hasSubmitted)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                previousQuestion()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .modifier(QuizSplitPaneLargeControlSize(enabled: useSplitPaneQuizLayout))
            .disabled(currentIndex == 0)

            Button {
                nextQuestion()
            } label: {
                HStack {
                    Text(currentIndex < questions.count - 1 ? "Next" : "Finish")
                    Image(systemName: currentIndex < questions.count - 1 ? "chevron.right" : "checkmark")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .modifier(QuizSplitPaneLargeControlSize(enabled: useSplitPaneQuizLayout))
            .disabled(currentIndex >= questions.count - 1)
        }
    }

    // MARK: - Actions

    private func submitAnswer() {
        guard let question = currentQuestion else { return }

        hasSubmitted = true
        showExplanation = true

        let correctAnswers = question.content.displayCorrectAnswer
        let answerOptions = question.content.displayAnswerOptions

        let isCorrect: Bool
        if answerOptions.isEmpty {
            let trimmed = freeResponseText.trimmingCharacters(in: .whitespacesAndNewlines)
            selectedAnswerId = trimmed
            isCorrect = checkFreeResponseCorrect(text: trimmed, correctAnswers: correctAnswers)
        } else {
            guard let selectedId = selectedAnswerId,
                  let selectedOption = answerOptions.first(where: { $0.id == selectedId }),
                  let selectedIndex = answerOptions.firstIndex(where: { $0.id == selectedId }) else { return }
            let selectedLabel = selectedOption.label ?? String(Character(UnicodeScalar(65 + selectedIndex)!))
            isCorrect = correctAnswers.contains { answer in
                answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
            }
        }

        progressManager.markAnswered(questionId: question.questionId, correct: isCorrect)
        saveCurrentQuestionState(isCorrect: isCorrect)
        saveQuizState()
    }

    @discardableResult
    private func previousQuestion() -> Bool {
        guard currentIndex > 0 else { return false }
        saveCurrentQuestionState()
        currentIndex -= 1
        restoreQuestionState()
        if let question = currentQuestion {
            progressManager.markSeen(questionId: question.questionId)
        }
        saveQuizState()
        return true
    }

    @discardableResult
    private func nextQuestion() -> Bool {
        guard currentIndex < questions.count - 1 else { return false }
        saveCurrentQuestionState()
        currentIndex += 1
        restoreQuestionState()
        if let question = currentQuestion {
            progressManager.markSeen(questionId: question.questionId)
        }
        saveQuizState()
        return true
    }

    private func resetQuestionState() {
        selectedAnswerId = nil
        freeResponseText = ""
        hasSubmitted = false
        showExplanation = false
        struckOutOptionIds = []
    }

    private func saveCurrentQuestionState(isCorrect: Bool? = nil) {
        guard let question = currentQuestion,
              let quizId = currentQuizId,
              var savedState = quizStateManager.loadQuizState(id: quizId) else { return }

        let correctValue = isCorrect ?? (hasSubmitted ? getCurrentQuestionCorrectness() : nil)
        let answerState = QuestionAnswerState(
            questionId: question.questionId,
            selectedAnswerId: selectedAnswerId,
            hasSubmitted: hasSubmitted,
            isCorrect: correctValue,
            struckOutOptionIds: Array(struckOutOptionIds)
        )
        savedState.answerStates[question.questionId] = answerState
        quizStateManager.saveQuizState(savedState)
    }

    private func restoreQuestionState() {
        guard let question = currentQuestion,
              let quizId = currentQuizId,
              let savedState = quizStateManager.loadQuizState(id: quizId),
              let answerState = savedState.answerStates[question.questionId] else {
            resetQuestionState()
            return
        }
        selectedAnswerId = answerState.selectedAnswerId
        hasSubmitted = answerState.hasSubmitted
        showExplanation = answerState.hasSubmitted
        struckOutOptionIds = Set(answerState.struckOutOptionIds)
        freeResponseText = question.content.displayAnswerOptions.isEmpty
            ? (answerState.selectedAnswerId ?? "")
            : ""
    }

    private func getCurrentQuestionCorrectness() -> Bool? {
        guard let question = currentQuestion,
              let selectedId = selectedAnswerId else { return nil }

        let correctAnswers = question.content.displayCorrectAnswer
        let answerOptions = question.content.displayAnswerOptions

        if answerOptions.isEmpty {
            return checkFreeResponseCorrect(text: selectedId, correctAnswers: correctAnswers)
        }

        guard let selectedOption = answerOptions.first(where: { $0.id == selectedId }),
              let selectedIndex = answerOptions.firstIndex(where: { $0.id == selectedId }) else { return nil }
        let selectedLabel = selectedOption.label ?? String(Character(UnicodeScalar(65 + selectedIndex)!))

        return correctAnswers.contains { answer in
            answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
        }
    }

    // MARK: - Free Response Helpers

    private func checkFreeResponseCorrect(text: String, correctAnswers: [String]) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }

        for correct in correctAnswers {
            let normalizedCorrect = correct.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalized.caseInsensitiveCompare(normalizedCorrect) == .orderedSame { return true }
            if let userVal = parseNumericAnswer(normalized),
               let correctVal = parseNumericAnswer(normalizedCorrect),
               abs(userVal - correctVal) < 0.0001 { return true }
        }
        return false
    }

    private func parseNumericAnswer(_ s: String) -> Double? {
        if let d = Double(s) { return d }
        if s.hasPrefix("."), let d = Double("0" + s) { return d }
        let parts = s.split(separator: "/", maxSplits: 1)
        if parts.count == 2,
           let num = Double(parts[0].trimmingCharacters(in: .whitespaces)),
           let denom = Double(parts[1].trimmingCharacters(in: .whitespaces)),
           denom != 0 { return num / denom }
        return nil
    }

    // MARK: - Utilities

    private func saveAndExit() {
        saveQuizState()
        onEndQuiz?()
    }

    private func saveQuizState() {
        let quizId = currentQuizId ?? UUID().uuidString

        var existingAnswerStates: [String: QuestionAnswerState] = [:]
        if let existingState = quizStateManager.loadQuizState(id: quizId) {
            existingAnswerStates = existingState.answerStates
        }

        if let question = currentQuestion {
            let correctValue = hasSubmitted ? getCurrentQuestionCorrectness() : nil
            let answerState = QuestionAnswerState(
                questionId: question.questionId,
                selectedAnswerId: selectedAnswerId,
                hasSubmitted: hasSubmitted,
                isCorrect: correctValue,
                struckOutOptionIds: Array(struckOutOptionIds)
            )
            existingAnswerStates[question.questionId] = answerState
        }

        let state = QuizState(
            id: quizId,
            filters: filters,
            currentIndex: currentIndex,
            questionIds: questions.map { $0.questionId },
            answerStates: existingAnswerStates
        )
        currentQuizId = quizId
        quizStateManager.saveQuizState(state)
    }
}

private struct QuizSplitPaneLargeControlSize: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.controlSize(.large)
        } else {
            content
        }
    }
}
