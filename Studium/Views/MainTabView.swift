//
//  MainTabView.swift
//  Studium
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MainTabView: View {
    @StateObject private var questionLoader = QuestionLoader.shared
    @StateObject private var progressManager = ProgressManager.shared
    @ObservedObject private var quizStateManager = QuizStateManager.shared

    @State private var activeQuizFilters = FilterOptions()
    @State private var activeQuizQuestionIds: [String] = []
    @State private var activeQuizId: String? = nil
    @State private var isInQuiz = false
    @State private var showLaunchEmptyAlert = false

    private var quizQuestions: [Question] {
        guard !activeQuizQuestionIds.isEmpty else { return [] }
        let byId = questionLoader.questionsById
        return activeQuizQuestionIds.compactMap { byId[$0] }
    }

    private var quizResumeIssue: String? {
        guard isInQuiz, !activeQuizQuestionIds.isEmpty else { return nil }
        let missing = activeQuizQuestionIds.count - quizQuestions.count
        guard missing > 0 else { return nil }
        return "\(missing) question\(missing == 1 ? "" : "s") missing from the question bank. End this quiz or update the bank."
    }

    var body: some View {
        #if os(iOS)
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom != .phone {
            sidebarTabs
        } else {
            tabs
        }
        #elseif os(macOS)
        if #available(macOS 15.0, *) {
            sidebarTabs
        } else {
            tabs
        }
        #else
        tabs
        #endif
    }

    @available(iOS 18.0, macOS 15.0, *)
    private var sidebarTabs: some View {
        tabs.tabViewStyle(.sidebarAdaptable)
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                if isInQuiz {
                    QuizView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        questions: quizQuestions,
                        filters: $activeQuizFilters,
                        savedQuestionIds: $activeQuizQuestionIds,
                        currentQuizId: $activeQuizId,
                        resumeIssue: quizResumeIssue,
                        onEndQuiz: { endQuiz() }
                    )
                } else {
                    PracticeHomeView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        quizStateManager: quizStateManager,
                        onStartQuiz: { launchQuiz(filters: $0) },
                        onResumeQuiz: { resumeQuiz($0) }
                    )
                    .navigationTitle("Practice")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #else
                    .navLargeTitle()
                    #endif
                }
            }
            .tabItem { Label("Practice", systemImage: "books.vertical") }

            ReferenceView()
                .tabItem { Label("Reference", systemImage: "book.closed") }

            NavigationStack {
                VocabFlashcardsView()
            }
            .tabItem { Label("Vocab", systemImage: "rectangle.on.rectangle.angled") }

            NavigationStack {
                DesmosCalculatorView()
                    .navigationTitle("Desmos")
                    .navInlineTitle()
            }
            .tabItem { Label("Desmos", systemImage: "function") }

            NavigationStack {
                StatsView(progressManager: progressManager, questionLoader: questionLoader)
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView(progressManager: progressManager, questionLoader: questionLoader)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .alert("No questions match", isPresented: $showLaunchEmptyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Adjust filters and try again.")
        }
    }

    private func launchQuiz(filters: FilterOptions) {
        let questions = questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
        guard !questions.isEmpty else {
            showLaunchEmptyAlert = true
            return
        }
        let state = QuizState(
            filters: filters,
            currentIndex: 0,
            questionIds: questions.map(\.questionId)
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

    private func endQuiz() {
        isInQuiz = false
    }
}
