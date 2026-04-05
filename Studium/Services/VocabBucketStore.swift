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

    @Published private(set) var wordBuckets: [String: String] = [:]
    @Published private(set) var rootBuckets: [String: String] = [:]

    private init() {
        wordBuckets = Self.loadMap(key: wordsKey)
        rootBuckets = Self.loadMap(key: rootsKey)
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
        Self.saveMap(m, key: wordsKey)
    }

    func setRootBucket(id: String, to bucket: VocabMemoryBucket) {
        var m = rootBuckets
        if bucket == .learn {
            m.removeValue(forKey: id)
        } else {
            m[id] = bucket.rawValue
        }
        rootBuckets = m
        Self.saveMap(m, key: rootsKey)
    }

    private static func loadMap(key: String) -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }

    private static func saveMap(_ map: [String: String], key: String) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
