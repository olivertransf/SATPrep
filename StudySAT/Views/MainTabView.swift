//
//  MainTabView.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var questionLoader = QuestionLoader.shared
    @StateObject private var progressManager = ProgressManager.shared
    @State private var filters = FilterOptions()
    @State private var showFilters = false
    @State private var selectedTab = 0
    @State private var hasAppliedFilters = false
    @State private var savedQuestionIds: [String] = []
    @State private var currentQuizId: String? = nil
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    @ObservedObject private var quizStateManager = QuizStateManager.shared

    var filteredQuestions: [Question] {
        if !savedQuestionIds.isEmpty {
            let questionDict = Dictionary(uniqueKeysWithValues: questionLoader.questions.map { ($0.questionId, $0) })
            let restored = savedQuestionIds.compactMap { questionDict[$0] }
            if restored.count == savedQuestionIds.count {
                return restored
            }
            savedQuestionIds = []
            if let quizId = currentQuizId {
                quizStateManager.deleteQuizState(id: quizId)
            }
            currentQuizId = nil
        }
        return questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Quiz Tab
            NavigationStack {
                if !hasAppliedFilters {
                    filterFirstView
                } else {
                    QuizView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        questions: filteredQuestions,
                        filters: $filters,
                        showFilters: $showFilters,
                        savedQuestionIds: $savedQuestionIds,
                        currentQuizId: $currentQuizId,
                        onEndQuiz: {
                            hasAppliedFilters = false
                        }
                    )
                }
            }
            .tabItem {
                Label("Quiz", systemImage: "questionmark.circle")
            }
            .tag(0)

            // Stats Tab
            StatsView(
                progressManager: progressManager,
                questionLoader: questionLoader
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(1)

            // Settings Tab
            SettingsView(progressManager: progressManager)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .sheet(isPresented: $showFilters) {
            FilterView(
                questionLoader: questionLoader,
                progressManager: progressManager,
                filters: $filters,
                isPresented: $showFilters,
                onApply: { quizId in
                    hasAppliedFilters = true

                    if let quizId = quizId, let savedQuiz = quizStateManager.loadQuizState(id: quizId) {
                        currentQuizId = quizId
                        filters = savedQuiz.filters
                        savedQuestionIds = savedQuiz.questionIds
                    } else {
                        let questions = questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
                        let state = QuizState(
                            filters: filters,
                            currentIndex: 0,
                            questionIds: questions.map { $0.questionId }
                        )
                        currentQuizId = state.id
                        savedQuestionIds = state.questionIds
                        quizStateManager.saveQuizState(state)
                    }
                }
            )
        }
    }

    // MARK: - Home Screen

    private var filterFirstView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome header
                welcomeHeader

                // Quick Start presets
                quickStartSection

                // Saved Quizzes
                savedQuizzesSection
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("StudySAT")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .onAppear {
            quizStateManager.loadAllQuizStates()
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            let total = questionLoader.questions.count
            let attempted = progressManager.getTotalAttempted()
            let accuracy = progressManager.getOverallAccuracy()

            if attempted > 0 {
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("\(attempted)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("practiced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 2) {
                        Text("\(Int(accuracy))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(accuracy >= 80 ? .green : accuracy >= 60 ? .orange : .red)
                        Text("accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 2) {
                        Text("\(total - attempted)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 4) {
                    Text("\(total)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("questions ready to practice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Quick Start Section

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickStartCard(
                        title: "Random 20",
                        subtitle: "Mixed topics",
                        icon: "shuffle",
                        color: .blue
                    ) {
                        startQuickQuiz(FilterOptions(shuffled: true, questionLimit: 20))
                    }

                    quickStartCard(
                        title: "Math",
                        subtitle: "All difficulty",
                        icon: "function",
                        color: .purple
                    ) {
                        startQuickQuiz(FilterOptions(module: "math", shuffled: true, questionLimit: 20))
                    }

                    quickStartCard(
                        title: "Reading & Writing",
                        subtitle: "All difficulty",
                        icon: "text.book.closed",
                        color: .orange
                    ) {
                        startQuickQuiz(FilterOptions(module: "reading and writing", shuffled: true, questionLimit: 20))
                    }

                    quickStartCard(
                        title: "Hard Only",
                        subtitle: "Challenge mode",
                        icon: "flame",
                        color: .red
                    ) {
                        startQuickQuiz(FilterOptions(difficulty: "H", shuffled: true, questionLimit: 20))
                    }

                    quickStartCard(
                        title: "Review Mistakes",
                        subtitle: "Previously wrong",
                        icon: "arrow.counterclockwise",
                        color: .green
                    ) {
                        startQuickQuiz(FilterOptions(answerStatus: .incorrect, shuffled: true, questionLimit: 20))
                    }

                    quickStartCard(
                        title: "Custom",
                        subtitle: "Pick filters",
                        icon: "slider.horizontal.3",
                        color: .gray
                    ) {
                        showFilters = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func quickStartCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .cornerRadius(8)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 130, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func startQuickQuiz(_ quickFilters: FilterOptions) {
        filters = quickFilters
        let questions = questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
        guard !questions.isEmpty else {
            // Fall back to filter view if no questions match
            showFilters = true
            return
        }
        let state = QuizState(
            filters: filters,
            currentIndex: 0,
            questionIds: questions.map { $0.questionId }
        )
        currentQuizId = state.id
        savedQuestionIds = state.questionIds
        quizStateManager.saveQuizState(state)
        hasAppliedFilters = true
    }

    // MARK: - Saved Quizzes Section

    private var savedQuizzesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !quizStateManager.savedQuizzes.isEmpty {
                HStack {
                    Text("Saved Quizzes")
                        .font(.headline)
                    Spacer()
                    Text("\(quizStateManager.savedQuizzes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                ForEach(quizStateManager.savedQuizzes) { savedQuiz in
                    SavedQuizRow(
                        quiz: savedQuiz,
                        onResume: {
                            filters = savedQuiz.filters
                            savedQuestionIds = savedQuiz.questionIds
                            currentQuizId = savedQuiz.id
                            hasAppliedFilters = true
                        },
                        onDelete: {
                            quizStateManager.deleteQuizState(id: savedQuiz.id)
                        }
                    )
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No saved quizzes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start a quiz to save your progress")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
}
