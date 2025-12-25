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
    private let deletedProgressKey = "deletedQuestionProgress"
    private let iCloudDeletedKey = "deletedQuestionProgress"
    private var iCloudStore: NSUbiquitousKeyValueStore?
    private var cancellables = Set<AnyCancellable>()
    
    private var deletedProgressTimestamps: [String: Date] = [:] // Track when progress was deleted
    
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
        
        // Load deleted progress timestamps
        if let data = UserDefaults.standard.data(forKey: deletedProgressKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            deletedProgressTimestamps = decoded
        }
        
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
        
        // Save deleted timestamps
        if let encoded = try? JSONEncoder().encode(deletedProgressTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedProgressKey)
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
        
        // Save progress
        if let encoded = try? JSONEncoder().encode(progress) {
            store.set(encoded, forKey: iCloudKey)
        } else {
            print("Failed to encode progress for iCloud")
            return
        }
        
        // Save deleted timestamps
        if let encoded = try? JSONEncoder().encode(deletedProgressTimestamps) {
            store.set(encoded, forKey: iCloudDeletedKey)
        }
        
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
        
        // Get iCloud progress
        var iCloudProgress: [String: QuestionProgress] = [:]
        if let data = store.data(forKey: iCloudKey),
           let decoded = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) {
            iCloudProgress = decoded
        }
        
        // Get iCloud deleted timestamps
        var iCloudDeletedTimestamps: [String: Date] = [:]
        if let data = store.data(forKey: iCloudDeletedKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            iCloudDeletedTimestamps = decoded
        }
        
        // If no iCloud data, push local data
        if iCloudProgress.isEmpty && iCloudDeletedTimestamps.isEmpty {
            syncToICloud()
            return
        }
        
        // Merge deleted timestamps - keep the most recent deletion
        var mergedDeletedTimestamps = deletedProgressTimestamps
        for (questionId, iCloudDeleteTime) in iCloudDeletedTimestamps {
            if let localDeleteTime = mergedDeletedTimestamps[questionId] {
                // Keep the more recent deletion
                if iCloudDeleteTime > localDeleteTime {
                    mergedDeletedTimestamps[questionId] = iCloudDeleteTime
                }
            } else {
                // Only in iCloud
                mergedDeletedTimestamps[questionId] = iCloudDeleteTime
            }
        }
        
        // Merge progress - respect deletions
        var hasChanges = false
        var mergedProgress = progress
        
        // Process iCloud items - only add if not deleted (or deleted before last attempt)
        for (questionId, iCloudProgressItem) in iCloudProgress {
            // Check if this progress was deleted
            let iCloudDeleteTime = iCloudDeletedTimestamps[questionId]
            let localDeleteTime = mergedDeletedTimestamps[questionId]
            
            // If deleted and deletion is after last attempt, skip it
            if let deleteTime = iCloudDeleteTime ?? localDeleteTime,
               let lastAttempted = iCloudProgressItem.lastAttempted,
               deleteTime > lastAttempted {
                // Deleted - respect deletion
                if mergedProgress[questionId] != nil {
                    mergedProgress.removeValue(forKey: questionId)
                    hasChanges = true
                }
                continue
            }
            
            // If progress exists and is newer than deletion, clear deletion timestamp
            if let lastAttempted = iCloudProgressItem.lastAttempted {
                if let deleteTime = mergedDeletedTimestamps[questionId],
                   lastAttempted > deleteTime {
                    mergedDeletedTimestamps.removeValue(forKey: questionId)
                    hasChanges = true
                }
            }
            
            // Progress is valid - merge it
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
        
        // Check for local items not in iCloud (if not deleted)
        for (questionId, localItem) in mergedProgress {
            if iCloudProgress[questionId] == nil {
                // Check if deleted
                if let deleteTime = mergedDeletedTimestamps[questionId],
                   let lastAttempted = localItem.lastAttempted,
                   deleteTime > lastAttempted {
                    // Deleted - remove it
                    mergedProgress.removeValue(forKey: questionId)
                    hasChanges = true
                    continue
                }
                
                // If progress exists and is newer than deletion, clear deletion timestamp
                if let lastAttempted = localItem.lastAttempted {
                    if let deleteTime = mergedDeletedTimestamps[questionId],
                       lastAttempted > deleteTime {
                        mergedDeletedTimestamps.removeValue(forKey: questionId)
                        hasChanges = true
                    }
                }
                
                // Local item not in iCloud - will be pushed
                hasChanges = true
            }
        }
        
        // Clean up old deletion timestamps (older than 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        mergedDeletedTimestamps = mergedDeletedTimestamps.filter { $0.value > thirtyDaysAgo }
        
        if hasChanges || mergedDeletedTimestamps != deletedProgressTimestamps {
            // Update progress
            progress = mergedProgress
            
            // Update deleted timestamps
            deletedProgressTimestamps = mergedDeletedTimestamps
            
            // Save locally
            if let encoded = try? JSONEncoder().encode(progress) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            }
            if let encoded = try? JSONEncoder().encode(deletedProgressTimestamps) {
                UserDefaults.standard.set(encoded, forKey: deletedProgressKey)
            }
            
            // Push to iCloud
            syncToICloud()
        }
    }
}

