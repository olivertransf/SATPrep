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
        case .known: "Mastered"
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

    private init() {
        wordBuckets = Self.loadMap(key: wordsKey)
        rootBuckets = Self.loadMap(key: rootsKey)
        wordTimestamps = Self.loadDates(key: wordTimestampsKey)
        rootTimestamps = Self.loadDates(key: rootTimestampsKey)
    }

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
    }

    func clearAll() {
        wordBuckets = [:]
        rootBuckets = [:]
        wordTimestamps = [:]
        rootTimestamps = [:]
        for key in [wordsKey, rootsKey, wordTimestampsKey, rootTimestampsKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        StudiumLocalDataNotify.changed()
    }

    // MARK: - Local Persistence

    private func persist(buckets: [String: String], timestamps: [String: Date], bucketsKey: String, timestampsKey: String) {
        if let data = try? JSONEncoder().encode(buckets) {
            UserDefaults.standard.set(data, forKey: bucketsKey)
        }
        if let data = try? JSONEncoder().encode(timestamps) {
            UserDefaults.standard.set(data, forKey: timestampsKey)
        }
        StudiumLocalDataNotify.changed()
    }

    func exportForSync() -> (
        words: [String: String],
        roots: [String: String],
        wordTimestamps: [String: Date],
        rootTimestamps: [String: Date]
    ) {
        (wordBuckets, rootBuckets, wordTimestamps, rootTimestamps)
    }

    func applyFromSync(
        words: [String: String],
        roots: [String: String],
        wordTimestamps: [String: Date],
        rootTimestamps: [String: Date]
    ) {
        wordBuckets = words
        rootBuckets = roots
        self.wordTimestamps = wordTimestamps
        self.rootTimestamps = rootTimestamps
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: wordsKey)
        }
        if let data = try? JSONEncoder().encode(wordTimestamps) {
            UserDefaults.standard.set(data, forKey: wordTimestampsKey)
        }
        if let data = try? JSONEncoder().encode(roots) {
            UserDefaults.standard.set(data, forKey: rootsKey)
        }
        if let data = try? JSONEncoder().encode(rootTimestamps) {
            UserDefaults.standard.set(data, forKey: rootTimestampsKey)
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
}
