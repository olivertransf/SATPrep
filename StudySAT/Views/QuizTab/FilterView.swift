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
    var onApply: (() -> Void)? = nil
    
    @State private var selectedProgram: String?
    @State private var selectedModule: String?
    @State private var selectedPrimaryClass: String?
    @State private var selectedSkillDesc: String?
    @State private var selectedDifficulty: String?
    @State private var selectedSeenStatus: FilterOptions.SeenStatus
    @State private var selectedBluebook: FilterOptions.BluebookFilter?
    
    init(
        questionLoader: QuestionLoader,
        progressManager: ProgressManager,
        filters: Binding<FilterOptions>,
        isPresented: Binding<Bool>,
        onApply: (() -> Void)? = nil
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
        _selectedSeenStatus = State(initialValue: filters.wrappedValue.seenStatus)
        _selectedBluebook = State(initialValue: filters.wrappedValue.isBluebook)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Program")) {
                    Picker("Program", selection: $selectedProgram) {
                        Text("All").tag(nil as String?)
                        ForEach(questionLoader.getAvailablePrograms(), id: \.self) { program in
                            Text(program).tag(program as String?)
                        }
                    }
                }
                
                Section(header: Text("Module")) {
                    Picker("Module", selection: $selectedModule) {
                        Text("All").tag(nil as String?)
                        ForEach(questionLoader.getAvailableModules(), id: \.self) { module in
                            Text(module.capitalized).tag(module as String?)
                        }
                    }
                    .onChange(of: selectedModule) {
                        // Reset dependent filters
                        selectedPrimaryClass = nil
                        selectedSkillDesc = nil
                    }
                }
                
                Section(header: Text("Primary Class")) {
                    Picker("Primary Class", selection: $selectedPrimaryClass) {
                        Text("All").tag(nil as String?)
                        ForEach(questionLoader.getAvailablePrimaryClasses(for: selectedModule), id: \.self) { primaryClass in
                            Text(primaryClass).tag(primaryClass as String?)
                        }
                    }
                    .onChange(of: selectedPrimaryClass) {
                        // Reset dependent filter
                        selectedSkillDesc = nil
                    }
                }
                
                Section(header: Text("Skill Description")) {
                    Picker("Skill Description", selection: $selectedSkillDesc) {
                        Text("All").tag(nil as String?)
                        ForEach(questionLoader.getAvailableSkillDescs(for: selectedModule, primaryClass: selectedPrimaryClass), id: \.self) { skillDesc in
                            Text(skillDesc).tag(skillDesc as String?)
                        }
                    }
                }
                
                Section(header: Text("Difficulty")) {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        Text("All").tag(nil as String?)
                        ForEach(questionLoader.getAvailableDifficulties(), id: \.self) { difficulty in
                            Text(difficultyDescription(difficulty)).tag(difficulty as String?)
                        }
                    }
                }
                
                Section(header: Text("Seen Status")) {
                    Picker("Seen Status", selection: $selectedSeenStatus) {
                        ForEach(FilterOptions.SeenStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                Section(header: Text("Source")) {
                    Picker("Bluebook", selection: $selectedBluebook) {
                        Text("All").tag(nil as FilterOptions.BluebookFilter?)
                        ForEach(FilterOptions.BluebookFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter as FilterOptions.BluebookFilter?)
                        }
                    }
                }
            }
            .navigationTitle("Filter Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Quiz") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func applyFilters() {
        filters = FilterOptions(
            program: selectedProgram,
            module: selectedModule,
            primaryClassCdDesc: selectedPrimaryClass,
            skillDesc: selectedSkillDesc,
            difficulty: selectedDifficulty,
            seenStatus: selectedSeenStatus,
            isBluebook: selectedBluebook
        )
        isPresented = false
        // Call onApply callback to mark filters as applied
        onApply?()
    }
    
    private func difficultyDescription(_ difficulty: String) -> String {
        switch difficulty {
        case "E": return "Easy"
        case "M": return "Medium"
        case "H": return "Hard"
        default: return difficulty
        }
    }
}

