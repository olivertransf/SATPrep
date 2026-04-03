//
//  QuizView.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct QuizView: View {
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
    @State private var hasSubmitted = false
    @State private var showExplanation = false
    @State private var passageHeight: CGFloat?
    @State private var questionStemHeight: CGFloat?
    @State private var explanationHeight: CGFloat?
    @State private var answerHeights: [String: CGFloat] = [:]
    @State private var showQuestionJumper = false

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    // Track quiz-level stats
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showQuestionJumper) {
            questionJumperSheet
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
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(questionJumperColor(index: index, answerState: answerState))
                                .foregroundColor(index == currentIndex ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Jump to Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showQuestionJumper = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func questionJumperColor(index: Int, answerState: QuestionAnswerState?) -> Color {
        if index == currentIndex {
            return .blue
        }
        guard let state = answerState, state.hasSubmitted else {
            return Color(.tertiarySystemGroupedBackground)
        }
        return state.isCorrect == true ? .green.opacity(0.3) : .red.opacity(0.3)
    }

    // MARK: - Question View

    private func questionView(question: Question) -> some View {
        VStack(spacing: 0) {
            // Top progress bar
            progressHeader

            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Difficulty + category badge
                        questionMetaBadges(question: question)
                            .padding(.horizontal)

                        // Stimulus/Passage
                        if let stimulus = question.content.displayStimulus {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Passage", systemImage: "text.book.closed")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                HTMLContentView(htmlContent: stimulus, isScrollable: false, allowInteraction: false, contentHeight: $passageHeight)
                                    .frame(height: safeHeight(passageHeight, default: 100))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }

                        // Question stem
                        if let stem = question.content.displayStem {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Question", systemImage: "questionmark.circle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                HTMLContentView(htmlContent: stem, isScrollable: false, allowInteraction: false, contentHeight: $questionStemHeight)
                                    .frame(height: safeHeight(questionStemHeight, default: 100))
                                    .padding(.horizontal)
                            }
                        }

                        // Answer options
                        let answerOptions = question.content.displayAnswerOptions
                        if !answerOptions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
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
                            .padding(.horizontal)
                        }

                        // Submit button
                        if !hasSubmitted {
                            Button(action: submitAnswer) {
                                Text("Submit Answer")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedAnswerId == nil)
                            .padding(.horizontal)
                        } else {
                            // Result banner
                            resultBanner(question: question)
                                .padding(.horizontal)
                        }

                        // Explanation
                        if showExplanation, let rationale = question.content.rationale {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Explanation", systemImage: "lightbulb")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal)
                                HTMLContentView(htmlContent: rationale, isScrollable: false, allowInteraction: false, contentHeight: $explanationHeight)
                                    .frame(height: safeHeight(explanationHeight, default: 100))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.08))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }

                        // Navigation buttons
                        navigationButtons
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 12)
                    .frame(maxWidth: min(geometry.size.width, 800))
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)))
                }
            }
            .frame(height: 3)

            // Question counter + stats
            HStack {
                Button {
                    showQuestionJumper = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Q \(currentIndex + 1)/\(questions.count)")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
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
            .padding(.horizontal)
        }
    }

    // MARK: - Question Meta Badges

    private func questionMetaBadges(question: Question) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                badge(question.module.capitalized, color: .blue)
                badge(difficultyLabel(question.difficulty), color: difficultyColor(question.difficulty))
                badge(question.primaryClassCdDesc, color: .purple)
            }
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(6)
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
            return Color(.systemGray4)
        }()

        let bgColor: Color = {
            if showResult && isCorrect { return .green.opacity(0.08) }
            if showResult && isSelected && !isCorrect { return .red.opacity(0.08) }
            if isSelected { return .blue.opacity(0.08) }
            return Color(.secondarySystemGroupedBackground)
        }()

        return Button(action: {
            if !hasSubmitted {
                selectedAnswerId = option.id
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Label circle
                Text(label)
                    .font(.subheadline.weight(.bold))
                    .frame(width: 32, height: 32, alignment: .center)
                    .background(isSelected ? (showResult ? (isCorrect ? Color.green : Color.red) : Color.blue) : Color(.systemGray5))
                    .foregroundColor(isSelected ? .white : .primary)
                    .clipShape(Circle())

                // Content
                HTMLContentView(htmlContent: option.content, isScrollable: false, allowInteraction: false, contentHeight: answerHeight)
                    .frame(height: safeHeight(answerHeight.wrappedValue, default: 40))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)

                // Result indicator
                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
            .disabled(currentIndex >= questions.count - 1)
        }
    }

    // MARK: - Actions

    private func submitAnswer() {
        guard let question = currentQuestion,
              let selectedId = selectedAnswerId else { return }

        hasSubmitted = true
        showExplanation = true

        let correctAnswers = question.content.displayCorrectAnswer
        let answerOptions = question.content.displayAnswerOptions

        guard let selectedOption = answerOptions.first(where: { $0.id == selectedId }),
              let selectedIndex = answerOptions.firstIndex(where: { $0.id == selectedId }) else { return }
        let selectedLabel = selectedOption.label ?? String(Character(UnicodeScalar(65 + selectedIndex)!))

        let isCorrect = correctAnswers.contains { answer in
            return answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
        }

        progressManager.markAnswered(questionId: question.questionId, correct: isCorrect)
        saveCurrentQuestionState(isCorrect: isCorrect)
        saveQuizState()
    }

    private func previousQuestion() {
        if currentIndex > 0 {
            saveCurrentQuestionState()
            currentIndex -= 1
            restoreQuestionState()
            if let question = currentQuestion {
                progressManager.markSeen(questionId: question.questionId)
            }
            saveQuizState()
        }
    }

    private func nextQuestion() {
        if currentIndex < questions.count - 1 {
            saveCurrentQuestionState()
            currentIndex += 1
            restoreQuestionState()
            if let question = currentQuestion {
                progressManager.markSeen(questionId: question.questionId)
            }
            saveQuizState()
        }
    }

    private func resetQuestionState() {
        selectedAnswerId = nil
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

        guard let selectedOption = answerOptions.first(where: { $0.id == selectedId }),
              let selectedIndex = answerOptions.firstIndex(where: { $0.id == selectedId }) else { return nil }
        let selectedLabel = selectedOption.label ?? String(Character(UnicodeScalar(65 + selectedIndex)!))

        return correctAnswers.contains { answer in
            return answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
        }
    }

    private func safeHeight(_ height: CGFloat?, default: CGFloat = 100) -> CGFloat {
        guard let height = height, height.isFinite && height > 0 && height < 10000 else {
            return `default`
        }
        return max(height, `default`)
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
