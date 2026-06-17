//
//  StatsView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var questionLoader: QuestionLoader

    @State private var showResetConfirmation = false
    @State private var resetType: ResetType?
    @State private var showProgramPicker = false
    @State private var showModulePicker = false
    @State private var showPrimaryClassPicker = false
    @State private var showSkillDescPicker = false
    @State private var showDifficultyPicker = false

    enum ResetType {
        case all
        case program(String)
        case module(String)
        case primaryClass(String)
        case skillDesc(String)
        case difficulty(String)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FilterStripSectionTitle(text: "Performance")
                overallStatsCard
                categoryBreakdownSection
                resetProgressSection
            }
            .padding(StudiumDesignSystem.isPhone ? StudiumDesignSystem.spacingLG : StudiumDesignSystem.spacingXL)
            .readableContentFrame(maxWidth: LayoutMetrics.settingsReadableMaxWidth)
        }
        .background(Color.systemGroupedBackground)
        .navigationTitle("Statistics")
        .navAdaptiveTitle()
        .alert("Reset Progress", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { resetType = nil }
            Button("Reset", role: .destructive) { performReset() }
        } message: {
            if let resetType = resetType {
                Text(resetMessage(for: resetType))
            }
        }
        .sheet(isPresented: $showProgramPicker) {
            resetPickerSheet(title: "Select Program", items: questionLoader.getAvailablePrograms(), isPresented: $showProgramPicker) { program in
                resetType = .program(program)
                showResetConfirmation = true
            }
        }
        .sheet(isPresented: $showModulePicker) {
            resetPickerSheet(title: "Select Module", items: questionLoader.getAvailableModules(), isPresented: $showModulePicker) { module in
                resetType = .module(module)
                showResetConfirmation = true
            }
        }
        .sheet(isPresented: $showPrimaryClassPicker) {
            resetPickerSheet(title: "Select Primary Class", items: questionLoader.getAvailablePrimaryClasses(for: nil), isPresented: $showPrimaryClassPicker) { primaryClass in
                resetType = .primaryClass(primaryClass)
                showResetConfirmation = true
            }
        }
        .sheet(isPresented: $showSkillDescPicker) {
            resetPickerSheet(title: "Select Skill", items: questionLoader.getAvailableSkillDescs(for: nil, primaryClass: nil), isPresented: $showSkillDescPicker) { skillDesc in
                resetType = .skillDesc(skillDesc)
                showResetConfirmation = true
            }
        }
        .sheet(isPresented: $showDifficultyPicker) {
            resetPickerSheet(title: "Select Difficulty", items: questionLoader.getAvailableDifficulties().map { difficultyDescription($0) }, isPresented: $showDifficultyPicker) { difficultyDisplay in
                let difficulty = questionLoader.getAvailableDifficulties().first { difficultyDescription($0) == difficultyDisplay } ?? difficultyDisplay
                resetType = .difficulty(difficulty)
                showResetConfirmation = true
            }
        }
    }

    private func resetPickerSheet(
        title: String,
        items: [String],
        isPresented: Binding<Bool>,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        NavigationStack {
            List {
                ForEach(items, id: \.self) { item in
                    Button(action: {
                        onSelect(item)
                        isPresented.wrappedValue = false
                    }) {
                        Text(item)
                    }
                }
            }
            .navigationTitle(title)
            .navInlineTitle()
            .toolbar {
                ToolbarItem(placement: .navTrailing) {
                    Button("Cancel") {
                        isPresented.wrappedValue = false
                    }
                }
            }
        }
    }

    // MARK: - Overall Stats

    private var overallStatsCard: some View {
        let attempted = progressManager.getTotalAttempted()
        let seen = progressManager.getTotalSeen()
        let accuracy = progressManager.getOverallAccuracy()
        let total = questionLoader.questions.count

        return VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.systemGray5, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: attempted > 0 ? CGFloat(accuracy / 100) : 0)
                    .stroke(accuracyColor(accuracy), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: accuracy)

                VStack(spacing: 2) {
                    Text("\(Int(accuracy))%")
                        .font(StudiumDesignSystem.statDigitFont)
                        .foregroundStyle(attempted > 0 ? accuracyColor(accuracy) : .secondary)
                    Text("accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Stats row
            HStack(spacing: 0) {
                statItem(value: "\(seen)", label: "Seen", color: .accentColor)
                Divider().frame(height: 40)
                statItem(value: "\(attempted)", label: "Attempted", color: .orange)
                Divider().frame(height: 40)
                statItem(value: "\(total)", label: "Total", color: .secondary)
            }
        }
        .studiumElevatedCard()
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(StudiumDesignSystem.statFont)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FilterStripSectionTitle(text: "By Module")
            categoryCard(items: questionLoader.getAvailableModules().map { module in
                CategoryItem(
                    name: module.capitalized,
                    accuracy: progressManager.getAccuracy(byModule: module, questionLoader: questionLoader)
                )
            })

            FilterStripSectionTitle(text: "By Difficulty")
            categoryCard(items: questionLoader.getAvailableDifficulties().map { difficulty in
                CategoryItem(
                    name: difficultyDescription(difficulty),
                    accuracy: progressManager.getAccuracy(byDifficulty: difficulty, questionLoader: questionLoader)
                )
            })

            FilterStripSectionTitle(text: "By Primary Class")
            categoryCard(items: questionLoader.getAvailablePrimaryClasses(for: nil).prefix(10).map { primaryClass in
                CategoryItem(
                    name: primaryClass,
                    accuracy: progressManager.getAccuracy(byPrimaryClass: primaryClass, questionLoader: questionLoader)
                )
            })
        }
    }

    private func categoryCard(items: [CategoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if items.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(items, id: \.name) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            if item.accuracy > 0 {
                                Text("\(Int(item.accuracy))%")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(accuracyColor(item.accuracy))
                            } else {
                                Text("--")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.systemGray5)
                                    .cornerRadius(2)
                                if item.accuracy > 0 {
                                    Rectangle()
                                        .fill(accuracyColor(item.accuracy))
                                        .cornerRadius(2)
                                        .frame(width: geo.size.width * CGFloat(item.accuracy / 100))
                                }
                            }
                        }
                        .frame(height: 4)
                    }

                    if item.name != items.last?.name {
                        Divider()
                    }
                }
            }
        }
        .studiumElevatedCard()
    }

    // MARK: - Reset Progress

    private var resetProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FilterStripSectionTitle(text: "Reset Progress")

            VStack(spacing: 0) {
                resetButton(title: "Reset All Progress", color: .red) {
                    resetType = .all
                    showResetConfirmation = true
                }
                Divider().padding(.leading)
                resetButton(title: "Reset by Program", color: .orange) { showProgramPicker = true }
                Divider().padding(.leading)
                resetButton(title: "Reset by Module", color: .orange) { showModulePicker = true }
                Divider().padding(.leading)
                resetButton(title: "Reset by Primary Class", color: .orange) { showPrimaryClassPicker = true }
                Divider().padding(.leading)
                resetButton(title: "Reset by Skill", color: .orange) { showSkillDescPicker = true }
                Divider().padding(.leading)
                resetButton(title: "Reset by Difficulty", color: .orange) { showDifficultyPicker = true }
            }
            .studiumElevatedCard(padding: 0, showsShadow: true)
        }
    }

    private func resetButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func difficultyDescription(_ difficulty: String) -> String {
        switch difficulty {
        case "E": return "Easy"
        case "M": return "Medium"
        case "H": return "Hard"
        default: return difficulty
        }
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 80 { return .green }
        if accuracy >= 60 { return .orange }
        return .red
    }

    private func resetMessage(for type: ResetType) -> String {
        switch type {
        case .all:
            return "This will clear all question progress, saved quizzes, and vocab buckets. This cannot be undone."
        case .program(let program):
            return "Are you sure you want to reset progress for all \(program) questions?"
        case .module(let module):
            return "Are you sure you want to reset progress for all \(module) questions?"
        case .primaryClass(let primaryClass):
            return "Are you sure you want to reset progress for all \(primaryClass) questions?"
        case .skillDesc(let skillDesc):
            return "Are you sure you want to reset progress for all \"\(skillDesc)\" questions?"
        case .difficulty(let difficulty):
            return "Are you sure you want to reset progress for all \(difficultyDescription(difficulty)) questions?"
        }
    }

    private func performReset() {
        guard let resetType = resetType else { return }
        switch resetType {
        case .all:
            StudiumLocalDataReset.resetAll()
        case .program(let program):
            progressManager.resetProgress(byProgram: program, questionLoader: questionLoader)
        case .module(let module):
            progressManager.resetProgress(byModule: module, questionLoader: questionLoader)
        case .primaryClass(let primaryClass):
            progressManager.resetProgress(byPrimaryClass: primaryClass, questionLoader: questionLoader)
        case .skillDesc(let skillDesc):
            progressManager.resetProgress(bySkillDesc: skillDesc, questionLoader: questionLoader)
        case .difficulty(let difficulty):
            progressManager.resetProgress(byDifficulty: difficulty, questionLoader: questionLoader)
        }
        self.resetType = nil
    }
}

struct CategoryItem {
    let name: String
    let accuracy: Double
}
