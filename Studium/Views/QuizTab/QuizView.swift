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
    @Binding var showFilters: Bool
    @Binding var savedQuestionIds: [String]
    @Binding var currentQuizId: String?
    var onEndQuiz: (() -> Void)? = nil

    @State private var currentIndex = 0

    private let quizStateManager = QuizStateManager.shared
    @State private var selectedAnswerId: String?
    @State private var freeResponseText: String = ""
    @State private var hasSubmitted = false
    @State private var showExplanation = false
    @State private var passageHeight: CGFloat?
    @State private var questionStemHeight: CGFloat?
    @State private var explanationHeight: CGFloat?
    @State private var answerHeights: [String: CGFloat] = [:]
    @State private var showQuestionJumper = false
    /// macOS: measured from the question `ScrollView` / split pane for adaptive column width.
    @State private var quizDetailPaneWidth: CGFloat = 720

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var isFreeResponse: Bool {
        currentQuestion?.content.displayAnswerOptions.isEmpty == true
    }

    /// macOS always; iPad regular uses the same split-pane quiz as macOS.
    private var useSplitPaneQuizLayout: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass == .regular
        #endif
    }

    private var questionContentBlockSpacing: CGFloat {
        useSplitPaneQuizLayout ? MacStudiumDesign.quizBlockSpacing : 20
    }

    /// Passage HTML body scale in the webview (split-pane and single-column share Mac baseline).
    private var passageHTMLFontPoints: CGFloat { 17 }

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

    var body: some View {
        Group {
            if questions.isEmpty {
                emptyStateView
            } else if let question = currentQuestion {
                questionView(question: question)
            }
        }
        .navigationTitle("Quiz")
        .navInlineTitle()
        .toolbar {
            ToolbarItem(placement: .navLeading) {
                Button {
                    saveAndExit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Save & Exit")
                            .font(.subheadline)
                    }
                }
            }
            ToolbarItem(placement: .navTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showQuestionJumper) {
            questionJumperSheet
                .presentationDetentsMediumLarge()
        }
        // Keyboard shortcuts (iOS 17+ / macOS 14+)
        .onKeyPress(.leftArrow)  { previousQuestion(); return .handled }
        .onKeyPress(.rightArrow) { nextQuestion();     return .handled }
        .onKeyPress(.return) {
            if !hasSubmitted { submitAnswer() }
            return .handled
        }
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

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No questions found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Try adjusting your filters")
                .foregroundColor(.secondary)
            Button("Change Filters") {
                showFilters = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
                                .frame(minHeight: 40)
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
    /// Uses flexible HStack sizing (no GeometryReader) to avoid zero-width collapse on first layout.
    @ViewBuilder
    private func splitPaneQuestionLayout(question: Question) -> some View {
        let hasStimulus = question.content.displayStimulus != nil
        let columnMax = LayoutMetrics.quizQuestionColumnMaxWidth(paneWidth: quizDetailPaneWidth)

        if hasStimulus {
            HStack(spacing: 0) {
                // Left pane — passage
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Passage", systemImage: "text.book.closed")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        if let stimulus = question.content.displayStimulus {
                            HTMLContentView(
                                htmlContent: stimulus,
                                isScrollable: false,
                                allowInteraction: false,
                                fontSizeOverride: passageHTMLFontPoints,
                                contentProfile: .passage,
                                contentHeight: $passageHeight
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: safeHeight(passageHeight, default: 200))
                        }
                    }
                    .padding(.horizontal, MacStudiumDesign.quizPanePaddingH)
                    .padding(.vertical, MacStudiumDesign.quizPanePaddingV)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .frame(minWidth: 260)
                .background(Color.secondarySystemGroupedBackground)

                Divider()

                // Right pane — question + answers + nav
                ScrollView {
                    questionAndAnswersContent(question: question)
                        .padding(.vertical, MacStudiumDesign.quizPanePaddingV)
                        .padding(.horizontal, MacStudiumDesign.quizPanePaddingH)
                        .frame(maxWidth: columnMax)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .frame(minWidth: 320)
                .trackQuizDetailPaneWidth($quizDetailPaneWidth)
            }
        } else {
            ScrollView {
                questionAndAnswersContent(question: question)
                    .padding(.top, MacStudiumDesign.quizPanePaddingV)
                    .padding(.horizontal, MacStudiumDesign.quizPanePaddingH)
                    .frame(maxWidth: columnMax)
                    .frame(maxWidth: .infinity)
            }
            .trackQuizDetailPaneWidth($quizDetailPaneWidth)
        }
    }

    // MARK: - iOS single-column layout

    private func iOSQuestionScrollView(question: Question, geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                questionMetaBadges(question: question)
                    .padding(.horizontal)

                if let stimulus = question.content.displayStimulus {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Passage", systemImage: "text.book.closed")
                            .padding(.horizontal)
                        HTMLContentView(
                            htmlContent: stimulus,
                            isScrollable: false,
                            allowInteraction: false,
                            fontSizeOverride: passageHTMLFontPoints,
                            contentProfile: .passage,
                            contentHeight: $passageHeight
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: safeHeight(passageHeight, default: 100))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 22)
                            .background(Color.tertiarySystemGroupedBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }

                questionAndAnswersContent(question: question)
            }
            .padding(.top, 12)
            .frame(maxWidth: min(geometry.size.width, 800))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Shared question + answers content

    @ViewBuilder
    private func questionAndAnswersContent(question: Question) -> some View {
        let answerOptions = question.content.displayAnswerOptions

        VStack(alignment: .leading, spacing: questionContentBlockSpacing) {
            if useSplitPaneQuizLayout {
                questionMetaBadges(question: question)
            }

            // Question stem
            if let stem = question.content.displayStem {
                VStack(alignment: .leading, spacing: 8) {
                    quizHorizontalPaddingIOS {
                        sectionLabel("Question", systemImage: "questionmark.circle")
                    }
                    quizHorizontalPaddingIOS {
                        HTMLContentView(
                            htmlContent: stem,
                            isScrollable: false,
                            allowInteraction: false,
                            fontSizeOverride: quizBlockHTMLFontOverride,
                            contentProfile: .quizFigures,
                            contentHeight: $questionStemHeight
                        )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: safeHeight(questionStemHeight, default: 100))
                    }
                }
            }

            // Answer options or free-response input
            if !answerOptions.isEmpty {
                quizHorizontalPaddingIOS {
                    VStack(alignment: .leading, spacing: 8) {
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

            // Submit button
            if !hasSubmitted {
                let canSubmit = answerOptions.isEmpty
                    ? !freeResponseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    : selectedAnswerId != nil
                quizHorizontalPaddingIOS {
                    Button(action: submitAnswer) {
                        Text("Submit Answer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .modifier(QuizSplitPaneLargeControlSize(enabled: useSplitPaneQuizLayout))
                    .disabled(!canSubmit)
                }
            } else {
                quizHorizontalPaddingIOS {
                    resultBanner(question: question)
                }
            }

            // Explanation (top-level or nested under `answer` in JSON)
            if showExplanation {
                if let rationale = question.content.displayRationale {
                    VStack(alignment: .leading, spacing: 8) {
                        quizHorizontalPaddingIOS {
                            sectionLabel("Explanation", systemImage: "lightbulb.fill")
                                .foregroundColor(.orange)
                        }
                        quizHorizontalPaddingIOS {
                            HTMLContentView(
                                htmlContent: rationale,
                                isScrollable: false,
                                allowInteraction: false,
                                fontSizeOverride: quizBlockHTMLFontOverride,
                                contentProfile: .quizFigures,
                                contentHeight: $explanationHeight
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: safeHeight(explanationHeight, default: 100))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        quizHorizontalPaddingIOS {
                            sectionLabel("Explanation", systemImage: "lightbulb.fill")
                                .foregroundColor(.orange)
                        }
                        quizHorizontalPaddingIOS {
                            Text("No written explanation is included for this item.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.06))
                                .cornerRadius(12)
                        }
                    }
                }
            }

            quizHorizontalPaddingIOS {
                navigationButtons
            }
            .padding(.bottom, useSplitPaneQuizLayout ? 16 : 20)
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(useSplitPaneQuizLayout ? Font.subheadline.weight(.semibold) : Font.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.systemGray5)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)))
                }
            }
            .frame(height: 3)

            HStack {
                Button {
                    showQuestionJumper = true
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Q \(currentIndex + 1)/\(questions.count)")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        if let qid = currentQuestion?.questionId {
                            Text("ID: \(qid)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Spacer()

                if answeredCount > 0 {
                    HStack(spacing: 12) {
                        Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Label("\(answeredCount - correctCount)", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, useSplitPaneQuizLayout ? MacStudiumDesign.quizProgressHeaderPaddingH : 16)
        }
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
        quizHorizontalPaddingIOS {
            VStack(alignment: .leading, spacing: 10) {
                Label("Your Answer", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    TextField("e.g. 5, 1/2, 3.14", text: $freeResponseText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(hasSubmitted)
                        .autocorrectionDisabled()
                        .autocapitalizationOff()
                        .font(.body.monospacedDigit())

                    if hasSubmitted {
                        let isCorrect = getCurrentQuestionCorrectness() == true
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                            .font(.title3)
                    }
                }

                if !hasSubmitted {
                    Text("Fractions (e.g. 3/4), decimals (.75), and whole numbers are all accepted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
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

    // MARK: - Answer Option

    private func answerOptionView(
        option: AnswerOption,
        index: Int,
        question: Question,
        isSelected: Bool,
        isCorrect: Bool,
        showResult: Bool
    ) -> some View {
        let label = option.label ?? String(Character(UnicodeScalar(65 + index)!))
        let answerHeight = Binding<CGFloat?>(
            get: { answerHeights[option.id] },
            set: { answerHeights[option.id] = $0 }
        )

        let borderColor: Color = {
            if showResult && isCorrect { return .green }
            if showResult && isSelected && !isCorrect { return .red }
            if isSelected { return .blue }
            return Color.systemGray4
        }()

        let bgColor: Color = {
            if showResult && isCorrect { return .green.opacity(0.08) }
            if showResult && isSelected && !isCorrect { return .red.opacity(0.08) }
            if isSelected { return .blue.opacity(0.08) }
            return Color.secondarySystemGroupedBackground
        }()

        return Button(action: {
            if !hasSubmitted {
                selectedAnswerId = option.id
            }
        }) {
            HStack(alignment: .top, spacing: useSplitPaneQuizLayout ? 16 : 12) {
                Text(label)
                    .font(useSplitPaneQuizLayout ? Font.body.weight(.bold) : Font.subheadline.weight(.bold))
                    .frame(
                        width: useSplitPaneQuizLayout ? 40 : 32,
                        height: useSplitPaneQuizLayout ? 40 : 32,
                        alignment: .center
                    )
                    .background(isSelected ? (showResult ? (isCorrect ? Color.green : Color.red) : Color.blue) : Color.systemGray5)
                    .foregroundColor(isSelected ? .white : .primary)
                    .clipShape(Circle())

                HTMLContentView(
                    htmlContent: option.content,
                    isScrollable: false,
                    allowInteraction: false,
                    compact: true,
                    fontSizeOverride: quizBlockHTMLFontOverride,
                    contentProfile: .quizFigures,
                    contentHeight: answerHeight
                )
                    .frame(minWidth: 1)
                    .frame(height: safeHeight(answerHeight.wrappedValue, default: useSplitPaneQuizLayout ? 52 : 40))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)

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
            .padding(useSplitPaneQuizLayout ? 14 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: useSplitPaneQuizLayout ? 14 : 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: useSplitPaneQuizLayout ? 14 : 12)
                            .stroke(borderColor, lineWidth: isSelected || (showResult && isCorrect) ? 2 : 1)
                    )
            )
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
        passageHeight = nil
        questionStemHeight = nil
        explanationHeight = nil
        answerHeights.removeAll()
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
            isCorrect: correctValue
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
        freeResponseText = question.content.displayAnswerOptions.isEmpty
            ? (answerState.selectedAnswerId ?? "")
            : ""
        passageHeight = nil
        questionStemHeight = nil
        explanationHeight = nil
        answerHeights.removeAll()
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

    private func safeHeight(_ height: CGFloat?, default: CGFloat = 100) -> CGFloat {
        let raw: CGFloat
        if let height = height, height.isFinite && height > 0 && height < 10000 {
            raw = max(height, `default`)
        } else {
            raw = `default`
        }
        #if os(iOS)
        let scale = UIScreen.main.scale
        return (raw * scale).rounded(.toNearestOrAwayFromZero) / scale
        #else
        return raw
        #endif
    }

    private func saveAndExit() {
        saveQuizState()
        if let onEndQuiz = onEndQuiz {
            onEndQuiz()
        } else {
            showFilters = true
        }
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
                isCorrect: correctValue
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
