//
//  MainTabView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var questionLoader = QuestionLoader.shared
    @StateObject private var progressManager = ProgressManager.shared
    @ObservedObject private var quizStateManager = QuizStateManager.shared

    @State private var activeQuizFilters = FilterOptions()
    @State private var activeQuizQuestionIds: [String] = []
    @State private var activeQuizId: String? = nil
    @State private var isInQuiz = false

    var quizQuestions: [Question] {
        guard !activeQuizQuestionIds.isEmpty else { return [] }
        let dict = Dictionary(uniqueKeysWithValues: questionLoader.questions.map { ($0.questionId, $0) })
        let restored = activeQuizQuestionIds.compactMap { dict[$0] }
        return restored.count == activeQuizQuestionIds.count ? restored : []
    }

    var body: some View {
        TabView {
            // Practice Tab
            NavigationStack {
                if isInQuiz {
                    QuizView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        questions: quizQuestions,
                        filters: $activeQuizFilters,
                        showFilters: .constant(false),
                        savedQuestionIds: $activeQuizQuestionIds,
                        currentQuizId: $activeQuizId,
                        onEndQuiz: {
                            isInQuiz = false
                        }
                    )
                } else {
                    PracticeHomeView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        quizStateManager: quizStateManager,
                        onStartQuiz: { filters in
                            launchQuiz(filters: filters)
                        },
                        onResumeQuiz: { savedQuiz in
                            resumeQuiz(savedQuiz)
                        }
                    )
                    .navigationTitle("Practice")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
            .tabItem {
                Label("Practice", systemImage: "books.vertical")
            }

            // Reference Tab
            ReferenceView()
            .tabItem {
                Label("Reference", systemImage: "book.closed")
            }

            // Vocab flashcards
            NavigationStack {
                VocabFlashcardsView()
            }
            .tabItem {
                Label("Vocab", systemImage: "rectangle.on.rectangle.angled")
            }

            // Desmos graphing calculator
            NavigationStack {
                DesmosCalculatorView()
                    .navigationTitle("Desmos")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Desmos", systemImage: "function")
            }

            // Settings Tab
            SettingsView(progressManager: progressManager, questionLoader: questionLoader)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Quiz Launch

    private func launchQuiz(filters: FilterOptions) {
        let questions = questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
        guard !questions.isEmpty else { return }

        let state = QuizState(
            filters: filters,
            currentIndex: 0,
            questionIds: questions.map { $0.questionId }
        )
        activeQuizFilters = filters
        activeQuizQuestionIds = state.questionIds
        activeQuizId = state.id
        quizStateManager.saveQuizState(state)
        isInQuiz = true
    }

    private func resumeQuiz(_ savedQuiz: QuizState) {
        activeQuizFilters = savedQuiz.filters
        activeQuizQuestionIds = savedQuiz.questionIds
        activeQuizId = savedQuiz.id
        isInQuiz = true
    }
}
