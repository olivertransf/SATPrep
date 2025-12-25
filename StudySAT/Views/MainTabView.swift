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
    @State private var showFilters = false // Don't show filters automatically
    @State private var selectedTab = 0
    @State private var hasAppliedFilters = false
    @State private var savedQuestionIds: [String] = [] // Store question IDs from saved state
    @State private var currentQuizId: String? = nil // Track which quiz we're currently viewing
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    @ObservedObject private var quizStateManager = QuizStateManager.shared
    
    var filteredQuestions: [Question] {
        // If we have saved question IDs, restore those exact questions
        if !savedQuestionIds.isEmpty {
            let questionDict = Dictionary(uniqueKeysWithValues: questionLoader.questions.map { ($0.questionId, $0) })
            let restored = savedQuestionIds.compactMap { questionDict[$0] }
            // Only use saved IDs if we successfully restored all questions
            if restored.count == savedQuestionIds.count {
                return restored
            }
            // If restoration failed, clear saved state and use fresh filter
            savedQuestionIds = []
            if let quizId = currentQuizId {
                quizStateManager.deleteQuizState(id: quizId)
            }
            currentQuizId = nil
        }
        // Otherwise, use filtered questions
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
                            // Just go back to filter page without clearing saved state
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
                    // Only mark filters as applied when "Start Quiz" is clicked
                    hasAppliedFilters = true
                    
                    if let quizId = quizId, let savedQuiz = quizStateManager.loadQuizState(id: quizId) {
                        // Resuming an existing quiz
                        currentQuizId = quizId
                        filters = savedQuiz.filters
                        savedQuestionIds = savedQuiz.questionIds
                    } else {
                        // Starting a new quiz - use current filters
                        let questions = questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
                        let state = QuizState(
                            filters: filters,
                            currentIndex: 0,
                            questionIds: questions.map { $0.questionId }
                        )
                        // Set quiz ID before saving
                        currentQuizId = state.id
                        // Update savedQuestionIds so filteredQuestions uses the new list
                        savedQuestionIds = state.questionIds
                        // Save the quiz state
                        quizStateManager.saveQuizState(state)
                    }
                }
            )
        }
        .onAppear {
            // Don't auto-restore - let user choose to resume from the filter page
            // Just check if we should show filters
            if !hasAppliedFilters {
                // Don't auto-show filters - let user see the resume option if available
            }
        }
    }
    
    private var filterFirstView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Select Filters to Start")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Choose your filters to begin your quiz")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Saved Quizzes Section
                if !quizStateManager.savedQuizzes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saved Quizzes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(quizStateManager.savedQuizzes) { savedQuiz in
                            SavedQuizRow(
                                quiz: savedQuiz,
                                onResume: {
                                    // Restore saved quiz
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
                    }
                } else {
                    // Show message when no saved quizzes
                    VStack(spacing: 8) {
                        Text("No saved quizzes yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Start a quiz and click 'Save Quiz' to save your progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                // Open Filters Button
            Button("Open Filters") {
                showFilters = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
                .padding(.horizontal)
        }
            .padding(.bottom)
        }
        .onAppear {
            // Refresh saved quizzes when view appears
            quizStateManager.loadAllQuizStates()
        }
    }
}

