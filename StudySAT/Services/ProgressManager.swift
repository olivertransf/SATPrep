//
//  ProgressManager.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation
import Combine

class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    @Published private(set) var progress: [String: QuestionProgress] = [:]
    
    private let userDefaultsKey = "questionProgress"
    private let iCloudKey = "questionProgress"
    private var iCloudStore: NSUbiquitousKeyValueStore?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isICloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isICloudSyncEnabled, forKey: "iCloudSyncEnabled")
            if isICloudSyncEnabled {
                enableICloudSync()
            } else {
                disableICloudSync()
            }
        }
    }
    
    private init() {
        self.isICloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        loadProgress()
        
        // Enable iCloud sync by default if not explicitly disabled
        if isICloudSyncEnabled {
            enableICloudSync()
        } else {
            // Check if this is first launch - enable iCloud sync by default
            if !UserDefaults.standard.bool(forKey: "hasSetICloudSyncPreference") {
                isICloudSyncEnabled = true
                UserDefaults.standard.set(true, forKey: "hasSetICloudSyncPreference")
                enableICloudSync()
            }
        }
    }
    
    // MARK: - Local Storage
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) {
            self.progress = decoded
        }
    }
    
    private func saveProgress() {
        // Save locally first
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        
        // Sync to iCloud if enabled
        if isICloudSyncEnabled && iCloudStore != nil {
            // Use async to avoid blocking
            DispatchQueue.main.async { [weak self] in
                self?.syncToICloud()
            }
        }
    }
    
    // MARK: - Progress Operations
    
    func markSeen(questionId: String) {
        var currentProgress = progress[questionId] ?? QuestionProgress()
        currentProgress.seen = true
        currentProgress.lastAttempted = Date()
        progress[questionId] = currentProgress
        saveProgress()
    }
    
    func markAnswered(questionId: String, correct: Bool) {
        var currentProgress = progress[questionId] ?? QuestionProgress()
        currentProgress.seen = true
        currentProgress.correct = correct
        currentProgress.lastAttempted = Date()
        progress[questionId] = currentProgress
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
        let moduleQuestions = questionLoader.getQuestions(byModule: module)
        let questionIds = Set(moduleQuestions.map { $0.questionId })
        let answered = progress.filter { questionIds.contains($0.key) && $0.value.correct != nil }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.value.correct == true }.count
        return Double(correct) / Double(answered.count) * 100
    }
    
    func getAccuracy(byDifficulty difficulty: String, questionLoader: QuestionLoader) -> Double {
        let difficultyQuestions = questionLoader.getQuestions(byDifficulty: difficulty)
        let questionIds = Set(difficultyQuestions.map { $0.questionId })
        let answered = progress.filter { questionIds.contains($0.key) && $0.value.correct != nil }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.value.correct == true }.count
        return Double(correct) / Double(answered.count) * 100
    }
    
    func getAccuracy(byPrimaryClass primaryClass: String, questionLoader: QuestionLoader) -> Double {
        let primaryClassQuestions = questionLoader.getQuestions(byPrimaryClass: primaryClass)
        let questionIds = Set(primaryClassQuestions.map { $0.questionId })
        let answered = progress.filter { questionIds.contains($0.key) && $0.value.correct != nil }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.value.correct == true }.count
        return Double(correct) / Double(answered.count) * 100
    }
    
    func getAccuracy(bySkillDesc skillDesc: String, questionLoader: QuestionLoader) -> Double {
        let skillDescQuestions = questionLoader.getQuestions(bySkillDesc: skillDesc)
        let questionIds = Set(skillDescQuestions.map { $0.questionId })
        let answered = progress.filter { questionIds.contains($0.key) && $0.value.correct != nil }
        guard !answered.isEmpty else { return 0 }
        let correct = answered.filter { $0.value.correct == true }.count
        return Double(correct) / Double(answered.count) * 100
    }
    
    // MARK: - Reset Operations
    
    func resetAllProgress() {
        progress.removeAll()
        saveProgress()
    }
    
    func resetProgress(byProgram program: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byProgram: program)
        let questionIds = Set(questions.map { $0.questionId })
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byModule module: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byModule: module)
        let questionIds = Set(questions.map { $0.questionId })
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byPrimaryClass primaryClass: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byPrimaryClass: primaryClass)
        let questionIds = Set(questions.map { $0.questionId })
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(bySkillDesc skillDesc: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(bySkillDesc: skillDesc)
        let questionIds = Set(questions.map { $0.questionId })
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    func resetProgress(byDifficulty difficulty: String, questionLoader: QuestionLoader) {
        let questions = questionLoader.getQuestions(byDifficulty: difficulty)
        let questionIds = Set(questions.map { $0.questionId })
        progress = progress.filter { !questionIds.contains($0.key) }
        saveProgress()
    }
    
    // MARK: - iCloud Sync
    
    func manualSync() {
        guard isICloudSyncEnabled else {
            print("iCloud sync is disabled")
            return
        }
        
        if iCloudStore == nil {
            enableICloudSync()
        } else {
            syncFromICloud()
            syncToICloud()
        }
    }
    
    private func enableICloudSync() {
        // Check if iCloud is available
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud not available - sync disabled")
            DispatchQueue.main.async { [weak self] in
                self?.isICloudSyncEnabled = false
            }
            return
        }
        
        iCloudStore = NSUbiquitousKeyValueStore.default
        
        // Set up notification observer first
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        
        // Sync from iCloud on enable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.syncFromICloud()
        }
        
        // Also push local data to iCloud
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.syncToICloud()
        }
    }
    
    private func disableICloudSync() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore = nil
    }
    
    @objc private func iCloudDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
              keys.contains(iCloudKey) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.syncFromICloud()
        }
    }
    
    private func syncToICloud() {
        guard let store = iCloudStore else {
            return
        }
        
        // Check if iCloud is still available
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud no longer available - disabling sync")
            DispatchQueue.main.async { [weak self] in
                self?.isICloudSyncEnabled = false
            }
            return
        }
        
        guard let encoded = try? JSONEncoder().encode(progress) else {
            print("Failed to encode progress for iCloud")
            return
        }
        
        store.set(encoded, forKey: iCloudKey)
        let synced = store.synchronize()
        
        if synced {
            print("iCloud sync successful")
        } else {
            // Don't print warning for simulator - iCloud may not be fully available
            #if !targetEnvironment(simulator)
            print("Warning: iCloud sync failed - synchronize() returned false")
            #endif
        }
    }
    
    private func syncFromICloud() {
        guard let store = iCloudStore else {
            return
        }
        
        // Try to get iCloud data
        guard let data = store.data(forKey: iCloudKey),
              let iCloudProgress = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) else {
            // No iCloud data yet - push local data to iCloud
            syncToICloud()
            return
        }
        
        // Merge: use most recent timestamp for conflicts
        var hasChanges = false
        var mergedProgress = progress
        
        // Process iCloud items
        for (questionId, iCloudProgressItem) in iCloudProgress {
            let localProgressItem = mergedProgress[questionId]
            
            if let local = localProgressItem, let localDate = local.lastAttempted, let iCloudDate = iCloudProgressItem.lastAttempted {
                // Use the more recent one
                if localDate > iCloudDate {
                    // Keep local - will push to iCloud
                    hasChanges = true
                } else {
                    // Use iCloud
                    mergedProgress[questionId] = iCloudProgressItem
                    hasChanges = true
                }
            } else if localProgressItem == nil {
                // No local, use iCloud
                mergedProgress[questionId] = iCloudProgressItem
                hasChanges = true
            }
        }
        
        // Check for local items not in iCloud
        for (questionId, localItem) in mergedProgress {
            if iCloudProgress[questionId] == nil {
                // Local item not in iCloud - will be pushed
                hasChanges = true
            }
        }
        
        if hasChanges {
            // Update progress
            progress = mergedProgress
            
            // Save locally
            if let encoded = try? JSONEncoder().encode(progress) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            }
            
            // Push to iCloud
            syncToICloud()
        }
    }
}

