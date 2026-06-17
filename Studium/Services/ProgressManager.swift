//
//  ProgressManager.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation
import Combine

class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    @Published private(set) var progress: [String: QuestionProgress] = [:]
    
    private let userDefaultsKey = "questionProgress"
    private let deletedProgressKey = "deletedQuestionProgress"
    
    private var deletedProgressTimestamps: [String: Date] = [:]
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: deletedProgressKey) {
            if let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
                deletedProgressTimestamps = decoded
            } else if let ms = try? JSONDecoder().decode([String: Double].self, from: data) {
                deletedProgressTimestamps = ms.mapValues { Date(timeIntervalSince1970: $0 / 1000) }
            }
        }
        loadProgress()
    }
    
    // MARK: - Local Storage
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) {
            self.progress = decoded
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        if let encoded = try? JSONEncoder().encode(deletedProgressTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedProgressKey)
        }
        StudiumLocalDataNotify.changed()
    }

    // MARK: - Cloud sync

    func exportProgressForSync() -> [String: QuestionProgress] {
        progress
    }

    func exportDeletedProgressForSync() -> [String: Date] {
        deletedProgressTimestamps
    }

    func applyFromSync(progress: [String: QuestionProgress], deleted: [String: Date]) {
        self.progress = progress
        deletedProgressTimestamps = deleted
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        if let encoded = try? JSONEncoder().encode(deleted) {
            UserDefaults.standard.set(encoded, forKey: deletedProgressKey)
        }
    }
    
    // MARK: - Progress Operations
    
    func markSeen(questionId: String) {
        var currentProgress = progress[questionId] ?? QuestionProgress()
        currentProgress.seen = true
        currentProgress.lastAttempted = Date()
        progress[questionId] = currentProgress
        
        // Clear deletion timestamp if new progress is more recent
        if let deleteTime = deletedProgressTimestamps[questionId],
           let lastAttempted = currentProgress.lastAttempted,
           lastAttempted > deleteTime {
            deletedProgressTimestamps.removeValue(forKey: questionId)
        }
        
        saveProgress()
    }
    
    func markAnswered(questionId: String, correct: Bool) {
        var currentProgress = progress[questionId] ?? QuestionProgress()
        currentProgress.seen = true
        currentProgress.correct = correct
        currentProgress.lastAttempted = Date()
        progress[questionId] = currentProgress
        
        // Clear deletion timestamp if new progress is more recent
        if let deleteTime = deletedProgressTimestamps[questionId],
           let lastAttempted = currentProgress.lastAttempted,
           lastAttempted > deleteTime {
            deletedProgressTimestamps.removeValue(forKey: questionId)
        }
        
        saveProgress()
    }
    
    func isSeen(questionId: String) -> Bool {
        progress[questionId]?.seen ?? false
    }
    
    func isCorrect(questionId: String) -> Bool? {
        progress[questionId]?.correct
    }
    
    func getProgress(questionId: String) -> QuestionProgress? {
        progress[questionId]
    }
    
    // MARK: - Statistics
    
    func getOverallAccuracy() -> Double {
        let answered = progress.values.filter { $0.correct != nil }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.correct == true }.count
        return Double(correct) / Double(answered.count) * 100
    }
    
    func getTotalSeen() -> Int {
        progress.values.filter { $0.seen }.count
    }
    
    func getTotalAttempted() -> Int {
        progress.values.filter { $0.correct != nil }.count
    }
    
    func getAccuracy(byModule module: String, questionLoader: QuestionLoader) -> Double {
        accuracy(forQuestionIds: questionLoader.questionIdsByModule[module] ?? [])
    }
    
    func getAccuracy(byDifficulty difficulty: String, questionLoader: QuestionLoader) -> Double {
        accuracy(forQuestionIds: questionLoader.questionIdsByDifficulty[difficulty] ?? [])
    }
    
    func getAccuracy(byPrimaryClass primaryClass: String, questionLoader: QuestionLoader) -> Double {
        accuracy(forQuestionIds: questionLoader.questionIdsByPrimaryClass[primaryClass] ?? [])
    }
    
    func getAccuracy(bySkillDesc skillDesc: String, questionLoader: QuestionLoader) -> Double {
        accuracy(forQuestionIds: questionLoader.questionIdsBySkillDesc[skillDesc] ?? [])
    }

    /// Accuracy over the given question IDs (answered only), O(ids) not O(all progress).
    private func accuracy(forQuestionIds ids: Set<String>) -> Double {
        guard !ids.isEmpty else { return 0 }
        var answered = 0
        var correct = 0
        for id in ids {
            guard let c = progress[id]?.correct else { continue }
            answered += 1
            if c { correct += 1 }
        }
        guard answered > 0 else { return 0 }
        return Double(correct) / Double(answered) * 100
    }
    
    // MARK: - Reset Operations
    
    func resetAllProgress() {
        let deletedIds = Set(progress.keys)
        let now = Date()
        for questionId in deletedIds {
            deletedProgressTimestamps[questionId] = now
        }
        progress.removeAll()
        saveProgress()
    }
    
    func resetProgress(byProgram program: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byProgram: program)
        let questionIds = Set(questions.map { $0.questionId })
        let now = Date()
        for questionId in questionIds {
            if progress[questionId] != nil {
                deletedProgressTimestamps[questionId] = now
            }
        }
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byModule module: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byModule: module)
        let questionIds = Set(questions.map { $0.questionId })
        let now = Date()
        for questionId in questionIds {
            if progress[questionId] != nil {
                deletedProgressTimestamps[questionId] = now
            }
        }
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byPrimaryClass primaryClass: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byPrimaryClass: primaryClass)
        let questionIds = Set(questions.map { $0.questionId })
        let now = Date()
        for questionId in questionIds {
            if progress[questionId] != nil {
                deletedProgressTimestamps[questionId] = now
            }
        }
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(bySkillDesc skillDesc: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(bySkillDesc: skillDesc)
        let questionIds = Set(questions.map { $0.questionId })
        let now = Date()
        for questionId in questionIds {
            if progress[questionId] != nil {
                deletedProgressTimestamps[questionId] = now
            }
        }
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byDifficulty difficulty: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byDifficulty: difficulty)
        let questionIds = Set(questions.map { $0.questionId })
        let now = Date()
        for questionId in questionIds {
            if progress[questionId] != nil {
                deletedProgressTimestamps[questionId] = now
            }
        }
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
}

