//
//  FilterView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject var progressManager: ProgressManager
    @Binding var filters: FilterOptions
    @Binding var isPresented: Bool
    var onApply: ((String?) -> Void)? = nil

    @State private var selectedProgram: String?
    @State private var selectedModule: String?
    @State private var selectedPrimaryClass: String?
    @State private var selectedSkillDesc: String?
    @State private var selectedDifficulty: String?
    @State private var selectedAnswerStatus: FilterOptions.AnswerStatus
    @State private var selectedBluebook: FilterOptions.BluebookFilter?
    @State private var shuffled: Bool
    @State private var questionLimit: Int?
    @State private var useQuestionLimit: Bool

    init(
        questionLoader: QuestionLoader,
        progressManager: ProgressManager,
        filters: Binding<FilterOptions>,
        isPresented: Binding<Bool>,
        onApply: ((String?) -> Void)? = nil
    ) {
        self.questionLoader = questionLoader
        self.progressManager = progressManager
        self._filters = filters
        self._isPresented = isPresented
        self.onApply = onApply

        _selectedProgram = State(initialValue: filters.wrappedValue.program)
        _selectedModule = State(initialValue: filters.wrappedValue.module)
        _selectedPrimaryClass = State(initialValue: filters.wrappedValue.primaryClassCdDesc)
        _selectedSkillDesc = State(initialValue: filters.wrappedValue.skillDesc)
        _selectedDifficulty = State(initialValue: filters.wrappedValue.difficulty)
        _selectedAnswerStatus = State(initialValue: filters.wrappedValue.answerStatus)
        _selectedBluebook = State(initialValue: filters.wrappedValue.isBluebook)
        _shuffled = State(initialValue: filters.wrappedValue.shuffled)
        _questionLimit = State(initialValue: filters.wrappedValue.questionLimit)
        _useQuestionLimit = State(initialValue: filters.wrappedValue.questionLimit != nil)
    }

    private var previewFilters: FilterOptions {
        FilterOptions(
            program: selectedProgram,
            module: selectedModule,
            primaryClassCdDesc: selectedPrimaryClass,
            skillDesc: selectedSkillDesc,
            difficulty: selectedDifficulty,
            answerStatus: selectedAnswerStatus,
            isBluebook: selectedBluebook,
            shuffled: false,
            questionLimit: nil
        )
    }

    private var matchingCount: Int {
        questionLoader.getFilteredQuestionCount(filters: previewFilters, progressManager: progressManager)
    }

    private var effectiveCount: Int {
        if useQuestionLimit, let limit = questionLimit, limit > 0 {
            return min(limit, matchingCount)
        }
        return matchingCount
    }

    private var useWideFilterColumns: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Question count preview card
                    questionCountCard

                    // Category filters
                    categorySection

                    if useWideFilterColumns {
                        HStack(alignment: .top, spacing: 10) {
                            difficultySection
                                .frame(maxWidth: .infinity)

                            VStack(spacing: 10) {
                                answerStatusSection
                                sourceSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        difficultySection
                        answerStatusSection
                        sourceSection
                    }

                    // Quiz options
                    quizOptionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filter Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        applyFilters()
                    } label: {
                        Text("Start Quiz")
                            .fontWeight(.semibold)
                    }
                    .disabled(matchingCount == 0)
                }
            }
        }
    }

    // MARK: - Question Count Card

    private var questionCountCard: some View {
        FilterFormCard(spacing: 4) {
            VStack(spacing: 4) {
                Text("\(effectiveCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(matchingCount > 0 ? Color.accentColor : .secondary)
                Text(effectiveCount == 1 ? "question available" : "questions available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if useQuestionLimit, let limit = questionLimit, limit > 0, matchingCount > limit {
                    Text("out of \(matchingCount) matching")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        FilterFormCard {
            FilterGroupHeading(title: "Category", systemImage: "square.grid.2x2", tint: .blue)

            VStack(alignment: .leading, spacing: 5) {
                FilterSubgroupLabel(text: "Module")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        FilterChipButton(title: "All", isSelected: selectedModule == nil, accent: .blue, fillsGridCell: false) {
                            selectedModule = nil
                            selectedPrimaryClass = nil
                            selectedSkillDesc = nil
                        }
                        ForEach(questionLoader.getAvailableModules(), id: \.self) { module in
                            FilterChipButton(
                                title: module.capitalized,
                                isSelected: selectedModule == module,
                                accent: .blue,
                                fillsGridCell: false
                            ) {
                                selectedModule = (selectedModule == module) ? nil : module
                                selectedPrimaryClass = nil
                                selectedSkillDesc = nil
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                FilterSubgroupLabel(text: "Primary Class")
                let classes = questionLoader.getAvailablePrimaryClasses(for: selectedModule)
                if classes.isEmpty {
                    Text("Select a module first")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChipButton(title: "All", isSelected: selectedPrimaryClass == nil, accent: .blue, fillsGridCell: false) {
                                selectedPrimaryClass = nil
                                selectedSkillDesc = nil
                            }
                            ForEach(classes, id: \.self) { cls in
                                FilterChipButton(
                                    title: cls,
                                    isSelected: selectedPrimaryClass == cls,
                                    accent: .blue,
                                    fillsGridCell: false,
                                    maxTextWidth: 200
                                ) {
                                    selectedPrimaryClass = (selectedPrimaryClass == cls) ? nil : cls
                                    selectedSkillDesc = nil
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                FilterSubgroupLabel(text: "Skill")
                let skills = questionLoader.getAvailableSkillDescs(for: selectedModule, primaryClass: selectedPrimaryClass)
                if skills.isEmpty {
                    Text("No skills for current selection")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChipButton(title: "All", isSelected: selectedSkillDesc == nil, accent: .blue, fillsGridCell: false) {
                                selectedSkillDesc = nil
                            }
                            ForEach(skills, id: \.self) { skill in
                                FilterChipButton(
                                    title: skill,
                                    isSelected: selectedSkillDesc == skill,
                                    accent: .blue,
                                    fillsGridCell: false,
                                    maxTextWidth: 220
                                ) {
                                    selectedSkillDesc = (selectedSkillDesc == skill) ? nil : skill
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        FilterFormCard {
            FilterGroupHeading(title: "Difficulty", systemImage: "chart.bar", tint: .orange)

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedDifficulty == nil, accent: .blue, fillsGridCell: true) {
                    selectedDifficulty = nil
                }
                FilterChipButton(title: "Easy", isSelected: selectedDifficulty == "E", accent: .green, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "E") ? nil : "E"
                }
                FilterChipButton(title: "Medium", isSelected: selectedDifficulty == "M", accent: .orange, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "M") ? nil : "M"
                }
                FilterChipButton(title: "Hard", isSelected: selectedDifficulty == "H", accent: .red, fillsGridCell: true) {
                    selectedDifficulty = (selectedDifficulty == "H") ? nil : "H"
                }
            }
        }
    }

    // MARK: - Answer Status Section

    private var answerStatusSection: some View {
        FilterFormCard {
            FilterGroupHeading(title: "Answer Status", systemImage: "checkmark.circle", tint: .green)

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 6) {
                ForEach(FilterOptions.AnswerStatus.allCases, id: \.self) { status in
                    let shortLabel: String = {
                        switch status {
                        case .all: return "All"
                        case .unanswered: return "New"
                        case .incorrect: return "Wrong"
                        case .correct: return "Correct"
                        }
                    }()
                    FilterChipButton(title: shortLabel, isSelected: selectedAnswerStatus == status, accent: .blue, fillsGridCell: true) {
                        selectedAnswerStatus = status
                    }
                }
            }
        }
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        FilterFormCard {
            FilterGroupHeading(title: "Source", systemImage: "books.vertical", tint: .purple)

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 6) {
                FilterChipButton(title: "All", isSelected: selectedBluebook == nil, accent: .purple, fillsGridCell: true) {
                    selectedBluebook = nil
                }
                FilterChipButton(title: "Bluebook", isSelected: selectedBluebook == .bluebook, accent: .purple, fillsGridCell: true) {
                    selectedBluebook = (selectedBluebook == .bluebook) ? nil : .bluebook
                }
                FilterChipButton(title: "Other", isSelected: selectedBluebook == .notBluebook, accent: .purple, fillsGridCell: true) {
                    selectedBluebook = (selectedBluebook == .notBluebook) ? nil : .notBluebook
                }
            }
        }
    }

    // MARK: - Quiz Options Section

    private var quizOptionsSection: some View {
        FilterFormCard {
            FilterGroupHeading(title: "Quiz Options", systemImage: "slider.horizontal.3", tint: .indigo)

            FilterSubgroupLabel(text: "Question order")

            HStack(spacing: 8) {
                FilterOrderChoiceButton(
                    title: "In order",
                    subtitle: "Stable sequence",
                    systemImage: "list.number",
                    isSelected: !shuffled,
                    tint: .indigo
                ) {
                    shuffled = false
                }
                FilterOrderChoiceButton(
                    title: "Random",
                    subtitle: "Shuffled",
                    systemImage: "shuffle",
                    isSelected: shuffled,
                    tint: .indigo
                ) {
                    shuffled = true
                }
            }

            Divider()

            HStack {
                Image(systemName: "number")
                    .foregroundStyle(Color.accentColor)
                Text("Limit Questions")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $useQuestionLimit)
                    .labelsHidden()
            }

            if useQuestionLimit {
                HStack(spacing: 8) {
                    ForEach([10, 20, 30, 50], id: \.self) { count in
                        FilterChipButton(
                            title: "\(count)",
                            isSelected: questionLimit == count,
                            accent: .blue,
                            fillsGridCell: true
                        ) {
                            questionLimit = count
                        }
                    }
                }
                .padding(.top, 2)
            }

            Divider()

            Button {
                clearAllFilters()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Filters")
                }
                .font(.subheadline)
                .foregroundStyle(Color(.systemRed))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Helpers

    private func clearAllFilters() {
        selectedProgram = nil
        selectedModule = nil
        selectedPrimaryClass = nil
        selectedSkillDesc = nil
        selectedDifficulty = nil
        selectedAnswerStatus = .all
        selectedBluebook = nil
        shuffled = true
        questionLimit = nil
        useQuestionLimit = false
    }

    private func applyFilters() {
        filters = FilterOptions(
            program: selectedProgram,
            module: selectedModule,
            primaryClassCdDesc: selectedPrimaryClass,
            skillDesc: selectedSkillDesc,
            difficulty: selectedDifficulty,
            answerStatus: selectedAnswerStatus,
            isBluebook: selectedBluebook,
            shuffled: shuffled,
            questionLimit: useQuestionLimit ? questionLimit : nil
        )
        isPresented = false
        onApply?(nil)
    }
}

// MARK: - Saved Quiz Row
struct SavedQuizRow: View {
    let quiz: QuizState
    let onResume: () -> Void
    let onDelete: () -> Void

    private var answeredCount: Int {
        quiz.answerStates.values.filter { $0.hasSubmitted }.count
    }

    private var correctCount: Int {
        quiz.answerStates.values.filter { $0.isCorrect == true }.count
    }

    private var progress: Double {
        guard quiz.questionIds.count > 0 else { return 0 }
        return Double(answeredCount) / Double(quiz.questionIds.count)
    }

    var body: some View {
        FilterFormCard(spacing: 10) {
            Text(quiz.filterDescription())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: progress)
                    .tint(progress >= 1.0 ? .green : Color.accentColor)

                HStack {
                    Text("\(answeredCount)/\(quiz.questionIds.count) answered")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if answeredCount > 0 {
                        Text("\(correctCount) correct")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Text(quiz.lastSaved, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 10) {
                Button(action: onResume) {
                    Label("Resume", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }
}
