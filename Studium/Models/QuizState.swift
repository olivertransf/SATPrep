//
//  QuizState.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation
import Combine

// MARK: - Question Answer State
struct QuestionAnswerState: Codable {
    var questionId: String
    var selectedAnswerId: String?
    var hasSubmitted: Bool
    var isCorrect: Bool?
    var struckOutOptionIds: [String]

    init(
        questionId: String,
        selectedAnswerId: String? = nil,
        hasSubmitted: Bool = false,
        isCorrect: Bool? = nil,
        struckOutOptionIds: [String] = []
    ) {
        self.questionId = questionId
        self.selectedAnswerId = selectedAnswerId
        self.hasSubmitted = hasSubmitted
        self.isCorrect = isCorrect
        self.struckOutOptionIds = struckOutOptionIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decode(String.self, forKey: .questionId)
        selectedAnswerId = try container.decodeIfPresent(String.self, forKey: .selectedAnswerId)
        hasSubmitted = try container.decode(Bool.self, forKey: .hasSubmitted)
        isCorrect = try container.decodeIfPresent(Bool.self, forKey: .isCorrect)
        struckOutOptionIds = try container.decodeIfPresent([String].self, forKey: .struckOutOptionIds) ?? []
    }
}

// MARK: - Quiz State
struct QuizState: Codable, Identifiable {
    var id: String
    var filters: FilterOptions
    var currentIndex: Int
    var questionIds: [String] // Store question IDs to restore the exact quiz
    var answerStates: [String: QuestionAnswerState] // Store answer state for each question
    var lastSaved: Date
    
    init(
        id: String = UUID().uuidString,
        filters: FilterOptions = FilterOptions(),
        currentIndex: Int = 0,
        questionIds: [String] = [],
        answerStates: [String: QuestionAnswerState] = [:],
        lastSaved: Date = Date()
    ) {
        self.id = id
        self.filters = filters
        self.currentIndex = currentIndex
        self.questionIds = questionIds
        self.answerStates = answerStates
        self.lastSaved = lastSaved
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        filters = try c.decode(FilterOptions.self, forKey: .filters)
        currentIndex = try c.decode(Int.self, forKey: .currentIndex)
        questionIds = try c.decode([String].self, forKey: .questionIds)
        answerStates = try c.decode([String: QuestionAnswerState].self, forKey: .answerStates)
        if let date = try? c.decode(Date.self, forKey: .lastSaved) {
            lastSaved = date
        } else if let ms = try? c.decode(Double.self, forKey: .lastSaved) {
            lastSaved = Date(timeIntervalSince1970: ms / 1000)
        } else {
            lastSaved = Date()
        }
    }

    var hasActiveQuiz: Bool {
        return !questionIds.isEmpty && currentIndex < questionIds.count
    }
    
    // Helper to get filter tags for display
    func filterTags() -> [String] {
        var parts: [String] = []
        if let program = filters.program {
            parts.append(program)
        }
        if let module = filters.module {
            parts.append(QuestionBankFilterLabels.sectionNameForSummary(module: module))
        }
        if let difficulty = filters.difficulty {
            let diffDesc = difficulty == "E" ? "Easy" : (difficulty == "M" ? "Medium" : (difficulty == "H" ? "Hard" : difficulty))
            parts.append(diffDesc)
        }
        if filters.answerStatus != .all {
            parts.append(filters.answerStatus.rawValue)
        }
        if let primaryClass = filters.primaryClassCdDesc {
            parts.append(primaryClass)
        }
        if let skill = filters.skillDesc {
            parts.append(skill)
        }
        if let bb = filters.isBluebook {
            parts.append(QuestionBankFilterLabels.displayTitle(for: bb))
        }
        if filters.cbVerifiedInactive == .onlyVerifiedOffCBPracticeTests {
            parts.append(QuestionBankFilterLabels.cbVerifiedChipOnly)
        }
        return parts.isEmpty ? ["All Questions"] : parts
    }

    // Helper to get a description of filters for display
    func filterDescription() -> String {
        filterTags().joined(separator: " • ")
    }
}

// MARK: - Quiz State Manager
class QuizStateManager: ObservableObject {
    static let shared = QuizStateManager()
    
    private let userDefaultsKey = "savedQuizStates"
    private let deletedQuizzesKey = "deletedQuizStates"
    
    @Published private(set) var savedQuizzes: [QuizState] = []
    private var deletedQuizTimestamps: [String: Date] = [:]
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: deletedQuizzesKey) {
            if let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
                deletedQuizTimestamps = decoded
            } else if let ms = try? JSONDecoder().decode([String: Double].self, from: data) {
                deletedQuizTimestamps = ms.mapValues { Date(timeIntervalSince1970: $0 / 1000) }
            }
        }
        loadAllQuizStates()
    }
    
    func loadAllQuizStates() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([QuizState].self, from: data) {
            savedQuizzes = decoded.filter { !$0.questionIds.isEmpty }.sorted { $0.lastSaved > $1.lastSaved }
        } else {
            savedQuizzes = []
        }
    }
    
    func saveQuizState(_ state: QuizState) {
        // Only save if quiz has questions
        guard !state.questionIds.isEmpty else { return }
        
        var updatedState = state
        updatedState.lastSaved = Date()
        
        // Update or add the quiz state
        if let index = savedQuizzes.firstIndex(where: { $0.id == state.id }) {
            savedQuizzes[index] = updatedState
        } else {
            savedQuizzes.append(updatedState)
        }
        
        savedQuizzes.sort { $0.lastSaved > $1.lastSaved }
        savedQuizzes = Array(savedQuizzes.prefix(10))

        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        StudiumLocalDataNotify.changed()
    }
    
    func loadQuizState(id: String) -> QuizState? {
        return savedQuizzes.first { $0.id == id }
    }
    
    func deleteQuizState(id: String) {
        savedQuizzes.removeAll { $0.id == id }
        
        // Track deletion timestamp
        deletedQuizTimestamps[id] = Date()
        
        // Save deleted timestamps
        if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedQuizzesKey)
        }
        
        // Save updated quiz list
        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        StudiumLocalDataNotify.changed()
    }

    func exportQuizzesForSync() -> [QuizState] {
        savedQuizzes
    }

    func exportDeletedQuizzesForSync() -> [String: Date] {
        deletedQuizTimestamps
    }

    func applyFromSync(quizzes: [QuizState], deleted: [String: Date]) {
        savedQuizzes = quizzes
            .filter { !$0.questionIds.isEmpty }
            .sorted { $0.lastSaved > $1.lastSaved }
        savedQuizzes = Array(savedQuizzes.prefix(10))
        deletedQuizTimestamps = deleted
        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedQuizzesKey)
        }
    }
    
    func clearAllQuizStates() {
        let now = Date()
        for quiz in savedQuizzes {
            deletedQuizTimestamps[quiz.id] = now
        }
        savedQuizzes.removeAll()
        if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedQuizzesKey)
        }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        StudiumLocalDataNotify.changed()
    }
    
    // Legacy support - get the most recent quiz
    func loadQuizState() -> QuizState? {
        return savedQuizzes.first
    }
    
    // Legacy support - clear (removes most recent)
    func clearQuizState() {
        if let first = savedQuizzes.first {
            deleteQuizState(id: first.id)
        }
    }
}

