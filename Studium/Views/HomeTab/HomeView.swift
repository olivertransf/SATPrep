//
//  HomeView.swift
//  Studium
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var quizStateManager: QuizStateManager

    var onStartSection: (String) -> Void
    var onGoToPractice: () -> Void
    var onGoToVocab: () -> Void
    var onGoToReference: () -> Void
    var onResumeQuiz: (QuizState) -> Void
    var onOpenSettings: () -> Void

    @State private var showStats = false
    @EnvironmentObject private var authManager: StudiumAuthManager
    @EnvironmentObject private var syncService: StudiumCloudSyncService

    private var isPhone: Bool { StudiumDesignSystem.isPhone }

    private struct SectionStats {
        let total: Int
        let answered: Int
        let accuracy: Int?
    }

    private struct HomeStats {
        let total: Int
        let answered: Int
        let accuracy: Int?
        let math: SectionStats
        let rw: SectionStats
    }

    private var stats: HomeStats {
        let questions = questionLoader.questions
        let progress = progressManager.progress

        func sectionStats(module: String) -> SectionStats {
            let qs = questions.filter { $0.module.lowercased() == module }
            let answered = qs.filter { progress[$0.questionId]?.correct != nil }.count
            let correct = qs.filter { progress[$0.questionId]?.correct == true }.count
            let accuracy = answered > 0 ? Int((Double(correct) / Double(answered) * 100).rounded()) : nil
            return SectionStats(total: qs.count, answered: answered, accuracy: accuracy)
        }

        let answered = questions.filter { progress[$0.questionId]?.correct != nil }.count
        let correct = questions.filter { progress[$0.questionId]?.correct == true }.count
        let accuracy = answered > 0 ? Int((Double(correct) / Double(answered) * 100).rounded()) : nil

        return HomeStats(
            total: questions.count,
            answered: answered,
            accuracy: accuracy,
            math: sectionStats(module: "math"),
            rw: sectionStats(module: "english")
        )
    }

    private var bankIsReady: Bool {
        !questionLoader.isLoading && questionLoader.error == nil && !questionLoader.questions.isEmpty
    }

    var body: some View {
        Group {
            if let error = questionLoader.error {
                StudiumEmptyState(
                    title: "Could not load questions",
                    message: error.localizedDescription,
                    systemImage: "exclamationmark.triangle",
                    primaryActionTitle: "Retry",
                    primaryAction: { questionLoader.reload() }
                )
            } else if questionLoader.isLoading && questionLoader.questions.isEmpty {
                StudiumEmptyState(
                    title: "Loading question bank",
                    message: nil,
                    systemImage: "arrow.down.circle"
                )
                .overlay { ProgressView() }
            } else {
                homeScrollContent
            }
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("Home")
        .navAdaptiveTitle()
        .toolbar {
            StudiumGlobalToolbar(
                authManager: authManager,
                syncService: syncService,
                onOpenSettings: onOpenSettings
            )
        }
        .navigationDestination(isPresented: $showStats) {
            StatsView(progressManager: progressManager, questionLoader: questionLoader)
        }
        .onAppear { quizStateManager.loadAllQuizStates() }
    }

    private var homeScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isPhone ? StudiumDesignSystem.spacingLG : StudiumDesignSystem.spacingXL) {
                if !isPhone {
                    header
                    progressCard
                }
                startPracticingSection
                if !quizStateManager.savedQuizzes.isEmpty {
                    continueSection
                }
                if !isPhone {
                    studyToolsSection
                }
            }
            .padding(.horizontal, isPhone ? StudiumDesignSystem.spacingMD : StudiumDesignSystem.spacingLG)
            .padding(.vertical, isPhone ? StudiumDesignSystem.spacingMD : StudiumDesignSystem.spacingLG)
            .readableContentFrame(maxWidth: 960)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            Text("Free SAT practice")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Text("Study smarter for the Digital SAT")
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)

            Text("Thousands of official-style questions, vocab flashcards, formula sheets, and a built-in Desmos calculator.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressCard: some View {
        Button { showStats = true } label: {
            if isPhone {
                phoneProgressCard
            } else {
                desktopProgressCard
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens statistics")
    }

    private var phoneProgressCard: some View {
        HStack(spacing: StudiumDesignSystem.spacingMD) {
            if let accuracy = stats.accuracy {
                Text("\(accuracy)%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .monospacedDigit()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accuracy")
                        .font(.subheadline.weight(.semibold))
                    Text("\(stats.answered) attempted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                StudiumIconBadge(systemImage: "chart.line.uptrend.xyaxis", tint: .accentColor, size: 40, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No stats yet")
                        .font(.subheadline.weight(.semibold))
                    Text("Answer questions to track progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .studiumElevatedCard(padding: StudiumDesignSystem.spacingMD)
    }

    private var desktopProgressCard: some View {
        HStack(spacing: StudiumDesignSystem.spacingMD) {
            StudiumIconBadge(systemImage: "chart.line.uptrend.xyaxis", tint: .accentColor, size: 48, cornerRadius: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let accuracy = stats.accuracy {
                    Text("\(accuracy)% accuracy")
                        .font(.title2.bold())
                        .foregroundStyle(Color.accentColor)
                        .monospacedDigit()
                    Text("\(stats.answered) of \(stats.total) questions attempted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No attempts yet")
                        .font(.title3.weight(.semibold))
                    Text("Start a practice set to track your accuracy")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text("View stats")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .studiumElevatedCard()
    }

    private var startPracticingSection: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
            Text("Start practicing")
                .font(isPhone ? .headline.weight(.semibold) : .title3.weight(.semibold))

            if isPhone {
                VStack(spacing: StudiumDesignSystem.spacingSM) {
                    phoneQuickStartRow(
                        title: "Math",
                        detail: phoneSectionDetail(stats.math),
                        systemImage: "function",
                        tint: .accentColor
                    ) { onStartSection("math") }

                    phoneQuickStartRow(
                        title: "Reading & Writing",
                        detail: phoneSectionDetail(stats.rw),
                        systemImage: "text.book.closed",
                        tint: .studiumSectionRW
                    ) { onStartSection("english") }

                    phoneQuickStartRow(
                        title: "All practice",
                        detail: "Filters, topics, and custom sets",
                        systemImage: "square.grid.2x2",
                        tint: .accentColor
                    ) { onGoToPractice() }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: StudiumDesignSystem.spacingMD) {
                    quickStartCard(
                        title: "Math",
                        subtitle: mathSubtitle,
                        systemImage: "function",
                        tint: .accentColor
                    ) { onStartSection("math") }

                    quickStartCard(
                        title: "Reading & Writing",
                        subtitle: rwSubtitle,
                        systemImage: "text.book.closed",
                        tint: .studiumSectionRW
                    ) { onStartSection("english") }
                }

                quickStartCard(
                    title: "All practice",
                    subtitle: "Filters, topics, and custom sets",
                    systemImage: "square.grid.2x2",
                    tint: .accentColor
                ) { onGoToPractice() }
            }
        }
        .disabled(!bankIsReady)
    }

    private func phoneSectionDetail(_ section: SectionStats) -> String {
        if questionLoader.isLoading && section.total == 0 { return "Loading…" }
        return "\(section.total.formatted()) questions"
    }

    private func phoneQuickStartRow(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: StudiumDesignSystem.spacingMD) {
                StudiumIconBadge(systemImage: systemImage, tint: tint, size: 40, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .studiumElevatedCard(padding: StudiumDesignSystem.spacingMD)
        }
        .buttonStyle(.plain)
    }

    private var mathSubtitle: String {
        if questionLoader.isLoading && stats.math.total == 0 { return "Loading…" }
        var parts = ["\(stats.math.total.formatted()) questions"]
        if let acc = stats.math.accuracy { parts.append("\(acc)% accuracy") }
        return parts.joined(separator: " · ")
    }

    private var rwSubtitle: String {
        if questionLoader.isLoading && stats.rw.total == 0 { return "Loading…" }
        var parts = ["\(stats.rw.total.formatted()) questions"]
        if let acc = stats.rw.accuracy { parts.append("\(acc)% accuracy") }
        return parts.joined(separator: " · ")
    }

    private func quickStartCard(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
                StudiumIconBadge(systemImage: systemImage, tint: tint)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .studiumElevatedCard()
        }
        .buttonStyle(.plain)
    }

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            HStack {
                Text(isPhone ? "Continue" : "Continue where you left off")
                    .font(isPhone ? .headline.weight(.semibold) : .title3.weight(.semibold))
                Spacer()
                if !isPhone {
                    Button(action: onGoToPractice) {
                        HStack(spacing: 4) {
                            Text("All practice")
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: StudiumDesignSystem.spacingSM) {
                ForEach(quizStateManager.savedQuizzes.prefix(5)) { quiz in
                    let answered = quiz.answerStates.values.filter(\.hasSubmitted).count
                    ContinueSavedQuizCard(
                        tags: quiz.filterTags(),
                        answered: answered,
                        total: quiz.questionIds.count,
                        onPlay: { onResumeQuiz(quiz) },
                        onDelete: { quizStateManager.deleteQuizState(id: quiz.id) }
                    )
                }
            }
        }
    }

    private var studyToolsSection: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingMD) {
            Text("Study tools")
                .font(.title3.weight(.semibold))

            VStack(spacing: StudiumDesignSystem.spacingSM) {
                studyToolRow(title: "Progress & stats", subtitle: "Accuracy and breakdowns", systemImage: "chart.bar.fill") {
                    showStats = true
                }
                studyToolRow(title: "Vocab flashcards", subtitle: "Words and roots", systemImage: "rectangle.on.rectangle.angled", action: onGoToVocab)
                studyToolRow(title: "Formula reference", subtitle: "Math cheat sheets", systemImage: "book.closed", action: onGoToReference)
            }
        }
    }

    private func studyToolRow(title: String, subtitle: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: StudiumDesignSystem.spacingMD) {
                StudiumIconBadge(systemImage: systemImage, tint: .accentColor, size: 40, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .studiumElevatedCard()
        }
        .buttonStyle(.plain)
    }
}
