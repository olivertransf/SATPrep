//
//  FilterOptions.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation

// MARK: - Filter Options
struct FilterOptions: Codable, Equatable, Hashable {
    var program: String?
    var module: String?
    var primaryClassCdDesc: String?
    var skillDesc: String?
    var difficulty: String?
    var answerStatus: AnswerStatus
    var isBluebook: BluebookFilter?
    /// IDs from Educator Question Bank HTML (exclude active) — see `cb-verified-not-on-practice-tests.json`.
    var cbVerifiedInactive: CBVerifiedInactiveFilter?
    var shuffled: Bool
    var questionLimit: Int?

    enum AnswerStatus: String, Codable, CaseIterable {
        case all = "All"
        case unanswered = "Unanswered"
        case incorrect = "Answered Incorrectly"
        case correct = "Answered Correctly"
    }

    enum BluebookFilter: String, Codable, CaseIterable {
        case all = "All"
        case bluebook = "Bluebook"
        case notBluebook = "Not Bluebook"
    }

    /// Restrict to question IDs scraped from CB Educator Bank with “Exclude Active Questions”.
    enum CBVerifiedInactiveFilter: String, Codable, CaseIterable {
        case ignore = "Any"
        case onlyVerifiedOffCBPracticeTests = "Verified off practice tests"
    }

    enum SortOrder: String, Codable, CaseIterable {
        case original = "Default"
        case random = "Random"
        case easyFirst = "Easy First"
        case hardFirst = "Hard First"
    }

    init(
        program: String? = nil,
        module: String? = nil,
        primaryClassCdDesc: String? = nil,
        skillDesc: String? = nil,
        difficulty: String? = nil,
        answerStatus: AnswerStatus = .all,
        isBluebook: BluebookFilter? = nil,
        cbVerifiedInactive: CBVerifiedInactiveFilter? = nil,
        shuffled: Bool = true,
        questionLimit: Int? = nil
    ) {
        self.program = program
        self.module = module
        self.primaryClassCdDesc = primaryClassCdDesc
        self.skillDesc = skillDesc
        self.difficulty = difficulty
        self.answerStatus = answerStatus
        self.isBluebook = isBluebook
        self.cbVerifiedInactive = cbVerifiedInactive
        self.shuffled = shuffled
        self.questionLimit = questionLimit
    }
    
    nonisolated func matches(_ question: Question, cbVerifiedNotOnPracticeTestIds: Set<String>) -> Bool {
        if let program = program, question.program != program {
            return false
        }
        if let module = module, question.module != module {
            return false
        }
        if let primaryClassCdDesc = primaryClassCdDesc, question.primaryClassCdDesc != primaryClassCdDesc {
            return false
        }
        if let skillDesc = skillDesc, question.skillDesc != skillDesc {
            return false
        }
        if let difficulty = difficulty, question.difficulty != difficulty {
            return false
        }
        if let isBluebook = isBluebook {
            let questionIsBluebook = question.isBluebookTagged
            switch isBluebook {
            case .bluebook:
                if !questionIsBluebook {
                    return false
                }
            case .notBluebook:
                if questionIsBluebook {
                    return false
                }
            case .all:
                break
            }
        }
        if cbVerifiedInactive == .onlyVerifiedOffCBPracticeTests {
            if !cbVerifiedNotOnPracticeTestIds.contains(question.questionId.lowercased()) {
                return false
            }
        }
        return true
    }

    /// Pure filter for use off the main actor (pass a snapshot of `questions` and `progress`).
    nonisolated func filteredQuestions(
        from questions: [Question],
        progress: [String: QuestionProgress],
        cbVerifiedNotOnPracticeTestIds: Set<String>
    ) -> [Question] {
        var filtered = questions.filter { matches($0, cbVerifiedNotOnPracticeTestIds: cbVerifiedNotOnPracticeTestIds) }

        switch answerStatus {
        case .unanswered:
            filtered = filtered.filter { progress[$0.questionId]?.correct == nil }
        case .incorrect:
            filtered = filtered.filter { progress[$0.questionId]?.correct == false }
        case .correct:
            filtered = filtered.filter { progress[$0.questionId]?.correct == true }
        case .all:
            break
        }

        if shuffled {
            filtered.shuffle()
        }

        if let limit = questionLimit, limit > 0, limit < filtered.count {
            filtered = Array(filtered.prefix(limit))
        }

        return filtered
    }
}

