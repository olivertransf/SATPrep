//
//  StudiumCloudSyncService.swift
//  Studium
//

import Foundation
import Combine

@MainActor
final class StudiumCloudSyncService: ObservableObject {
    static let shared = StudiumCloudSyncService()

    @Published private(set) var isActive = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSyncedAt: Date?

    private let gateUnlockKey = "studium_sync_gate_unlocked"
    private let accessTokenKey = "studium_sync_access_token"
    private let refreshTokenKey = "studium_sync_refresh_token"

    private var pushTask: Task<Void, Never>?

    private init() {
        Task { await refreshActiveState() }
    }

    var isConfigured: Bool { StudiumSyncConfig.isConfigured }

    // MARK: - Auth

    func unlock(password: String) async -> Bool {
        guard isConfigured, let base = StudiumSyncConfig.supabaseURL, let key = StudiumSyncConfig.anonKey else {
            lastError = "Add StudiumSync.plist (copy from StudiumSync.plist.example)"
            return false
        }

        lastError = nil

        if let email = StudiumSyncConfig.syncEmail {
            do {
                let token = try await signIn(email: email, password: password, base: base, anonKey: key)
                UserDefaults.standard.set(token.access, forKey: accessTokenKey)
                UserDefaults.standard.set(token.refresh, forKey: refreshTokenKey)
                UserDefaults.standard.removeObject(forKey: gateUnlockKey)
                isActive = true
                _ = await pullAndMerge()
                return true
            } catch {
                lastError = error.localizedDescription
                return false
            }
        }

        guard let gate = StudiumSyncConfig.gatePassword else {
            lastError = "Set SYNC_EMAIL or SYNC_GATE_PASSWORD in StudiumSync.plist"
            return false
        }
        guard password == gate else {
            lastError = "Wrong password"
            return false
        }
        UserDefaults.standard.set(true, forKey: gateUnlockKey)
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isActive = true
        _ = await pullAndMerge()
        return true
    }

    func signOut() {
        pushTask?.cancel()
        UserDefaults.standard.removeObject(forKey: gateUnlockKey)
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isActive = false
        lastSyncedAt = nil
        lastError = nil
    }

    func syncIfNeeded() {
        guard isActive else { return }
        Task { _ = await pullAndMerge() }
    }

