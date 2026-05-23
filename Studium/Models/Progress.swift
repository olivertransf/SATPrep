//
//  Progress.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation

// MARK: - Question Progress
struct QuestionProgress: Codable {
    var seen: Bool
    var correct: Bool?
    var lastAttempted: Date?

    enum CodingKeys: String, CodingKey {
        case seen
        case correct
        case lastAttempted
    }

    init(seen: Bool = false, correct: Bool? = nil, lastAttempted: Date? = nil) {
        self.seen = seen
        self.correct = correct
        self.lastAttempted = lastAttempted
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seen = try c.decode(Bool.self, forKey: .seen)
        correct = try c.decodeIfPresent(Bool.self, forKey: .correct)
        lastAttempted = Self.decodeFlexibleDate(from: c, forKey: .lastAttempted)
    }

    private static func decodeFlexibleDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        guard let value = try? container.decodeIfPresent(Double.self, forKey: key) else {
            return nil
        }
        if value > 1_000_000_000_000 {
            return Date(timeIntervalSince1970: value / 1000)
        }
        if value > 1_000_000_000 {
            return Date(timeIntervalSince1970: value)
        }
        return Date(timeIntervalSince1970: value / 1000)
    }
}

// MARK: - Progress Data
struct ProgressData: Codable {
    var progress: [String: QuestionProgress]
    
    init(progress: [String: QuestionProgress] = [:]) {
        self.progress = progress
    }
}

