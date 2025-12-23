//
//  Progress.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation

// MARK: - Question Progress
struct QuestionProgress: Codable {
    var seen: Bool
    var correct: Bool?
    var lastAttempted: Date?
    
    init(seen: Bool = false, correct: Bool? = nil, lastAttempted: Date? = nil) {
        self.seen = seen
        self.correct = correct
        self.lastAttempted = lastAttempted
    }
}

// MARK: - Progress Data
struct ProgressData: Codable {
    var progress: [String: QuestionProgress]
    
    init(progress: [String: QuestionProgress] = [:]) {
        self.progress = progress
    }
}

