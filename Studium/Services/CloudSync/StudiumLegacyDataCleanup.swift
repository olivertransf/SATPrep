//
//  StudiumLegacyDataCleanup.swift
//  Studium
//

import Foundation

/// One-time removal of legacy iCloud KVS data and preference keys. Supabase is the sync source now.
enum StudiumLegacyDataCleanup {
    private static let migrationKey = "studium_legacy_icloud_cleanup_v2"

    private static let progressKey = "questionProgress"
    private static let deletedProgressKey = "deletedQuestionProgress"
    private static let savedQuizzesKey = "savedQuizStates"
    private static let deletedQuizzesKey = "deletedQuizStates"

    private static let legacyICloudKVSKeys = [
        "questionProgress",
        "deletedQuestionProgress",
        "savedQuizStates",
        "deletedQuizStates",
    ]

    private static let legacyPreferenceKeys = [
        "iCloudSyncEnabled",
        "quizICloudSyncEnabled",
        "hasSetICloudSyncPreference",
        "hasSetQuizICloudSyncPreference",
    ]

    static func runIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        UserDefaults.standard.set(true, forKey: migrationKey)

        for key in legacyPreferenceKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        let store = NSUbiquitousKeyValueStore.default
        for key in legacyICloudKVSKeys {
            store.removeObject(forKey: key)
        }
        store.synchronize()

        sanitizeCorruptLocalEntries()
    }

    private static func sanitizeCorruptLocalEntries() {
        if !decodesProgress(UserDefaults.standard.data(forKey: progressKey)) {
            UserDefaults.standard.removeObject(forKey: progressKey)
        }
        if !decodesDeletedDates(UserDefaults.standard.data(forKey: deletedProgressKey)) {
            UserDefaults.standard.removeObject(forKey: deletedProgressKey)
        }
        if !decodesQuizzes(UserDefaults.standard.data(forKey: savedQuizzesKey)) {
            UserDefaults.standard.removeObject(forKey: savedQuizzesKey)
        }
        if !decodesDeletedDates(UserDefaults.standard.data(forKey: deletedQuizzesKey)) {
            UserDefaults.standard.removeObject(forKey: deletedQuizzesKey)
        }
    }

    private static func decodesProgress(_ data: Data?) -> Bool {
        guard let data else { return true }
        return (try? JSONDecoder().decode([String: QuestionProgress].self, from: data)) != nil
    }

    private static func decodesDeletedDates(_ data: Data?) -> Bool {
        guard let data else { return true }
        if (try? JSONDecoder().decode([String: Date].self, from: data)) != nil { return true }
        return (try? JSONDecoder().decode([String: Double].self, from: data)) != nil
    }

    private static func decodesQuizzes(_ data: Data?) -> Bool {
        guard let data else { return true }
        return (try? JSONDecoder().decode([QuizState].self, from: data)) != nil
    }
}
