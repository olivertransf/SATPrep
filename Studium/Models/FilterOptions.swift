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

    private enum CodingKeys: String, CodingKey {
        case program
        case module
        case primaryClassCdDesc
        case skillDesc
        case difficulty
        case answerStatus
        case isBluebook
        case cbVerifiedInactive
        case shuffled
        case questionLimit
    }

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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        program = try c.decodeIfPresent(String.self, forKey: .program)
        module = try c.decodeIfPresent(String.self, forKey: .module)
        primaryClassCdDesc = try c.decodeIfPresent(String.self, forKey: .primaryClassCdDesc)
        skillDesc = try c.decodeIfPresent(String.self, forKey: .skillDesc)
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty)
        questionLimit = try c.decodeIfPresent(Int.self, forKey: .questionLimit)
        shuffled = try c.decodeIfPresent(Bool.self, forKey: .shuffled) ?? true

        if let raw = try c.decodeIfPresent(String.self, forKey: .answerStatus) {
            answerStatus = Self.decodeAnswerStatus(raw)
        } else {
            answerStatus = .all
        }

        if let raw = try c.decodeIfPresent(String.self, forKey: .isBluebook) {
            isBluebook = Self.decodeBluebook(raw)
        } else {
            isBluebook = nil
        }

        if let raw = try c.decodeIfPresent(String.self, forKey: .cbVerifiedInactive) {
            cbVerifiedInactive = Self.decodeCBVerified(raw)
        } else {
            cbVerifiedInactive = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(program, forKey: .program)
        try c.encodeIfPresent(module, forKey: .module)
        try c.encodeIfPresent(primaryClassCdDesc, forKey: .primaryClassCdDesc)
        try c.encodeIfPresent(skillDesc, forKey: .skillDesc)
        try c.encodeIfPresent(difficulty, forKey: .difficulty)
        try c.encodeIfPresent(questionLimit, forKey: .questionLimit)
        try c.encode(shuffled, forKey: .shuffled)
        try c.encode(Self.encodeAnswerStatus(answerStatus), forKey: .answerStatus)
        if let isBluebook, isBluebook != .all {
            try c.encode(Self.encodeBluebook(isBluebook), forKey: .isBluebook)
        }
        if let cbVerifiedInactive {
            try c.encode(Self.encodeCBVerified(cbVerifiedInactive), forKey: .cbVerifiedInactive)
        }
    }

    private static func encodeAnswerStatus(_ status: AnswerStatus) -> String {
        switch status {
        case .all: return "all"
        case .unanswered: return "unanswered"
        case .incorrect: return "incorrect"
        case .correct: return "correct"
        }
    }

    private static func encodeBluebook(_ filter: BluebookFilter) -> String {
        switch filter {
        case .bluebook: return "bluebook"
        case .notBluebook: return "notbluebook"
        case .all: return "all"
        }
    }

    private static func encodeCBVerified(_ filter: CBVerifiedInactiveFilter) -> String {
        switch filter {
        case .onlyVerifiedOffCBPracticeTests: return "onlyVerifiedOffCBPracticeTests"
        case .ignore: return "any"
        }
    }

    private static func decodeAnswerStatus(_ raw: String) -> AnswerStatus {
        switch raw.lowercased() {
        case "all": return .all
        case "unanswered": return .unanswered
        case "incorrect": return .incorrect
        case "correct": return .correct
        default: return AnswerStatus(rawValue: raw) ?? .all
        }
    }

    private static func decodeBluebook(_ raw: String) -> BluebookFilter? {
        switch raw.lowercased().replacingOccurrences(of: " ", with: "") {
        case "bluebook": return .bluebook
        case "notbluebook": return .notBluebook
        case "all": return .all
        default: return BluebookFilter(rawValue: raw)
        }
    }

    private static func decodeCBVerified(_ raw: String) -> CBVerifiedInactiveFilter? {
        if raw == CBVerifiedInactiveFilter.onlyVerifiedOffCBPracticeTests.rawValue {
            return .onlyVerifiedOffCBPracticeTests
        }
        switch raw.lowercased() {
        case "onlyverifiedoffcbpracticetests", "verified off practice tests":
            return .onlyVerifiedOffCBPracticeTests
        case "any", "ignore": return nil
        default: return CBVerifiedInactiveFilter(rawValue: raw)
        }
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

