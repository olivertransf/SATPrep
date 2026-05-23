//
//  StudiumSyncMerge.swift
//  Studium
//

import Foundation

enum StudiumSyncMerge {
    static func mergeProgress(
        local: [String: QuestionProgress],
        remote: [String: QuestionProgress],
        localDeleted: [String: Date],
        remoteDeleted: [String: Date]
    ) -> (progress: [String: QuestionProgress], deleted: [String: Date]) {
        var deleted = localDeleted
        for (id, t) in remoteDeleted {
            if let existing = deleted[id] {
                deleted[id] = max(existing, t)
            } else {
                deleted[id] = t
            }
        }

        func progressTime(_ p: QuestionProgress) -> Date {
            p.lastAttempted ?? .distantPast
        }

        var merged: [String: QuestionProgress] = [:]
        let ids = Set(local.keys).union(remote.keys)

        for id in ids {
            let l = local[id]
            let r = remote[id]
            let delAt = deleted[id]

            if let l, let delAt, progressTime(l) <= delAt {
                let remoteAlsoDeleted = r.map { progressTime($0) <= delAt } ?? true
                if remoteAlsoDeleted { continue }
            }
            if let r, let delAt, progressTime(r) <= delAt {
                let localAlsoDeleted = l.map { progressTime($0) <= delAt } ?? true
                if localAlsoDeleted { continue }
            }

            switch (l, r) {
            case (nil, let r?):
                merged[id] = r
            case (let l?, nil):
                merged[id] = l
            case (let l?, let r?):
                merged[id] = progressTime(l) >= progressTime(r) ? l : r
            default:
                break
            }
        }

        return (merged, deleted)
    }

    static func mergeQuizzes(
        local: [QuizState],
        remote: [QuizState],
        localDeleted: [String: Date],
        remoteDeleted: [String: Date]
    ) -> (quizzes: [QuizState], deleted: [String: Date]) {
        var deleted = localDeleted
        for (id, t) in remoteDeleted {
            if let existing = deleted[id] {
                deleted[id] = max(existing, t)
            } else {
                deleted[id] = t
            }
        }

        var byId: [String: QuizState] = [:]
        for q in local + remote {
            if let delAt = deleted[q.id], q.lastSaved <= delAt { continue }
            if let existing = byId[q.id] {
                if q.lastSaved > existing.lastSaved { byId[q.id] = q }
            } else {
                byId[q.id] = q
            }
        }

        let quizzes = byId.values.sorted { $0.lastSaved > $1.lastSaved }.prefix(10).map { $0 }
        return (Array(quizzes), deleted)
    }
}