    func schedulePush(delaySeconds: Double = 2.5) {
        guard isActive else { return }
        pushTask?.cancel()
        pushTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            _ = await pushLocal()
        }
    }

    func flushPush() async {
        guard isActive else { return }
        pushTask?.cancel()
        pushTask = nil
        _ = await pushLocal()
    }

    @discardableResult
    func pullAndMerge() async -> Bool {
        guard isActive, isConfigured else { return false }
        guard let rowId = await syncRowId() else {
            lastError = "Not connected"
            return false
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let remote = try await fetchRow(id: rowId)
            let local = packLocal()

            if let remote {
                let merged = merge(local: local, remote: remote)
                applyLocal(merged)
                try await upsertRow(id: rowId, snapshot: merged)
            } else {
                try await upsertRow(id: rowId, snapshot: local)
            }

            lastSyncedAt = Date()
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func pushLocal() async -> Bool {
        guard isActive, isConfigured else { return false }
        guard let rowId = await syncRowId() else { return false }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await upsertRow(id: rowId, snapshot: packLocal())
            lastSyncedAt = Date()
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Local pack / apply

    private struct LocalSnapshot {
        var progress: [String: QuestionProgress]
        var deletedProgress: [String: Date]
        var savedQuizzes: [QuizState]
        var deletedQuizzes: [String: Date]
        var wordBuckets: [String: String]
        var rootBuckets: [String: String]
        var wordTimestamps: [String: Date]
        var rootTimestamps: [String: Date]
    }

    private func packLocal() -> LocalSnapshot {
        let pm = ProgressManager.shared
        let qm = QuizStateManager.shared
        let vocab = VocabBucketStore.shared
        return LocalSnapshot(
            progress: pm.exportProgress(),
            deletedProgress: pm.exportDeletedProgress(),
            savedQuizzes: qm.exportSavedQuizzes(),
            deletedQuizzes: qm.exportDeletedQuizzes(),
            wordBuckets: vocab.exportWordBuckets(),
            rootBuckets: vocab.exportRootBuckets(),
            wordTimestamps: vocab.exportWordTimestamps(),
            rootTimestamps: vocab.exportRootTimestamps()
        )
    }

    private func applyLocal(_ s: LocalSnapshot) {
        ProgressManager.shared.applyCloudSync(progress: s.progress, deleted: s.deletedProgress)
        QuizStateManager.shared.applyCloudSync(quizzes: s.savedQuizzes, deleted: s.deletedQuizzes)
        VocabBucketStore.shared.applyCloudSync(
            wordBuckets: s.wordBuckets,
            rootBuckets: s.rootBuckets,
            wordTimestamps: s.wordTimestamps,
            rootTimestamps: s.rootTimestamps
        )
    }

    private func merge(local: LocalSnapshot, remote: LocalSnapshot) -> LocalSnapshot {
        let (progress, deletedProgress) = StudiumSyncMerge.mergeProgress(
            local: local.progress,
            remote: remote.progress,
            localDeleted: local.deletedProgress,
            remoteDeleted: remote.deletedProgress
        )
        let (savedQuizzes, deletedQuizzes) = StudiumSyncMerge.mergeQuizzes(
            local: local.savedQuizzes,
            remote: remote.savedQuizzes,
            localDeleted: local.deletedQuizzes,
            remoteDeleted: remote.deletedQuizzes
        )
        let (wordBuckets, wordTimestamps) = VocabBucketStore.mergedLWW(
            localBuckets: local.wordBuckets,
            localTimestamps: local.wordTimestamps,
            remoteBuckets: remote.wordBuckets,
            remoteTimestamps: remote.wordTimestamps
        )
        let (rootBuckets, rootTimestamps) = VocabBucketStore.mergedLWW(
            localBuckets: local.rootBuckets,
            localTimestamps: local.rootTimestamps,
            remoteBuckets: remote.rootBuckets,
            remoteTimestamps: remote.rootTimestamps
        )
        return LocalSnapshot(
            progress: progress,
            deletedProgress: deletedProgress,
            savedQuizzes: savedQuizzes,
            deletedQuizzes: deletedQuizzes,
            wordBuckets: wordBuckets,
            rootBuckets: rootBuckets,
            wordTimestamps: wordTimestamps,
            rootTimestamps: rootTimestamps
        )
    }

    private func wireRow(id: String, from s: LocalSnapshot) -> StudiumSyncRowWire {
        StudiumSyncRowWire(
            id: id,
            progress: StudiumSyncWireCodec.wireProgress(from: s.progress),
            deleted_progress: StudiumSyncWireCodec.wireDeleted(from: s.deletedProgress),
            saved_quizzes: StudiumSyncWireCodec.wireQuizzes(from: s.savedQuizzes),
            deleted_quizzes: StudiumSyncWireCodec.wireDeleted(from: s.deletedQuizzes),
            vocab_buckets: WireVocabBuckets(
                words: s.wordBuckets,
                roots: s.rootBuckets,
                wordTimestamps: StudiumSyncWireCodec.wireDeleted(from: s.wordTimestamps),
                rootTimestamps: StudiumSyncWireCodec.wireDeleted(from: s.rootTimestamps)
            ),
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func localFromWire(_ row: StudiumSyncRowWire) -> LocalSnapshot {
        let vocab = row.vocab_buckets
        return LocalSnapshot(
            progress: StudiumSyncWireCodec.localProgress(from: row.progress),
            deletedProgress: StudiumSyncWireCodec.localDeleted(from: row.deleted_progress),
            savedQuizzes: StudiumSyncWireCodec.localQuizzes(from: row.saved_quizzes),
            deletedQuizzes: StudiumSyncWireCodec.localDeleted(from: row.deleted_quizzes),
            wordBuckets: Self.normalizeWireBuckets(vocab?.words ?? [:]),
            rootBuckets: vocab?.roots ?? [:],
            wordTimestamps: StudiumSyncWireCodec.localDeleted(from: vocab?.wordTimestamps ?? [:]),
            rootTimestamps: StudiumSyncWireCodec.localDeleted(from: vocab?.rootTimestamps ?? [:])
        )
    }

    // MARK: - HTTP

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
    }

    private func signIn(email: String, password: String, base: URL, anonKey: String) async throws -> (access: String, refresh: String?) {
        guard let url = URL(string: base.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/auth/v1/token?grant_type=password") else {
            throw NSError(domain: "StudiumCloudSync", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let (data, response) = try await URLSession.shared.data(for: request)
        try throwIfHTTPError(response, data: data)
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return (decoded.access_token, decoded.refresh_token)
    }

    private func fetchRow(id: String) async throws -> LocalSnapshot? {
        guard let base = StudiumSyncConfig.supabaseURL, let key = StudiumSyncConfig.anonKey else { return nil }
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/studium_sync"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(id)"),
            URLQueryItem(name: "select", value: "*"),
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        applyHeaders(&request, anonKey: key)
        let (data, response) = try await URLSession.shared.data(for: request)
        try throwIfHTTPError(response, data: data)
        if let rows = try? JSONDecoder().decode([StudiumSyncRowWire].self, from: data),
           let row = rows.first {
            return localFromWire(row)
        }
        return try parseRowLeniently(data: data)
    }

    private func parseRowLeniently(data: Data) throws -> LocalSnapshot? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let row = json.first else {
            return nil
        }

        var progress: [String: QuestionProgress] = [:]
        if let progressJSON = row["progress"] as? [String: Any] {
            let progressData = try JSONSerialization.data(withJSONObject: progressJSON)
            progress = (try? JSONDecoder().decode([String: QuestionProgress].self, from: progressData)) ?? [:]
        }

        var deletedProgress: [String: Date] = [:]
        if let deletedJSON = row["deleted_progress"] as? [String: Any] {
            let deletedData = try JSONSerialization.data(withJSONObject: deletedJSON)
            if let dates = try? JSONDecoder().decode([String: Date].self, from: deletedData) {
                deletedProgress = dates
            } else if let ms = try? JSONDecoder().decode([String: Double].self, from: deletedData) {
                deletedProgress = StudiumSyncWireCodec.localDeleted(from: ms)
            }
        }

        var savedQuizzes: [QuizState] = []
        if let quizzes = row["saved_quizzes"] as? [[String: Any]] {
            for quizJSON in quizzes {
                let quizData = try JSONSerialization.data(withJSONObject: quizJSON)
                if let quiz = try? JSONDecoder().decode(QuizState.self, from: quizData) {
                    savedQuizzes.append(quiz)
                }
            }
        }

        var deletedQuizzes: [String: Date] = [:]
        if let deletedJSON = row["deleted_quizzes"] as? [String: Any] {
            let deletedData = try JSONSerialization.data(withJSONObject: deletedJSON)
            if let dates = try? JSONDecoder().decode([String: Date].self, from: deletedData) {
                deletedQuizzes = dates
            } else if let ms = try? JSONDecoder().decode([String: Double].self, from: deletedData) {
                deletedQuizzes = StudiumSyncWireCodec.localDeleted(from: ms)
            }
        }

        let vocabJSON = row["vocab_buckets"] as? [String: Any]
        let vocabData = vocabJSON.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
        let vocab = vocabData.flatMap { try? JSONDecoder().decode(WireVocabBuckets.self, from: $0) }

        return LocalSnapshot(
            progress: progress,
            deletedProgress: deletedProgress,
            savedQuizzes: savedQuizzes,
            deletedQuizzes: deletedQuizzes,
            wordBuckets: Self.normalizeWireBuckets(vocab?.words ?? [:]),
            rootBuckets: vocab?.roots ?? [:],
            wordTimestamps: StudiumSyncWireCodec.localDeleted(from: vocab?.wordTimestamps ?? [:]),
            rootTimestamps: StudiumSyncWireCodec.localDeleted(from: vocab?.rootTimestamps ?? [:])
        )
    }

    private func upsertRow(id: String, snapshot: LocalSnapshot) async throws {
        guard let base = StudiumSyncConfig.supabaseURL, let key = StudiumSyncConfig.anonKey else { return }
        var request = URLRequest(url: base.appendingPathComponent("rest/v1/studium_sync"))
        request.httpMethod = "POST"
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        applyHeaders(&request, anonKey: key)
        request.httpBody = try JSONEncoder().encode(wireRow(id: id, from: snapshot))
        let (data, response) = try await URLSession.shared.data(for: request)
        try throwIfHTTPError(response, data: data)
    }

    private func applyHeaders(_ request: inout URLRequest, anonKey: String) {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: accessTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    /// Web uses `mastered`; native uses `known`.
    private static func normalizeWireBuckets(_ buckets: [String: String]) -> [String: String] {
        buckets.mapValues { value in
            value == "mastered" ? VocabMemoryBucket.known.rawValue : value
        }
    }

    private func throwIfHTTPError(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "StudiumCloudSync", code: 1, userInfo: [NSLocalizedDescriptionKey: body.isEmpty ? "Request failed" : body])
        }
    }

    private func refreshActiveState() async {
        if UserDefaults.standard.string(forKey: accessTokenKey) != nil {
            isActive = true
            return
        }
        if UserDefaults.standard.bool(forKey: gateUnlockKey), StudiumSyncConfig.gatePassword != nil {
            isActive = true
            return
        }
        isActive = false
    }

    private func syncRowId() async -> String? {
        if UserDefaults.standard.string(forKey: accessTokenKey) != nil {
            return await fetchAuthUserId()
        }
        if UserDefaults.standard.bool(forKey: gateUnlockKey) {
            return "default"
        }
        return nil
    }

    private func fetchAuthUserId() async -> String? {
        guard let base = StudiumSyncConfig.supabaseURL, let key = StudiumSyncConfig.anonKey else { return nil }
        var request = URLRequest(url: base.appendingPathComponent("auth/v1/user"))
        request.httpMethod = "GET"
        applyHeaders(&request, anonKey: key)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String
        else { return nil }
        return id
    }
}
