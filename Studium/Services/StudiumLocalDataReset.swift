//
//  StudiumLocalDataReset.swift
//  Studium
//

import Foundation

extension Notification.Name {
    static let studiumLocalDataDidReset = Notification.Name("studiumLocalDataDidReset")
}

enum StudiumLocalDataReset {
    @MainActor
    static func resetAll() {
        ProgressManager.shared.resetAllProgress()
        QuizStateManager.shared.clearAllQuizStates()
        VocabBucketStore.shared.clearAll()
        NotificationCenter.default.post(name: .studiumLocalDataDidReset, object: nil)
    }
}
