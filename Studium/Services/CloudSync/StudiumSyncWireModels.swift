//
//  StudiumSyncWireModels.swift
//  Studium
//
//  JSON shapes stored in Supabase `studium_sync` (aligned with studium-web).
//

import Foundation

struct StudiumSyncRowWire: Codable {
    var id: String
    var progress: [String: WireQuestionProgress]
    var deleted_progress: [String: Double]
    var saved_quizzes: [WireSavedQuiz]
    var deleted_quizzes: [String: Double]
    var vocab_buckets: WireVocabBuckets?
    var updated_at: String?
}

struct WireQuestionProgress: Codable {
    var seen: Bool
    var correct: Bool?
    var lastAttempted: Double?
}

struct WireSavedQuiz: Codable {
    var id: String
    var questionIds: [String]
    var currentIndex: Int
    var filters: FilterOptions
    var answerStates: [String: WireAnswerState]
    var lastSaved: Double
}

struct WireAnswerState: Codable {
    var selectedAnswerId: String?
    var hasSubmitted: Bool
    var isCorrect: Bool?
}

struct WireVocabBuckets: Codable {
    var words: [String: String]?
    var roots: [String: String]?
    var wordTimestamps: [String: Double]?
    var rootTimestamps: [String: Double]?
}

enum StudiumSyncWireCodec {
    static func ms(from date: Date?) -> Double? {
        date.map { $0.timeIntervalSince1970 * 1000 }
    }

    static func date(fromMs ms: Double?) -> Date? {
        guard let ms else { return nil }
        return Date(timeIntervalSince1970: ms / 1000)
    }

    static func wireProgress(from local: [String: QuestionProgress]) -> [String: WireQuestionProgress] {
        local.mapValues { p in
            WireQuestionProgress(
                seen: p.seen,
                correct: p.correct,
                lastAttempted: ms(from: p.lastAttempted)
            )
        }
    }

    static func localProgress(from wire: [String: WireQuestionProgress]) -> [String: QuestionProgress] {
        wire.mapValues { w in
            QuestionProgress(
                seen: w.seen,
                correct: w.correct,
                lastAttempted: date(fromMs: w.lastAttempted)
            )
        }
    }

    static func wireQuizzes(from local: [QuizState]) -> [WireSavedQuiz] {
        local.map { q in
            WireSavedQuiz(
                id: q.id,
                questionIds: q.questionIds,
                currentIndex: q.currentIndex,
                filters: q.filters,
                answerStates: q.answerStates.mapValues { a in
                    WireAnswerState(
                        selectedAnswerId: a.selectedAnswerId,
                        hasSubmitted: a.hasSubmitted,
                        isCorrect: a.isCorrect
                    )
                },
                lastSaved: ms(from: q.lastSaved) ?? 0
            )
        }
    }

    static func localQuizzes(from wire: [WireSavedQuiz]) -> [QuizState] {
        wire.map { w in
            var states: [String: QuestionAnswerState] = [:]
            for (qid, a) in w.answerStates {
                states[qid] = QuestionAnswerState(
                    questionId: qid,
                    selectedAnswerId: a.selectedAnswerId,
                    hasSubmitted: a.hasSubmitted,
                    isCorrect: a.isCorrect
                )
            }
            return QuizState(
                id: w.id,
                filters: w.filters,
                currentIndex: w.currentIndex,
                questionIds: w.questionIds,
                answerStates: states,
                lastSaved: date(fromMs: w.lastSaved) ?? Date()
            )
        }
    }

    static func wireDeleted(from local: [String: Date]) -> [String: Double] {
        local.mapValues { $0.timeIntervalSince1970 * 1000 }
    }

    static func localDeleted(from wire: [String: Double]) -> [String: Date] {
        wire.mapValues { Date(timeIntervalSince1970: $0 / 1000) }
    }
}
