//
//  QuestionLoader.swift
//  Studium
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

    /// Fast quiz restore / lookups — built once when JSON loads.
    private(set) var questionsById: [String: Question] = [:]
    private(set) var questionIdsByModule: [String: Set<String>] = [:]
    private(set) var questionIdsByDifficulty: [String: Set<String>] = [:]
    private(set) var questionIdsByPrimaryClass: [String: Set<String>] = [:]
    private(set) var questionIdsByProgram: [String: Set<String>] = [:]
    private(set) var questionIdsBySkillDesc: [String: Set<String>] = [:]

    private(set) var sortedModules: [String] = []
    private(set) var sortedDifficulties: [String] = []
    private(set) var sortedPrograms: [String] = []
    private(set) var sortedPrimaryClassesAll: [String] = []

    /// Count of questions with non-empty `ibn` (or Bluebook in `content.origin`). Updated when JSON loads.
    private(set) var bluebookTaggedCount: Int = 0
    private(set) var bluebookTaggedMathCount: Int = 0
    private(set) var bluebookTaggedEnglishCount: Int = 0

    /// `questionId` values from `cb-verified-not-on-practice-tests.json` (Educator Bank HTML scrape, exclude active).
    private(set) var cbVerifiedNotOnPracticeTestIds: Set<String> = []
    private(set) var cbVerifiedInBankCount: Int = 0
    
    private let jsonFileName = "cb-digital-questions"
    private let cbVerifiedSidecarName = "cb-verified-not-on-practice-tests"
    
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
                let verifiedIds = Self.loadCBVerifiedNotOnPracticeTestIds(bundle: .main)
                let bankIds = Set(questionsArray.map { $0.questionId.lowercased() })
                let verifiedInBank = verifiedIds.intersection(bankIds).count
                
                DispatchQueue.main.async {
                    self.cbVerifiedNotOnPracticeTestIds = verifiedIds
                    self.cbVerifiedInBankCount = verifiedInBank
                    self.questions = questionsArray
                    self.rebuildIndexes(from: questionsArray)
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
    
    func getHardMCQuestions() -> [Question] {
        let hardIds = questionIdsByDifficulty["H"] ?? []
        let englishIds = questionIdsByModule["english"] ?? []
        return hardIds.intersection(englishIds)
            .compactMap { questionsById[$0] }
            .filter { !$0.content.displayAnswerOptions.isEmpty }
    }

    /// Medium or hard MC questions across all modules (used by menu bar + break overlay).
    func getMediumAndHardMCQuestions() -> [Question] {
        let hardIds = questionIdsByDifficulty["H"] ?? []
        let mediumIds = questionIdsByDifficulty["M"] ?? []
        return hardIds.union(mediumIds)
            .compactMap { questionsById[$0] }
            .filter { !$0.content.displayAnswerOptions.isEmpty }
    }

    func getFilteredQuestions(filters: FilterOptions, progressManager: ProgressManager) -> [Question] {
        filters.filteredQuestions(
            from: questions,
            progress: progressManager.progress,
            cbVerifiedNotOnPracticeTestIds: cbVerifiedNotOnPracticeTestIds
        )
    }

    /// Returns count of questions matching filters (without shuffle/limit) for preview
    func getFilteredQuestionCount(filters: FilterOptions, progressManager: ProgressManager) -> Int {
        let previewFilters = FilterOptions(
            program: filters.program,
            module: filters.module,
            primaryClassCdDesc: filters.primaryClassCdDesc,
            skillDesc: filters.skillDesc,
            difficulty: filters.difficulty,
            answerStatus: filters.answerStatus,
            isBluebook: filters.isBluebook,
            cbVerifiedInactive: filters.cbVerifiedInactive,
            shuffled: false,
            questionLimit: nil
        )
        return getFilteredQuestions(filters: previewFilters, progressManager: progressManager).count
    }
    
    // Get unique values for filter options (cached when the bank loads)
    func getAvailablePrograms() -> [String] {
        sortedPrograms
    }
    
    func getAvailableModules() -> [String] {
        sortedModules
    }
    
    func getAvailablePrimaryClasses(for module: String?) -> [String] {
        guard let module else { return sortedPrimaryClassesAll }
        guard let ids = questionIdsByModule[module] else { return [] }
        var classes = Set<String>()
        classes.reserveCapacity(ids.count)
        for id in ids {
            if let q = questionsById[id] { classes.insert(q.primaryClassCdDesc) }
        }
        return classes.sorted()
    }
    
    func getAvailableSkillDescs(for module: String?, primaryClass: String?) -> [String] {
        let idPool: Set<String>
        switch (module, primaryClass) {
        case (nil, nil):
            return Array(questionIdsBySkillDesc.keys).sorted()
        case let (m?, nil):
            idPool = questionIdsByModule[m] ?? []
        case let (nil, p?):
            idPool = questionIdsByPrimaryClass[p] ?? []
        case let (m?, p?):
            let modIds = questionIdsByModule[m] ?? []
            let classIds = questionIdsByPrimaryClass[p] ?? []
            idPool = modIds.intersection(classIds)
        }
        var skills = Set<String>()
        for id in idPool {
            if let q = questionsById[id] { skills.insert(q.skillDesc) }
        }
        return skills.sorted()
    }
    
    func getAvailableDifficulties() -> [String] {
        sortedDifficulties
    }

    private func rebuildIndexes(from questions: [Question]) {
        var byId: [String: Question] = [:]
        byId.reserveCapacity(questions.count)
        var byModule: [String: Set<String>] = [:]
        var byDifficulty: [String: Set<String>] = [:]
        var byPrimary: [String: Set<String>] = [:]
        var byProgram: [String: Set<String>] = [:]
        var bySkill: [String: Set<String>] = [:]

        for q in questions {
            let id = q.questionId
            byId[id] = q
            byModule[q.module, default: []].insert(id)
            byDifficulty[q.difficulty, default: []].insert(id)
            byPrimary[q.primaryClassCdDesc, default: []].insert(id)
            byProgram[q.program, default: []].insert(id)
            bySkill[q.skillDesc, default: []].insert(id)
        }

        questionsById = byId
        questionIdsByModule = byModule
        questionIdsByDifficulty = byDifficulty
        questionIdsByPrimaryClass = byPrimary
        questionIdsByProgram = byProgram
        questionIdsBySkillDesc = bySkill
        sortedModules = byModule.keys.sorted()
        sortedDifficulties = byDifficulty.keys.sorted()
        sortedPrograms = byProgram.keys.sorted()
        sortedPrimaryClassesAll = byPrimary.keys.sorted()

        var bb = 0
        var bbMath = 0
        var bbEnglish = 0
        for q in questions where q.isBluebookTagged {
            bb += 1
            if q.module.caseInsensitiveCompare("math") == .orderedSame {
                bbMath += 1
            }
            if q.module.localizedCaseInsensitiveContains("english") {
                bbEnglish += 1
            }
        }
        bluebookTaggedCount = bb
        bluebookTaggedMathCount = bbMath
        bluebookTaggedEnglishCount = bbEnglish
    }
    
    // Get questions matching specific criteria for reset operations
    func getQuestions(byProgram program: String) -> [Question] {
        (questionIdsByProgram[program] ?? []).compactMap { questionsById[$0] }
    }
    
    func getQuestions(byModule module: String) -> [Question] {
        (questionIdsByModule[module] ?? []).compactMap { questionsById[$0] }
    }
    
    func getQuestions(byPrimaryClass primaryClass: String) -> [Question] {
        (questionIdsByPrimaryClass[primaryClass] ?? []).compactMap { questionsById[$0] }
    }
    
    func getQuestions(bySkillDesc skillDesc: String) -> [Question] {
        (questionIdsBySkillDesc[skillDesc] ?? []).compactMap { questionsById[$0] }
    }
    
    func getQuestions(byDifficulty difficulty: String) -> [Question] {
        (questionIdsByDifficulty[difficulty] ?? []).compactMap { questionsById[$0] }
    }

    private static func loadCBVerifiedNotOnPracticeTestIds(bundle: Bundle) -> Set<String> {
        guard let url = bundle.url(forResource: "cb-verified-not-on-practice-tests", withExtension: "json") else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else { return [] }

        struct Manifest: Codable {
            var questionIds: [String]
        }

        if let manifest = try? JSONDecoder().decode(Manifest.self, from: data) {
            return Set(manifest.questionIds.map { $0.lowercased() })
        }
        if let raw = try? JSONDecoder().decode([String].self, from: data) {
            return Set(raw.map { $0.lowercased() })
        }
        return []
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

