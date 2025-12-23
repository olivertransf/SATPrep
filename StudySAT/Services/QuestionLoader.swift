//
//  QuestionLoader.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation
import Combine

class QuestionLoader: ObservableObject {
    static let shared = QuestionLoader()
    
    @Published private(set) var questions: [Question] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let jsonFileName = "cb-digital-questions"
    
    private init() {
        loadQuestions()
    }
    
    func loadQuestions() {
        isLoading = true
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                guard let url = Bundle.main.url(forResource: self.jsonFileName, withExtension: "json") else {
                    throw QuestionLoaderError.fileNotFound
                }
                
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let questionDict = try decoder.decode([String: Question].self, from: data)
                
                let questionsArray = Array(questionDict.values)
                
                DispatchQueue.main.async {
                    self.questions = questionsArray
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func getFilteredQuestions(filters: FilterOptions, progressManager: ProgressManager) -> [Question] {
        var filtered = questions
        
        // Apply filters using the matches method
        filtered = filtered.filter { filters.matches($0) }
        
        // Apply seen status filter
        switch filters.seenStatus {
        case .seen:
            filtered = filtered.filter { progressManager.isSeen(questionId: $0.questionId) }
        case .unseen:
            filtered = filtered.filter { !progressManager.isSeen(questionId: $0.questionId) }
        case .all:
            break
        }
        
        return filtered
    }
    
    // Get unique values for filter options
    func getAvailablePrograms() -> [String] {
        Array(Set(questions.map { $0.program })).sorted()
    }
    
    func getAvailableModules() -> [String] {
        Array(Set(questions.map { $0.module })).sorted()
    }
    
    func getAvailablePrimaryClasses(for module: String?) -> [String] {
        let filtered = module != nil ? questions.filter { $0.module == module } : questions
        return Array(Set(filtered.map { $0.primaryClassCdDesc })).sorted()
    }
    
    func getAvailableSkillDescs(for module: String?, primaryClass: String?) -> [String] {
        var filtered = questions
        if let module = module {
            filtered = filtered.filter { $0.module == module }
        }
        if let primaryClass = primaryClass {
            filtered = filtered.filter { $0.primaryClassCdDesc == primaryClass }
        }
        return Array(Set(filtered.map { $0.skillDesc })).sorted()
    }
    
    func getAvailableDifficulties() -> [String] {
        Array(Set(questions.map { $0.difficulty })).sorted()
    }
    
    // Get questions matching specific criteria for reset operations
    func getQuestions(byProgram program: String) -> [Question] {
        questions.filter { $0.program == program }
    }
    
    func getQuestions(byModule module: String) -> [Question] {
        questions.filter { $0.module == module }
    }
    
    func getQuestions(byPrimaryClass primaryClass: String) -> [Question] {
        questions.filter { $0.primaryClassCdDesc == primaryClass }
    }
    
    func getQuestions(bySkillDesc skillDesc: String) -> [Question] {
        questions.filter { $0.skillDesc == skillDesc }
    }
    
    func getQuestions(byDifficulty difficulty: String) -> [Question] {
        questions.filter { $0.difficulty == difficulty }
    }
}

enum QuestionLoaderError: LocalizedError {
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Question file not found in bundle"
        }
    }
}

