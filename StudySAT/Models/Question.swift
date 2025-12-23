//
//  Question.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation

// MARK: - Question Container
struct QuestionContainer: Codable {
    let questions: [String: Question]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dict = try container.decode([String: Question].self)
        self.questions = dict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(questions)
    }
}

// MARK: - Question
struct Question: Codable, Identifiable {
    let id: String // uId
    let updateDate: Int64?
    let pPcc: String?
    let questionId: String
    let skillCd: String?
    let scoreBandRangeCd: Int?
    let skillDesc: String
    let createDate: Int64?
    let program: String
    let primaryClassCdDesc: String
    let ibn: String?
    let externalId: String?
    let primaryClassCd: String
    let difficulty: String
    let module: String
    let content: QuestionContent
    
    enum CodingKeys: String, CodingKey {
        case updateDate
        case pPcc
        case questionId
        case skillCd = "skill_cd"
        case scoreBandRangeCd = "score_band_range_cd"
        case uId
        case skillDesc = "skill_desc"
        case createDate
        case program
        case primaryClassCdDesc = "primary_class_cd_desc"
        case ibn
        case externalId = "external_id"
        case primaryClassCd = "primary_class_cd"
        case difficulty
        case module
        case content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.updateDate = try container.decodeIfPresent(Int64.self, forKey: .updateDate)
        self.pPcc = try container.decodeIfPresent(String.self, forKey: .pPcc)
        self.questionId = try container.decode(String.self, forKey: .questionId)
        self.skillCd = try container.decodeIfPresent(String.self, forKey: .skillCd)
        self.scoreBandRangeCd = try container.decodeIfPresent(Int.self, forKey: .scoreBandRangeCd)
        self.id = try container.decode(String.self, forKey: .uId)
        self.skillDesc = try container.decode(String.self, forKey: .skillDesc)
        self.createDate = try container.decodeIfPresent(Int64.self, forKey: .createDate)
        self.program = try container.decode(String.self, forKey: .program)
        self.primaryClassCdDesc = try container.decode(String.self, forKey: .primaryClassCdDesc)
        self.ibn = try container.decodeIfPresent(String.self, forKey: .ibn)
        self.externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        self.primaryClassCd = try container.decode(String.self, forKey: .primaryClassCd)
        self.difficulty = try container.decode(String.self, forKey: .difficulty)
        self.module = try container.decode(String.self, forKey: .module)
        self.content = try container.decode(QuestionContent.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(updateDate, forKey: .updateDate)
        try container.encodeIfPresent(pPcc, forKey: .pPcc)
        try container.encode(questionId, forKey: .questionId)
        try container.encodeIfPresent(skillCd, forKey: .skillCd)
        try container.encodeIfPresent(scoreBandRangeCd, forKey: .scoreBandRangeCd)
        try container.encode(id, forKey: .uId)
        try container.encode(skillDesc, forKey: .skillDesc)
        try container.encodeIfPresent(createDate, forKey: .createDate)
        try container.encode(program, forKey: .program)
        try container.encode(primaryClassCdDesc, forKey: .primaryClassCdDesc)
        try container.encodeIfPresent(ibn, forKey: .ibn)
        try container.encodeIfPresent(externalId, forKey: .externalId)
        try container.encode(primaryClassCd, forKey: .primaryClassCd)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(module, forKey: .module)
        try container.encode(content, forKey: .content)
    }
}

// MARK: - Question Content
struct QuestionContent: Codable {
    // Common fields
    let rationale: String?
    let stem: String?
    let stimulus: String?
    let type: String?
    let answerOptions: [AnswerOption]?
    let correctAnswer: [String]?
    
    // Alternative structure fields (for questions with "answer" object)
    let prompt: String?
    let body: String? // Sometimes used as stimulus
    let answer: AnswerObject?
    
    // Other fields
    let keys: [String]?
    let origin: String?
    let externalid: String?
    let templateid: String?
    let vaultid: String?
    let itemId: String?
    let section: String?
    
    enum CodingKeys: String, CodingKey {
        case rationale
        case stem
        case stimulus
        case type
        case answerOptions
        case correctAnswer = "correct_answer"
        case prompt
        case body
        case answer
        case keys
        case origin
        case externalid
        case templateid
        case vaultid
        case itemId = "item_id"
        case section
    }
    
    // Computed properties to normalize access
    var displayStem: String? {
        return stem ?? prompt
    }
    
    var displayStimulus: String? {
        return stimulus ?? body
    }
    
    var displayAnswerOptions: [AnswerOption] {
        if let answerOptions = answerOptions {
            // Add labels if not present
            return answerOptions.enumerated().map { index, option in
                if option.label != nil {
                    return option
                } else {
                    return AnswerOption(id: option.id, content: option.content, label: String(Character(UnicodeScalar(65 + index)!)))
                }
            }
        } else if let answer = answer, let choices = answer.choices {
            // Convert choices dictionary to AnswerOption array, maintaining order
            let sortedChoices = choices.sorted { $0.key < $1.key }
            return sortedChoices.enumerated().map { index, item in
                AnswerOption(id: item.key, content: item.value.body, label: String(Character(UnicodeScalar(65 + index)!)))
            }
        }
        return []
    }
    
    var displayCorrectAnswer: [String] {
        if let correctAnswer = correctAnswer {
            return correctAnswer
        } else if let answer = answer, let correctChoice = answer.correctChoice {
            return [correctChoice.uppercased()]
        }
        return []
    }
}

// MARK: - Answer Option
struct AnswerOption: Codable, Identifiable {
    let id: String
    let content: String
    let label: String? // A, B, C, D
    
    init(id: String, content: String, label: String? = nil) {
        self.id = id
        self.content = content
        self.label = label
    }
}

// MARK: - Answer Object (for alternative structure)
struct AnswerObject: Codable {
    let style: String?
    let choices: [String: Choice]?
    let correctChoice: String?
    let rationale: String?
    
    enum CodingKeys: String, CodingKey {
        case style
        case choices
        case correctChoice = "correct_choice"
        case rationale
    }
}

struct Choice: Codable {
    let body: String
}

