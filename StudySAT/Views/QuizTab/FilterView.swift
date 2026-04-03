//
//  FilterView.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct FilterView: View {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Question count preview card
                    questionCountCard

                    // Category filters
                    categorySection

                    // Difficulty chips
                    difficultySection

                    // Answer status
                    answerStatusSection

                    // Source filter
                    sourceSection

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
        VStack(spacing: 8) {
            Text("\(effectiveCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(matchingCount > 0 ? .blue : .secondary)
            Text(effectiveCount == 1 ? "question available" : "questions available")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if useQuestionLimit, let limit = questionLimit, limit > 0, matchingCount > limit {
                Text("out of \(matchingCount) matching")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Category")

            // Module picker as horizontal chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Module")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chipButton("All", isSelected: selectedModule == nil) {
                            selectedModule = nil
                            selectedPrimaryClass = nil
                            selectedSkillDesc = nil
                        }
                        ForEach(questionLoader.getAvailableModules(), id: \.self) { module in
                            chipButton(module.capitalized, isSelected: selectedModule == module) {
                                selectedModule = (selectedModule == module) ? nil : module
                                selectedPrimaryClass = nil
                                selectedSkillDesc = nil
                            }
                        }
                    }
                }
            }

            // Primary Class picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Class")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                let classes = questionLoader.getAvailablePrimaryClasses(for: selectedModule)
                if classes.isEmpty {
                    Text("Select a module first")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chipButton("All", isSelected: selectedPrimaryClass == nil) {
                                selectedPrimaryClass = nil
                                selectedSkillDesc = nil
                            }
                            ForEach(classes, id: \.self) { cls in
                                chipButton(cls, isSelected: selectedPrimaryClass == cls) {
                                    selectedPrimaryClass = (selectedPrimaryClass == cls) ? nil : cls
                                    selectedSkillDesc = nil
                                }
                            }
                        }
                    }
                }
            }

            // Skill Description picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Skill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                let skills = questionLoader.getAvailableSkillDescs(for: selectedModule, primaryClass: selectedPrimaryClass)
                if skills.isEmpty {
                    Text("No skills for current selection")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chipButton("All", isSelected: selectedSkillDesc == nil) {
                                selectedSkillDesc = nil
                            }
                            ForEach(skills, id: \.self) { skill in
                                chipButton(skill, isSelected: selectedSkillDesc == skill) {
                                    selectedSkillDesc = (selectedSkillDesc == skill) ? nil : skill
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Difficulty")

            HStack(spacing: 10) {
                difficultyChip(nil, label: "All", color: .blue)
                difficultyChip("E", label: "Easy", color: .green)
                difficultyChip("M", label: "Medium", color: .orange)
                difficultyChip("H", label: "Hard", color: .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func difficultyChip(_ value: String?, label: String, color: Color) -> some View {
        Button {
            selectedDifficulty = (selectedDifficulty == value) ? nil : value
            // Tapping "All" always clears
            if value == nil { selectedDifficulty = nil }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedDifficulty == value ? color.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                .foregroundColor(selectedDifficulty == value ? color : .primary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedDifficulty == value ? color : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Answer Status Section

    private var answerStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Answer Status")

            HStack(spacing: 8) {
                ForEach(FilterOptions.AnswerStatus.allCases, id: \.self) { status in
                    let shortLabel: String = {
                        switch status {
                        case .all: return "All"
                        case .unanswered: return "New"
                        case .incorrect: return "Wrong"
                        case .correct: return "Correct"
                        }
                    }()
                    Button {
                        selectedAnswerStatus = status
                    } label: {
                        Text(shortLabel)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedAnswerStatus == status ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                            .foregroundColor(selectedAnswerStatus == status ? .blue : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAnswerStatus == status ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Source")

            HStack(spacing: 8) {
                sourceChip(nil, label: "All")
                sourceChip(.bluebook, label: "Bluebook")
                sourceChip(.notBluebook, label: "Other")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func sourceChip(_ value: FilterOptions.BluebookFilter?, label: String) -> some View {
        Button {
            selectedBluebook = (selectedBluebook == value) ? nil : value
            if value == nil { selectedBluebook = nil }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedBluebook == value ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                .foregroundColor(selectedBluebook == value ? .blue : .primary)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedBluebook == value ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quiz Options Section

    private var quizOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Quiz Options")

            // Shuffle toggle
            HStack {
                Image(systemName: "shuffle")
                    .foregroundColor(.blue)
                Text("Shuffle Questions")
                Spacer()
                Toggle("", isOn: $shuffled)
                    .labelsHidden()
            }

            Divider()

            // Question limit
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.blue)
                Text("Limit Questions")
                Spacer()
                Toggle("", isOn: $useQuestionLimit)
                    .labelsHidden()
            }

            if useQuestionLimit {
                HStack(spacing: 12) {
                    ForEach([10, 20, 30, 50], id: \.self) { count in
                        Button {
                            questionLimit = count
                        } label: {
                            Text("\(count)")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(questionLimit == count ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                                .foregroundColor(questionLimit == count ? .blue : .primary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(questionLimit == count ? Color.blue : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }

            Divider()

            // Clear all filters
            Button {
                clearAllFilters()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Filters")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

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
        VStack(alignment: .leading, spacing: 12) {
            // Filter description
            Text(quiz.filterDescription())
                .font(.headline)
                .lineLimit(2)

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: progress)
                    .tint(progress >= 1.0 ? .green : .blue)

                HStack {
                    Text("\(answeredCount)/\(quiz.questionIds.count) answered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if answeredCount > 0 {
                        Text("\(correctCount) correct")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            // Time saved
            Text(quiz.lastSaved, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))

            // Buttons
            HStack(spacing: 12) {
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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
