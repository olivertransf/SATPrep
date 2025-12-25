//
//  QuizState.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation
import Combine

// MARK: - Question Answer State
struct QuestionAnswerState: Codable {
    var questionId: String
    var selectedAnswerId: String?
    var hasSubmitted: Bool
    var isCorrect: Bool?
    
    init(questionId: String, selectedAnswerId: String? = nil, hasSubmitted: Bool = false, isCorrect: Bool? = nil) {
        self.questionId = questionId
        self.selectedAnswerId = selectedAnswerId
        self.hasSubmitted = hasSubmitted
        self.isCorrect = isCorrect
    }
}

// MARK: - Quiz State
struct QuizState: Codable, Identifiable {
    var id: String
    var filters: FilterOptions
    var currentIndex: Int
    var questionIds: [String] // Store question IDs to restore the exact quiz
    var answerStates: [String: QuestionAnswerState] // Store answer state for each question
    var lastSaved: Date
    
    init(
        id: String = UUID().uuidString,
        filters: FilterOptions = FilterOptions(),
        currentIndex: Int = 0,
        questionIds: [String] = [],
        answerStates: [String: QuestionAnswerState] = [:],
        lastSaved: Date = Date()
    ) {
        self.id = id
        self.filters = filters
        self.currentIndex = currentIndex
        self.questionIds = questionIds
        self.answerStates = answerStates
        self.lastSaved = lastSaved
    }
    
    var hasActiveQuiz: Bool {
        return !questionIds.isEmpty && currentIndex < questionIds.count
    }
    
    // Helper to get a description of filters for display
    func filterDescription() -> String {
        var parts: [String] = []
        if let program = filters.program {
            parts.append(program)
        }
        if let module = filters.module {
            parts.append(module.capitalized)
        }
        if let difficulty = filters.difficulty {
            let diffDesc = difficulty == "E" ? "Easy" : (difficulty == "M" ? "Medium" : (difficulty == "H" ? "Hard" : difficulty))
            parts.append(diffDesc)
        }
        if filters.answerStatus != .all {
            parts.append(filters.answerStatus.rawValue)
        }
        if let primaryClass = filters.primaryClassCdDesc {
            parts.append(primaryClass)
        }
        if let skill = filters.skillDesc {
            parts.append(skill)
        }
        return parts.isEmpty ? "All Questions" : parts.joined(separator: " • ")
    }
}

// MARK: - Quiz State Manager
class QuizStateManager: ObservableObject {
    static let shared = QuizStateManager()
    
    private let userDefaultsKey = "savedQuizStates"
    private let iCloudKey = "savedQuizStates"
    private let deletedQuizzesKey = "deletedQuizStates"
    private let iCloudDeletedKey = "deletedQuizStates"
    private var iCloudStore: NSUbiquitousKeyValueStore?
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var savedQuizzes: [QuizState] = []
    private var deletedQuizTimestamps: [String: Date] = [:] // Track when quizzes were deleted
    
