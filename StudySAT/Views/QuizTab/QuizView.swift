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
    
    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
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
                    showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveAndExit()
                } label: {
                    Text("Save Quiz")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // Restore saved quiz position if question IDs match
            if let quizId = currentQuizId,
               let savedState = quizStateManager.loadQuizState(id: quizId),
               savedState.questionIds == questions.map({ $0.questionId }),
               savedState.hasActiveQuiz {
                currentIndex = min(savedState.currentIndex, questions.count - 1)
                
                // Restore answer state for current question
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
            
            // Save initial state
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
    
    private func questionView(question: Question) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question counter
                    HStack {
                        Text("Question \(currentIndex + 1) of \(questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: min(geometry.size.width - 40, 800)) // Limit width on iPad
                    .frame(maxWidth: .infinity)
                
                    // Stimulus/Passage - show full content without scrolling
                    if let stimulus = question.content.displayStimulus {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passage")
                                .font(.headline)
                                .padding(.horizontal)
                            HTMLContentView(htmlContent: stimulus, isScrollable: false, allowInteraction: false, contentHeight: $passageHeight)
                                .frame(height: safeHeight(passageHeight, default: 100))
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: min(geometry.size.width - 40, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Question stem - dynamically sized
                    if let stem = question.content.displayStem {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Question")
                                .font(.headline)
                                .padding(.horizontal)
                            HTMLContentView(htmlContent: stem, isScrollable: false, allowInteraction: false, contentHeight: $questionStemHeight)
                                .frame(height: safeHeight(questionStemHeight, default: 100))
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: min(geometry.size.width - 40, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Answer options
                    let answerOptions = question.content.displayAnswerOptions
                    if !answerOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Answer Choices")
                                .font(.headline)
                                .padding(.horizontal)
                            
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
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: min(geometry.size.width - 40, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Submit button
                    if !hasSubmitted {
                        Button(action: submitAnswer) {
                            Text("Submit")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAnswerId != nil ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedAnswerId == nil)
                        .padding(.horizontal)
                        .frame(maxWidth: min(geometry.size.width - 40, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Explanation - show full content dynamically
                    if showExplanation, let rationale = question.content.rationale {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explanation")
                                .font(.headline)
                                .padding(.horizontal)
                            HTMLContentView(htmlContent: rationale, isScrollable: false, allowInteraction: false, contentHeight: $explanationHeight)
                                .frame(height: safeHeight(explanationHeight, default: 100))
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: min(geometry.size.width - 40, 800))
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 12) {
                        Button(action: previousQuestion) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: nextQuestion) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentIndex < questions.count - 1 ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(currentIndex >= questions.count - 1)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(maxWidth: min(geometry.size.width - 40, 800))
                    .frame(maxWidth: .infinity)
                }
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
        let answerHeight = Binding<CGFloat?>(
            get: { answerHeights[option.id] },
            set: { answerHeights[option.id] = $0 }
        )
        
        return Button(action: {
            if !hasSubmitted {
                selectedAnswerId = option.id
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Label (A, B, C, D)
                Text(label)
                    .font(.headline)
                    .frame(width: 30, height: 30, alignment: .center)
                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(15)
                
                // Content - entire area is tappable via parent button, shows full content
                HTMLContentView(htmlContent: option.content, isScrollable: false, allowInteraction: false, contentHeight: answerHeight)
                    .frame(height: safeHeight(answerHeight.wrappedValue, default: 50))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false) // Let taps pass through to parent button
                
                // Result indicator
                if showResult {
                    VStack {
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
                    .frame(width: 30)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle()) // Make entire rectangle tappable
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(hasSubmitted)
    }
    
    private func submitAnswer() {
        guard let question = currentQuestion,
              let selectedId = selectedAnswerId else { return }
        
        hasSubmitted = true
        showExplanation = true
        
        let correctAnswers = question.content.displayCorrectAnswer
        let answerOptions = question.content.displayAnswerOptions
        
        // Find the selected option and its label
        guard let selectedOption = answerOptions.first(where: { $0.id == selectedId }),
              let selectedIndex = answerOptions.firstIndex(where: { $0.id == selectedId }) else { return }
        let selectedLabel = selectedOption.label ?? String(Character(UnicodeScalar(65 + selectedIndex)!))
        
        // Check if the selected answer is correct
        let isCorrect = correctAnswers.contains { answer in
            // Match by label (A, B, C, D) or by ID
            return answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
        }
        
        progressManager.markAnswered(questionId: question.questionId, correct: isCorrect)
        
        // Save answer state immediately with the correct value
        saveCurrentQuestionState(isCorrect: isCorrect)
        saveQuizState()
    }
    
    private func previousQuestion() {
        if currentIndex > 0 {
            // Save current question state before moving
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
            // Save current question state before moving
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
        // Reset heights for new question
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
        // Reset heights for new question
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
        
        let isCorrect = correctAnswers.contains { answer in
            return answer.uppercased() == selectedLabel.uppercased() || answer.uppercased() == selectedId.uppercased()
        }
        
        return isCorrect
    }
    
    // Helper function to validate and return safe height value
    private func safeHeight(_ height: CGFloat?, default: CGFloat = 100) -> CGFloat {
        guard let height = height, height.isFinite && height > 0 && height < 10000 else {
            return `default`
        }
        return max(height, `default`)
    }
    
    private func saveAndExit() {
        // Save current state before exiting
        saveQuizState()
        // Call onEndQuiz callback if provided, otherwise just show filters
        if let onEndQuiz = onEndQuiz {
            onEndQuiz()
        } else {
            showFilters = true
        }
    }
    
    private func saveQuizState() {
        // Use existing quiz ID or create new one
        let quizId = currentQuizId ?? UUID().uuidString
        
        // Get existing answer states or create new dictionary
        var existingAnswerStates: [String: QuestionAnswerState] = [:]
        if let existingState = quizStateManager.loadQuizState(id: quizId) {
            existingAnswerStates = existingState.answerStates
        }
        
        // Save current question state (will be merged with existing)
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

