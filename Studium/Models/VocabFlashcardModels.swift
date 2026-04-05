//
//  VocabFlashcardModels.swift
//  Studium
//

import Combine
import Foundation

struct VocabWordCard: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let definition: String
    /// JSON: noun | verb | adj | adverb | other
    let partOfSpeech: String?

    var posKey: String { partOfSpeech ?? "other" }
}

struct VocabRootCard: Identifiable, Codable, Hashable {
    let id: String
    let root: String
    let meaning: String
    let origin: String
    let examples: [String]
}

private struct VocabFlashcardFile: Codable {
    let words: [VocabWordCard]
    let roots: [VocabRootCard]
}

enum VocabFlashcardLoadError: Error {
    case fileNotFound
    case decodeFailed
}

@MainActor
final class VocabFlashcardStore: ObservableObject {
    static let shared = VocabFlashcardStore()

    @Published private(set) var words: [VocabWordCard] = []
    @Published private(set) var roots: [VocabRootCard] = []
    @Published private(set) var loadError: Error?

    private let resourceName = "sat-vocab-flashcards"

    private init() {
        load()
    }

    func load() {
        loadError = nil
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            loadError = VocabFlashcardLoadError.fileNotFound
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(VocabFlashcardFile.self, from: data)
            words = decoded.words
            roots = decoded.roots
        } catch {
            loadError = error
        }
    }
}
