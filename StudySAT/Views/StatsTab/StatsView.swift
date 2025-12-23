//
//  StatsView.swift
//  StudySAT
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
    
    // Helper function to safely calculate width
    private func safeWidth(_ width: CGFloat) -> CGFloat {
        guard width.isFinite && width > 0 else { return 1000 }
        return min(max(width - 40, 200), 1000) // Ensure at least 200, max 1000
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Overall Stats
                        overallStatsCard
                        
                        // Breakdown by Category
                        categoryBreakdownSection
                        
                        // Reset Progress Section
                        resetProgressSection
                    }
                    .padding()
                    .frame(maxWidth: safeWidth(geometry.size.width))
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Statistics")
            .alert("Reset Progress", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {
                    resetType = nil
                }
                Button("Reset", role: .destructive) {
                    performReset()
                }
            } message: {
                if let resetType = resetType {
                    Text(resetMessage(for: resetType))
                }
            }
            .sheet(isPresented: $showProgramPicker) {
                resetPickerSheet(
                    title: "Select Program",
                    items: questionLoader.getAvailablePrograms(),
                    isPresented: $showProgramPicker
                ) { program in
                    resetType = .program(program)
                    showResetConfirmation = true
                }
            }
            .sheet(isPresented: $showModulePicker) {
                resetPickerSheet(
                    title: "Select Module",
                    items: questionLoader.getAvailableModules(),
                    isPresented: $showModulePicker
                ) { module in
                    resetType = .module(module)
                    showResetConfirmation = true
                }
            }
            .sheet(isPresented: $showPrimaryClassPicker) {
                resetPickerSheet(
                    title: "Select Primary Class",
                    items: questionLoader.getAvailablePrimaryClasses(for: nil),
                    isPresented: $showPrimaryClassPicker
                ) { primaryClass in
                    resetType = .primaryClass(primaryClass)
                    showResetConfirmation = true
                }
            }
            .sheet(isPresented: $showSkillDescPicker) {
                resetPickerSheet(
                    title: "Select Skill Description",
                    items: questionLoader.getAvailableSkillDescs(for: nil, primaryClass: nil),
                    isPresented: $showSkillDescPicker
                ) { skillDesc in
                    resetType = .skillDesc(skillDesc)
                    showResetConfirmation = true
                }
            }
            .sheet(isPresented: $showDifficultyPicker) {
                resetPickerSheet(
                    title: "Select Difficulty",
                    items: questionLoader.getAvailableDifficulties().map { difficultyDescription($0) },
                    isPresented: $showDifficultyPicker
                ) { difficultyDisplay in
                    // Find the actual difficulty code
                    let difficulty = questionLoader.getAvailableDifficulties().first { difficultyDescription($0) == difficultyDisplay } ?? difficultyDisplay
                    resetType = .difficulty(difficulty)
                    showResetConfirmation = true
                }
            }
        }
    }
    
    private func resetPickerSheet(
        title: String,
        items: [String],
        isPresented: Binding<Bool>,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        NavigationView {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented.wrappedValue = false
                    }
                }
            }
        }
    }
    
    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            Text("Overall Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(Int(progressManager.getOverallAccuracy()))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Text("\(progressManager.getTotalSeen())")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)
                        .lineLimit(1)
                    Text("Seen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Text("\(progressManager.getTotalAttempted())")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.orange)
                        .lineLimit(1)
                    Text("Attempted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown by Category")
                .font(.title2)
                .fontWeight(.bold)
            
            // By Module
            categoryCard(
                title: "By Module",
                items: questionLoader.getAvailableModules().map { module in
                    CategoryItem(
                        name: module.capitalized,
                        accuracy: progressManager.getAccuracy(byModule: module, questionLoader: questionLoader)
                    )
                }
            )
            
            // By Difficulty
            categoryCard(
                title: "By Difficulty",
                items: questionLoader.getAvailableDifficulties().map { difficulty in
                    CategoryItem(
                        name: difficultyDescription(difficulty),
                        accuracy: progressManager.getAccuracy(byDifficulty: difficulty, questionLoader: questionLoader)
                    )
                }
            )
            
            // By Primary Class
            categoryCard(
                title: "By Primary Class",
                items: questionLoader.getAvailablePrimaryClasses(for: nil).prefix(10).map { primaryClass in
                    CategoryItem(
                        name: primaryClass,
                        accuracy: progressManager.getAccuracy(byPrimaryClass: primaryClass, questionLoader: questionLoader)
                    )
                }
            )
        }
    }
    
    private func categoryCard(title: String, items: [CategoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            if items.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(items, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        if item.accuracy > 0 {
                            Text("\(Int(item.accuracy))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(accuracyColor(item.accuracy))
                        } else {
                            Text("—")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    if item.name != items.last?.name {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var resetProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reset Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                resetButton(title: "Reset All Progress", color: .red) {
                    resetType = .all
                    showResetConfirmation = true
                }
                
                Divider()
                
                resetButton(title: "Reset by Program", color: .orange) {
                    showProgramPicker = true
                }
                
                resetButton(title: "Reset by Module", color: .orange) {
                    showModulePicker = true
                }
                
                resetButton(title: "Reset by Primary Class", color: .orange) {
                    showPrimaryClassPicker = true
                }
                
                resetButton(title: "Reset by Skill Description", color: .orange) {
                    showSkillDescPicker = true
                }
                
                resetButton(title: "Reset by Difficulty", color: .orange) {
                    showDifficultyPicker = true
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func resetButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private func difficultyDescription(_ difficulty: String) -> String {
        switch difficulty {
        case "E": return "Easy"
        case "M": return "Medium"
        case "H": return "Hard"
        default: return difficulty
        }
    }
    
    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 80 {
            return .green
        } else if accuracy >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func resetMessage(for type: ResetType) -> String {
        switch type {
        case .all:
            return "Are you sure you want to reset all progress? This cannot be undone."
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
            progressManager.resetAllProgress()
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

