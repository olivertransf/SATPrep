//
//  StudiumSyncWireModels.swift
//  Studium
//

import FirebaseFirestore
import Foundation

/// Firestore payload shape — matches `studium-web` `users/{uid}/sync/data`.
struct StudiumSyncPayloadWire: Codable, Sendable {
    var progress: [String: QuestionProgressWire]
    var deletedProgress: [String: Double]
    var savedQuizzes: [QuizStateWire]
    var deletedQuizzes: [String: Double]
    var vocabBuckets: VocabBucketsWire
    var clientUpdatedAt: Double

    static let empty = StudiumSyncPayloadWire(
        progress: [:],
        deletedProgress: [:],
        savedQuizzes: [],
        deletedQuizzes: [:],
        vocabBuckets: .empty,
        clientUpdatedAt: 0
    )
}

struct QuestionProgressWire: Codable, Sendable {
    var seen: Bool
    var correct: Bool?
    var lastAttempted: Double?
}

struct QuestionAnswerStateWire: Codable, Sendable {
    var selectedAnswerId: String?
    var hasSubmitted: Bool
    var isCorrect: Bool?
}

struct QuizStateWire: Codable, Sendable {
    var id: String
    var questionIds: [String]
    var currentIndex: Int
    var filters: FilterOptions
    var answerStates: [String: QuestionAnswerStateWire]
    var lastSaved: Double
}

struct VocabBucketsWire: Codable, Sendable {
    var words: [String: String]
    var roots: [String: String]
    var wordTimestamps: [String: Double]
    var rootTimestamps: [String: Double]

    static let empty = VocabBucketsWire(
        words: [:],
        roots: [:],
        wordTimestamps: [:],
        rootTimestamps: [:]
    )
}

enum StudiumSyncWireError: Error {
    case invalidPayload
}

@MainActor
enum StudiumSyncWireCodec {
    static func ms(_ date: Date) -> Double {
        date.timeIntervalSince1970 * 1000
    }

    static func date(fromMs ms: Double) -> Date {
        Date(timeIntervalSince1970: ms / 1000)
    }

    static func firestoreData(from payload: StudiumSyncPayloadWire) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let json = try encoder.encode(payload)
        guard let object = try JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            throw StudiumSyncWireError.invalidPayload
        }
        return object
    }

    static func payload(from data: [String: Any]) throws -> StudiumSyncPayloadWire {
        let normalized = normalizeFirestoreValue(data) as? [String: Any] ?? [:]
        let json = try JSONSerialization.data(withJSONObject: normalized)
        let decoder = JSONDecoder()
        return try decoder.decode(StudiumSyncPayloadWire.self, from: json)
    }

    private static func normalizeFirestoreValue(_ value: Any) -> Any {
        switch value {
        case let timestamp as Timestamp:
            return timestamp.dateValue().timeIntervalSince1970 * 1000
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            return number.doubleValue.truncatingRemainder(dividingBy: 1) == 0
                ? number.int64Value
                : number.doubleValue
        case let dict as [String: Any]:
            return dict.mapValues(normalizeFirestoreValue)
        case let array as [Any]:
            return array.map(normalizeFirestoreValue)
        default:
            return value
        }
    }

    static func progressToWire(_ progress: [String: QuestionProgress]) -> [String: QuestionProgressWire] {
        progress.mapValues { p in
            QuestionProgressWire(
                seen: p.seen,
                correct: p.correct,
                lastAttempted: p.lastAttempted.map(ms)
            )
        }
    }

    static func progressFromWire(_ wire: [String: QuestionProgressWire]) -> [String: QuestionProgress] {
        wire.mapValues { w in
            QuestionProgress(
                seen: w.seen,
                correct: w.correct,
                lastAttempted: w.lastAttempted.map(date(fromMs:))
            )
        }
    }

    static func deletedToWire(_ map: [String: Date]) -> [String: Double] {
        map.mapValues(ms)
    }

    static func deletedFromWire(_ wire: [String: Double]) -> [String: Date] {
        wire.mapValues(date(fromMs:))
    }

    static func quizToWire(_ quiz: QuizState) -> QuizStateWire {
        QuizStateWire(
            id: quiz.id,
            questionIds: quiz.questionIds,
            currentIndex: quiz.currentIndex,
            filters: quiz.filters,
            answerStates: quiz.answerStates.mapValues { state in
                QuestionAnswerStateWire(
                    selectedAnswerId: state.selectedAnswerId,
                    hasSubmitted: state.hasSubmitted,
                    isCorrect: state.isCorrect
                )
            },
            lastSaved: ms(quiz.lastSaved)
        )
    }

    static func quizFromWire(_ wire: QuizStateWire) -> QuizState {
        var answerStates: [String: QuestionAnswerState] = [:]
        for (qid, w) in wire.answerStates {
            answerStates[qid] = QuestionAnswerState(
                questionId: qid,
                selectedAnswerId: w.selectedAnswerId,
                hasSubmitted: w.hasSubmitted,
                isCorrect: w.isCorrect
            )
        }
        return QuizState(
            id: wire.id,
            filters: wire.filters,
            currentIndex: wire.currentIndex,
            questionIds: wire.questionIds,
            answerStates: answerStates,
            lastSaved: date(fromMs: wire.lastSaved)
        )
    }

    static func vocabToWire(
        words: [String: String],
        roots: [String: String],
        wordTimestamps: [String: Date],
        rootTimestamps: [String: Date]
    ) -> VocabBucketsWire {
        VocabBucketsWire(
            words: words,
            roots: roots,
            wordTimestamps: wordTimestamps.mapValues(ms),
            rootTimestamps: rootTimestamps.mapValues(ms)
        )
    }

    static func vocabFromWire(_ wire: VocabBucketsWire) -> (
        words: [String: String],
        roots: [String: String],
        wordTimestamps: [String: Date],
        rootTimestamps: [String: Date]
    ) {
        (
            words: wire.words,
            roots: wire.roots,
            wordTimestamps: wire.wordTimestamps.mapValues(date(fromMs:)),
            rootTimestamps: wire.rootTimestamps.mapValues(date(fromMs:))
        )
    }
}