    @Published var isICloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isICloudSyncEnabled, forKey: "quizICloudSyncEnabled")
            if isICloudSyncEnabled {
                enableICloudSync()
            } else {
                disableICloudSync()
            }
        }
    }
    
    private init() {
        // Use the same setting as ProgressManager for consistency
        let progressSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        self.isICloudSyncEnabled = UserDefaults.standard.bool(forKey: "quizICloudSyncEnabled")
        
        // If quiz sync hasn't been set yet, use progress sync setting
        if !UserDefaults.standard.bool(forKey: "hasSetQuizICloudSyncPreference") {
            self.isICloudSyncEnabled = progressSyncEnabled
            UserDefaults.standard.set(true, forKey: "hasSetQuizICloudSyncPreference")
        }
        
        // Load deleted quiz timestamps
        if let data = UserDefaults.standard.data(forKey: deletedQuizzesKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            deletedQuizTimestamps = decoded
        }
        
        loadAllQuizStates()
        
        // Enable iCloud sync if enabled
        if isICloudSyncEnabled {
            enableICloudSync()
        }
    }
    
    func loadAllQuizStates() {
        // Try to load from local first
        var localQuizzes: [QuizState] = []
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([QuizState].self, from: data) {
            localQuizzes = decoded.filter { !$0.questionIds.isEmpty }
        }
        
        // If iCloud sync is enabled, merge with iCloud data
        if isICloudSyncEnabled && iCloudStore != nil {
            syncFromICloud()
        } else {
            savedQuizzes = localQuizzes.sorted { $0.lastSaved > $1.lastSaved }
        }
    }
    
    func saveQuizState(_ state: QuizState) {
        // Only save if quiz has questions
        guard !state.questionIds.isEmpty else { return }
        
        var updatedState = state
        updatedState.lastSaved = Date()
        
        // Update or add the quiz state
        if let index = savedQuizzes.firstIndex(where: { $0.id == state.id }) {
            savedQuizzes[index] = updatedState
        } else {
            savedQuizzes.append(updatedState)
        }
        
        // Sort by most recent
        savedQuizzes.sort { $0.lastSaved > $1.lastSaved }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        
        // Sync to iCloud if enabled
        if isICloudSyncEnabled && iCloudStore != nil {
            DispatchQueue.main.async { [weak self] in
                self?.syncToICloud()
            }
        }
    }
    
    func loadQuizState(id: String) -> QuizState? {
        return savedQuizzes.first { $0.id == id }
    }
    
    func deleteQuizState(id: String) {
        savedQuizzes.removeAll { $0.id == id }
        
        // Track deletion timestamp
        deletedQuizTimestamps[id] = Date()
        
        // Save deleted timestamps
        if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
            UserDefaults.standard.set(encoded, forKey: deletedQuizzesKey)
        }
        
        // Save updated quiz list
        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        
        // Sync to iCloud if enabled
        if isICloudSyncEnabled && iCloudStore != nil {
            DispatchQueue.main.async { [weak self] in
                self?.syncToICloud()
            }
        }
    }
    
    func clearAllQuizStates() {
        savedQuizzes.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Sync to iCloud if enabled
        if isICloudSyncEnabled && iCloudStore != nil {
            DispatchQueue.main.async { [weak self] in
                self?.syncToICloud()
            }
        }
    }
    
    // Legacy support - get the most recent quiz
    func loadQuizState() -> QuizState? {
        return savedQuizzes.first
    }
    
    // Legacy support - clear (removes most recent)
    func clearQuizState() {
        if let first = savedQuizzes.first {
            deleteQuizState(id: first.id)
        }
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
        
        // Save quizzes
        if let encoded = try? JSONEncoder().encode(savedQuizzes) {
            store.set(encoded, forKey: iCloudKey)
        } else {
            print("Failed to encode quiz states for iCloud")
            return
        }
        
        // Save deleted timestamps
        if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
            store.set(encoded, forKey: iCloudDeletedKey)
        }
        
        let synced = store.synchronize()
        
        if synced {
            print("iCloud quiz sync successful")
        } else {
            // Don't print warning for simulator - iCloud may not be fully available
            #if !targetEnvironment(simulator)
            print("Warning: iCloud quiz sync failed - synchronize() returned false")
            #endif
        }
    }
    
    private func syncFromICloud() {
        guard let store = iCloudStore else {
            return
        }
        
        // Get iCloud quizzes
        var iCloudQuizzes: [QuizState] = []
        if let data = store.data(forKey: iCloudKey),
           let decoded = try? JSONDecoder().decode([QuizState].self, from: data) {
            iCloudQuizzes = decoded.filter { !$0.questionIds.isEmpty }
        }
        
        // Get iCloud deleted timestamps
        var iCloudDeletedTimestamps: [String: Date] = [:]
        if let data = store.data(forKey: iCloudDeletedKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            iCloudDeletedTimestamps = decoded
        }
        
        // If no iCloud data, push local data
        if iCloudQuizzes.isEmpty && iCloudDeletedTimestamps.isEmpty {
            syncToICloud()
            return
        }
        
        // Merge deleted timestamps - keep the most recent deletion
        var mergedDeletedTimestamps = deletedQuizTimestamps
        for (quizId, iCloudDeleteTime) in iCloudDeletedTimestamps {
            if let localDeleteTime = mergedDeletedTimestamps[quizId] {
                // Keep the more recent deletion
                if iCloudDeleteTime > localDeleteTime {
                    mergedDeletedTimestamps[quizId] = iCloudDeleteTime
                }
            } else {
                // Only in iCloud
                mergedDeletedTimestamps[quizId] = iCloudDeleteTime
            }
        }
        
        // Merge quizzes - respect deletions
        var hasChanges = false
        var mergedQuizzes: [QuizState] = []
        var processedIds = Set<String>()
        
        // Process iCloud quizzes - only add if not deleted (or deleted before last save)
        for iCloudQuiz in iCloudQuizzes {
            processedIds.insert(iCloudQuiz.id)
            
            // Check if this quiz was deleted
            let iCloudDeleteTime = iCloudDeletedTimestamps[iCloudQuiz.id]
            let localDeleteTime = deletedQuizTimestamps[iCloudQuiz.id]
            
            // If deleted on iCloud and deletion is after last save, skip it
            if let deleteTime = iCloudDeleteTime, deleteTime > iCloudQuiz.lastSaved {
                // Deleted on iCloud - respect deletion
                if localDeleteTime == nil || deleteTime > localDeleteTime! {
                    // iCloud deletion is more recent, remove from local if exists
                    if savedQuizzes.contains(where: { $0.id == iCloudQuiz.id }) {
                        hasChanges = true
                    }
                    continue
                }
            }
            
            // If deleted locally and deletion is after last save, skip it
            if let deleteTime = localDeleteTime, deleteTime > iCloudQuiz.lastSaved {
                // Deleted locally - keep deletion
                continue
            }
            
            // Quiz is valid - merge it
            if let localQuiz = savedQuizzes.first(where: { $0.id == iCloudQuiz.id }) {
                // Both exist - use the more recent one
                if iCloudQuiz.lastSaved > localQuiz.lastSaved {
                    mergedQuizzes.append(iCloudQuiz)
                    hasChanges = true
                } else {
                    mergedQuizzes.append(localQuiz)
                    hasChanges = true
                }
            } else {
                // Only in iCloud - add it
                mergedQuizzes.append(iCloudQuiz)
                hasChanges = true
            }
        }
        
        // Add local quizzes not in iCloud (if not deleted)
        for localQuiz in savedQuizzes {
            if !processedIds.contains(localQuiz.id) {
                // Check if locally deleted
                if let deleteTime = deletedQuizTimestamps[localQuiz.id],
                   deleteTime > localQuiz.lastSaved {
                    // Locally deleted - check if iCloud has a more recent version
                    if let iCloudDeleteTime = iCloudDeletedTimestamps[localQuiz.id],
                       iCloudDeleteTime < deleteTime {
                        // Local deletion is more recent, skip
                        continue
                    }
                }
                mergedQuizzes.append(localQuiz)
                hasChanges = true
            }
        }
        
        // Clean up old deletion timestamps (older than 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        mergedDeletedTimestamps = mergedDeletedTimestamps.filter { $0.value > thirtyDaysAgo }
        
        if hasChanges || mergedDeletedTimestamps != deletedQuizTimestamps {
            // Update saved quizzes
            savedQuizzes = mergedQuizzes.sorted { $0.lastSaved > $1.lastSaved }
            
            // Update deleted timestamps
            deletedQuizTimestamps = mergedDeletedTimestamps
            
            // Save locally
            if let encoded = try? JSONEncoder().encode(savedQuizzes) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            }
            if let encoded = try? JSONEncoder().encode(deletedQuizTimestamps) {
                UserDefaults.standard.set(encoded, forKey: deletedQuizzesKey)
            }
            
            // Push to iCloud
            syncToICloud()
        }
    }
}

