//
//  VocabBucketStore.swift
//  Studium
//

import Combine
import Foundation

enum VocabMemoryBucket: String, CaseIterable, Identifiable, Codable {
    case learn
    case review
    case known

    var id: String { rawValue }

    var title: String {
        switch self {
        case .learn: "Learn now"
        case .review: "Review"
        case .known: "Known"
        }
    }

    var subtitle: String {
        switch self {
        case .learn: "New & active"
        case .review: "Circle back"
        case .known: "Solid"
        }
    }
}

@MainActor
final class VocabBucketStore: ObservableObject {
    static let shared = VocabBucketStore()

    private let wordsKey = "vocabMemory.wordBuckets"
    private let rootsKey = "vocabMemory.rootBuckets"
    private let wordTimestampsKey = "vocabMemory.wordTimestamps"
    private let rootTimestampsKey = "vocabMemory.rootTimestamps"

    @Published private(set) var wordBuckets: [String: String] = [:]
    @Published private(set) var rootBuckets: [String: String] = [:]

    private var wordTimestamps: [String: Date] = [:]
    private var rootTimestamps: [String: Date] = [:]

    private var iCloudStore: NSUbiquitousKeyValueStore?

    var isICloudSyncEnabled: Bool = false {
        didSet {
            if isICloudSyncEnabled {
                enableICloudSync()
            } else {
                disableICloudSync()
            }
        }
    }

    private init() {
        wordBuckets = Self.loadMap(key: wordsKey)
        rootBuckets = Self.loadMap(key: rootsKey)
        wordTimestamps = Self.loadDates(key: wordTimestampsKey)
        rootTimestamps = Self.loadDates(key: rootTimestampsKey)

        // Default to enabled on first launch; otherwise respect stored preference.
        let syncEnabled = UserDefaults.standard.object(forKey: "iCloudSyncEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        isICloudSyncEnabled = syncEnabled
        if syncEnabled {
            enableICloudSync()
        }
    }

    // MARK: - Public API

    func wordBucket(for id: String) -> VocabMemoryBucket {
        guard let raw = wordBuckets[id], let b = VocabMemoryBucket(rawValue: raw) else { return .learn }
        return b
    }

    func rootBucket(for id: String) -> VocabMemoryBucket {
        guard let raw = rootBuckets[id], let b = VocabMemoryBucket(rawValue: raw) else { return .learn }
        return b
    }

    func setWordBucket(id: String, to bucket: VocabMemoryBucket) {
        var m = wordBuckets
        if bucket == .learn {
            m.removeValue(forKey: id)
        } else {
            m[id] = bucket.rawValue
        }
        wordBuckets = m
        wordTimestamps[id] = Date()
        persist(buckets: m, timestamps: wordTimestamps, bucketsKey: wordsKey, timestampsKey: wordTimestampsKey)
        if isICloudSyncEnabled { syncToICloud() }
    }

    func setRootBucket(id: String, to bucket: VocabMemoryBucket) {
        var m = rootBuckets
        if bucket == .learn {
            m.removeValue(forKey: id)
        } else {
            m[id] = bucket.rawValue
        }
        rootBuckets = m
        rootTimestamps[id] = Date()
        persist(buckets: m, timestamps: rootTimestamps, bucketsKey: rootsKey, timestampsKey: rootTimestampsKey)
        if isICloudSyncEnabled { syncToICloud() }
    }

    func manualSync() {
        guard isICloudSyncEnabled else { return }
        if iCloudStore == nil { enableICloudSync() }
        guard let store = iCloudStore else { return }
        _ = store.synchronize()
        syncFromICloud()
        syncToICloud()
    }

    // MARK: - Local Persistence

    private func persist(buckets: [String: String], timestamps: [String: Date], bucketsKey: String, timestampsKey: String) {
        if let data = try? JSONEncoder().encode(buckets) {
            UserDefaults.standard.set(data, forKey: bucketsKey)
        }
        if let data = try? JSONEncoder().encode(timestamps) {
            UserDefaults.standard.set(data, forKey: timestampsKey)
        }
    }

    private static func loadMap(key: String) -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }

