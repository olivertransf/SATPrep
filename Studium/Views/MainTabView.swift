//
//  MainTabView.swift
//  Studium
//

import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

private enum AppTab: Hashable {
    case home, practice, vocab, reference, desmos
}

struct MainTabView: View {
    @EnvironmentObject private var authManager: StudiumAuthManager
    @EnvironmentObject private var syncService: StudiumCloudSyncService
    @StateObject private var questionLoader = QuestionLoader.shared
    @StateObject private var progressManager = ProgressManager.shared
    @ObservedObject private var quizStateManager = QuizStateManager.shared

    @State private var selectedTab: AppTab = .home
    @State private var practiceModulePreset: String?
    @State private var showSettings = false

    @State private var activeQuizFilters = FilterOptions()
    @State private var activeQuizQuestionIds: [String] = []
    @State private var activeQuizId: String? = nil
    @State private var isInQuiz = false
    @State private var showLaunchEmptyAlert = false
    @State private var showQuizTabGuardAlert = false

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
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    questionLoader: questionLoader,
                    progressManager: progressManager,
                    quizStateManager: quizStateManager,
                    onStartSection: { module in
                        practiceModulePreset = module
                        selectedTab = .practice
                    },
                    onGoToPractice: { selectedTab = .practice },
                    onGoToVocab: { selectedTab = .vocab },
                    onGoToReference: { selectedTab = .reference },
                    onResumeQuiz: { resumeQuiz($0) },
                    onOpenSettings: { showSettings = true }
                )
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(AppTab.home)

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
                    #if os(iOS)
                    .toolbar(.hidden, for: .tabBar)
                    #endif
                } else {
                    PracticeHomeView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        quizStateManager: quizStateManager,
                        initialModule: practiceModulePreset,
                        onConsumeModulePreset: { practiceModulePreset = nil },
                        onStartQuiz: { launchQuiz(filters: $0) },
                        onResumeQuiz: { resumeQuiz($0) }
                    )
                    .navigationTitle("Practice")
                    .navAdaptiveTitle()
                    .toolbar {
                        StudiumGlobalToolbar(
                            authManager: authManager,
                            syncService: syncService,
                            onOpenSettings: { showSettings = true }
                        )
                    }
                }
            }
            .tabItem { Label("Practice", systemImage: "books.vertical") }
            .tag(AppTab.practice)

            NavigationStack {
                VocabFlashcardsView()
                    .toolbar {
                        StudiumGlobalToolbar(
                            authManager: authManager,
                            syncService: syncService,
                            onOpenSettings: { showSettings = true }
                        )
                    }
            }
            .tabItem { Label("Vocab", systemImage: "rectangle.on.rectangle.angled") }
            .tag(AppTab.vocab)

            ReferenceView(onOpenSettings: { showSettings = true })
                .tabItem { Label("Reference", systemImage: "book.closed") }
                .tag(AppTab.reference)

            NavigationStack {
                DesmosCalculatorView()
                    .navigationTitle("Desmos")
                    .navInlineTitle()
                    .toolbar {
                        StudiumGlobalToolbar(
                            authManager: authManager,
                            syncService: syncService,
                            onOpenSettings: { showSettings = true }
                        )
                    }
            }
            .tabItem { Label("Desmos", systemImage: "function") }
            .tag(AppTab.desmos)
        }
        .onChange(of: selectedTab) { _, newTab in
            guard isInQuiz, newTab != .practice else { return }
            selectedTab = .practice
            showQuizTabGuardAlert = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .studiumSyncApplied)) { _ in
            quizStateManager.loadAllQuizStates()
            progressManager.objectWillChange.send()
        }
        .onReceive(NotificationCenter.default.publisher(for: .studiumLocalDataDidReset)) { _ in
            endQuiz()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(progressManager: progressManager, questionLoader: questionLoader)
                .environmentObject(authManager)
                .environmentObject(syncService)
            #if os(iOS)
            .presentationDetents([.large])
            #endif
        }
        .alert("Quiz in progress", isPresented: $showQuizTabGuardAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use Save & Exit on the Practice tab to leave your quiz.")
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
        selectedTab = .practice
        activeQuizFilters = savedQuiz.filters
        activeQuizQuestionIds = savedQuiz.questionIds
        activeQuizId = savedQuiz.id
        isInQuiz = true
    }

    private func endQuiz() {
        isInQuiz = false
    }
}
