//
//  StudiumCloudSyncService.swift
//  Studium
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

enum StudiumSyncStatus: Equatable {
  case idle
  case syncing
  case synced
  case offline
  case error
}

@MainActor
final class StudiumCloudSyncService: ObservableObject {
  static let shared = StudiumCloudSyncService()

  @Published private(set) var status: StudiumSyncStatus = .idle
  @Published private(set) var lastSyncedAt: Date?
  @Published private(set) var errorMessage: String?

  private let debounceSeconds: TimeInterval = 2.5
  private let syncDocId = "data"

  private var activeUid: String?
  private var pushTask: Task<Void, Never>?
  private var pushInFlight = false
  private var pullInFlight = false
  private var applyingRemote = false

  private init() {}

  func setUser(uid: String?) {
    activeUid = uid
    if uid == nil {
      cancelScheduledPush()
      status = .idle
      errorMessage = nil
    }
  }

  func schedulePush() {
    guard !applyingRemote, resolvedUid() != nil else { return }
    pushTask?.cancel()
    pushTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(self?.debounceSeconds ?? 2.5))
      guard !Task.isCancelled else { return }
      await self?.flush()
    }
  }

  func cancelScheduledPush() {
    pushTask?.cancel()
    pushTask = nil
  }

  func pullAndMerge(uid: String) async {
    guard !pullInFlight else { return }
    pullInFlight = true
    defer { pullInFlight = false }

    activeUid = uid

    guard await isOnline() else {
      status = .offline
      return
    }

    status = .syncing
    errorMessage = nil

    do {
      let local = loadLocalPayload()
      let remote = try await pullRemote(uid: uid)
      let merged = remote.map { StudiumSyncMerge.mergePayloads(local: local, remote: $0) } ?? local
      applyPayload(merged)

      if merged.clientUpdatedAt > (remote?.clientUpdatedAt ?? 0) {
        try await pushPayload(uid: uid, payload: merged)
      }

      status = .synced
      lastSyncedAt = Date()
    } catch {
      status = .error
      errorMessage = Self.describe(error)
    }
  }

  func flush() async {
    guard let uid = resolvedUid(), !pushInFlight else {
      if resolvedUid() == nil {
        status = .error
        errorMessage = "Not signed in."
      }
      return
    }

    guard await isOnline() else {
      status = .offline
      return
    }

    pushInFlight = true
    defer { pushInFlight = false }

    status = .syncing
    errorMessage = nil

    do {
      let local = loadLocalPayload()
      let remote = try await pullRemote(uid: uid)
      let merged = remote.map { StudiumSyncMerge.mergePayloads(local: local, remote: $0) } ?? local
      applyPayload(merged)
      try await pushPayload(uid: uid, payload: merged)
      status = .synced
      lastSyncedAt = Date()
    } catch {
      status = .error
      errorMessage = Self.describe(error)
    }
  }

  // MARK: - Local payload

  func loadLocalPayload() -> StudiumSyncPayloadWire {
    let progress = ProgressManager.shared.exportProgressForSync()
    let deletedProgress = ProgressManager.shared.exportDeletedProgressForSync()
    let quizzes = QuizStateManager.shared.exportQuizzesForSync()
    let deletedQuizzes = QuizStateManager.shared.exportDeletedQuizzesForSync()
    let vocab = VocabBucketStore.shared.exportForSync()

    return StudiumSyncPayloadWire(
      progress: StudiumSyncWireCodec.progressToWire(progress),
      deletedProgress: StudiumSyncWireCodec.deletedToWire(deletedProgress),
      savedQuizzes: quizzes.map(StudiumSyncWireCodec.quizToWire),
      deletedQuizzes: StudiumSyncWireCodec.deletedToWire(deletedQuizzes),
      vocabBuckets: StudiumSyncWireCodec.vocabToWire(
        words: vocab.words,
        roots: vocab.roots,
        wordTimestamps: vocab.wordTimestamps,
        rootTimestamps: vocab.rootTimestamps
      ),
      clientUpdatedAt: StudiumSyncWireCodec.ms(Date())
    )
  }

  private func applyPayload(_ payload: StudiumSyncPayloadWire) {
    applyingRemote = true
    defer { applyingRemote = false }

    ProgressManager.shared.applyFromSync(
      progress: StudiumSyncWireCodec.progressFromWire(payload.progress),
      deleted: StudiumSyncWireCodec.deletedFromWire(payload.deletedProgress)
    )
    QuizStateManager.shared.applyFromSync(
      quizzes: payload.savedQuizzes.map(StudiumSyncWireCodec.quizFromWire),
      deleted: StudiumSyncWireCodec.deletedFromWire(payload.deletedQuizzes)
    )
    let vocab = StudiumSyncWireCodec.vocabFromWire(payload.vocabBuckets)
    VocabBucketStore.shared.applyFromSync(
      words: vocab.words,
      roots: vocab.roots,
      wordTimestamps: vocab.wordTimestamps,
      rootTimestamps: vocab.rootTimestamps
    )

    StudiumLocalDataNotify.changed(fromSync: true)
    StudiumLocalDataNotify.syncApplied()
  }

  // MARK: - Firestore

  private func resolvedUid() -> String? {
    if let activeUid { return activeUid }
    let current = Auth.auth().currentUser?.uid
    if let current { activeUid = current }
    return current
  }

  private func syncDocRef(uid: String) -> DocumentReference {
    Firestore.firestore()
      .collection("users")
      .document(uid)
      .collection("sync")
      .document(syncDocId)
  }

  private func pullRemote(uid: String) async throws -> StudiumSyncPayloadWire? {
    let snap = try await syncDocRef(uid: uid).getDocument()
    guard snap.exists else { return nil }
    return try StudiumSyncWireCodec.payload(from: snap.data() ?? [:])
  }

  private func pushPayload(uid: String, payload: StudiumSyncPayloadWire) async throws {
    var body = payload
    body.clientUpdatedAt = StudiumSyncWireCodec.ms(Date())
    let data = try StudiumSyncWireCodec.firestoreData(from: body)
    try await syncDocRef(uid: uid).setData(data)
  }

  private func isOnline() async -> Bool {
    true
  }

  private static func describe(_ error: Error) -> String {
    let ns = error as NSError
    if ns.domain == FirestoreErrorDomain {
      switch ns.code {
      case FirestoreErrorCode.permissionDenied.rawValue:
        return "Firestore permission denied. Publish firestore.rules for project odev-b10e2."
      case FirestoreErrorCode.unavailable.rawValue:
        return "Firestore is unavailable. Check your network connection."
      default:
        break
      }
    }
    return error.localizedDescription
  }
}