    private static func loadDates(key: String) -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let map = try? JSONDecoder().decode([String: Date].self, from: data)
        else { return [:] }
        return map
    }

    // MARK: - iCloud Sync

    private func enableICloudSync() {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            isICloudSyncEnabled = false
            return
        }
        iCloudStore = NSUbiquitousKeyValueStore.default
        iCloudStore?.synchronize()

        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.syncFromICloud()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.syncToICloud()
        }
    }

    private func disableICloudSync() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        iCloudStore = nil
    }

    @objc private func iCloudDidChange(notification: Notification) {
        let keys = (notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String])
        let shouldMerge: Bool
        if let keys {
            shouldMerge = keys.isEmpty
                || keys.contains(wordsKey)
                || keys.contains(rootsKey)
                || keys.contains(wordTimestampsKey)
                || keys.contains(rootTimestampsKey)
        } else {
            shouldMerge = true
        }
        guard shouldMerge else { return }
        DispatchQueue.main.async { [weak self] in
            self?.syncFromICloud()
        }
    }

    private func syncToICloud() {
        guard let store = iCloudStore else { return }
        guard FileManager.default.ubiquityIdentityToken != nil else {
            isICloudSyncEnabled = false
            return
        }
        if let data = try? JSONEncoder().encode(wordBuckets) { store.set(data, forKey: wordsKey) }
        if let data = try? JSONEncoder().encode(rootBuckets) { store.set(data, forKey: rootsKey) }
        if let data = try? JSONEncoder().encode(wordTimestamps) { store.set(data, forKey: wordTimestampsKey) }
        if let data = try? JSONEncoder().encode(rootTimestamps) { store.set(data, forKey: rootTimestampsKey) }
        _ = store.synchronize()
    }

    private func syncFromICloud() {
        guard let store = iCloudStore else { return }
        _ = store.synchronize()

        let iCloudWordBuckets = decode([String: String].self, from: store.data(forKey: wordsKey)) ?? [:]
        let iCloudWordTimestamps = decode([String: Date].self, from: store.data(forKey: wordTimestampsKey)) ?? [:]
        let iCloudRootBuckets = decode([String: String].self, from: store.data(forKey: rootsKey)) ?? [:]
        let iCloudRootTimestamps = decode([String: Date].self, from: store.data(forKey: rootTimestampsKey)) ?? [:]

        let (mergedWordBuckets, mergedWordTimestamps) = mergedLWW(
            localBuckets: wordBuckets, localTimestamps: wordTimestamps,
            remoteBuckets: iCloudWordBuckets, remoteTimestamps: iCloudWordTimestamps
        )
        let (mergedRootBuckets, mergedRootTimestamps) = mergedLWW(
            localBuckets: rootBuckets, localTimestamps: rootTimestamps,
            remoteBuckets: iCloudRootBuckets, remoteTimestamps: iCloudRootTimestamps
        )

        let wordChanged = mergedWordBuckets != wordBuckets || mergedWordTimestamps != wordTimestamps
        let rootChanged = mergedRootBuckets != rootBuckets || mergedRootTimestamps != rootTimestamps

        if wordChanged {
            wordBuckets = mergedWordBuckets
            wordTimestamps = mergedWordTimestamps
            persist(buckets: mergedWordBuckets, timestamps: mergedWordTimestamps, bucketsKey: wordsKey, timestampsKey: wordTimestampsKey)
        }
        if rootChanged {
            rootBuckets = mergedRootBuckets
            rootTimestamps = mergedRootTimestamps
            persist(buckets: mergedRootBuckets, timestamps: mergedRootTimestamps, bucketsKey: rootsKey, timestampsKey: rootTimestampsKey)
        }
        if wordChanged || rootChanged {
            syncToICloud()
        }
    }

    /// LWW merge per entry. An absent bucket key with a timestamp means "explicitly set to learn."
    private func mergedLWW(
        localBuckets: [String: String], localTimestamps: [String: Date],
        remoteBuckets: [String: String], remoteTimestamps: [String: Date]
    ) -> ([String: String], [String: Date]) {
        var buckets = localBuckets
        var timestamps = localTimestamps

        for (id, remoteTime) in remoteTimestamps {
            if let localTime = timestamps[id] {
                if remoteTime > localTime {
                    timestamps[id] = remoteTime
                    if let bucket = remoteBuckets[id] {
                        buckets[id] = bucket
                    } else {
                        buckets.removeValue(forKey: id)
                    }
                }
            } else {
                timestamps[id] = remoteTime
                if let bucket = remoteBuckets[id] {
                    buckets[id] = bucket
                } else {
                    buckets.removeValue(forKey: id)
                }
            }
        }

        return (buckets, timestamps)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
