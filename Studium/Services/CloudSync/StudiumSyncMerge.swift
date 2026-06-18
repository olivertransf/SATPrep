//
//  StudiumSyncMerge.swift
//  Studium
//

import Foundation

@MainActor
enum StudiumSyncMerge {
  static func mergePayloads(local: StudiumSyncPayloadWire, remote: StudiumSyncPayloadWire) -> StudiumSyncPayloadWire {
    let progress = mergeProgress(
      local: local.progress,
      remote: remote.progress,
      deletedLocal: local.deletedProgress,
      deletedRemote: remote.deletedProgress
    )
    let quizzes = mergeQuizzes(
      local: local.savedQuizzes,
      remote: remote.savedQuizzes,
      deletedLocal: local.deletedQuizzes,
      deletedRemote: remote.deletedQuizzes
    )
    let vocab = mergeVocab(local: local.vocabBuckets, remote: remote.vocabBuckets)

    return StudiumSyncPayloadWire(
      progress: progress.progress,
      deletedProgress: progress.deletedProgress,
      savedQuizzes: quizzes.savedQuizzes,
      deletedQuizzes: quizzes.deletedQuizzes,
      vocabBuckets: vocab,
      clientUpdatedAt: max(local.clientUpdatedAt, remote.clientUpdatedAt, StudiumSyncWireCodec.ms(Date()))
    )
  }

  private static func progressTime(_ p: QuestionProgressWire?) -> Double {
    p?.lastAttempted ?? 0
  }

  private static func pickProgress(_ a: QuestionProgressWire, _ b: QuestionProgressWire) -> QuestionProgressWire {
    let at = progressTime(a)
    let bt = progressTime(b)
    if at > bt { return a }
    if bt > at { return b }
    if a.correct != nil, b.correct == nil { return a }
    if b.correct != nil, a.correct == nil { return b }
    return a
  }

  private static func mergeProgress(
    local: [String: QuestionProgressWire],
    remote: [String: QuestionProgressWire],
    deletedLocal: [String: Double],
    deletedRemote: [String: Double]
  ) -> (progress: [String: QuestionProgressWire], deletedProgress: [String: Double]) {
    var deletedProgress = deletedLocal
    for (id, t) in deletedRemote {
      deletedProgress[id] = max(deletedProgress[id] ?? 0, t)
    }

    var progress: [String: QuestionProgressWire] = [:]
    let ids = Set(local.keys).union(remote.keys)

    for id in ids {
      let lp = local[id]
      let rp = remote[id]
      let maxAttempt = max(progressTime(lp), progressTime(rp))
      let tomb = deletedProgress[id] ?? 0

      if tomb > 0, tomb >= maxAttempt { continue }

      let winner: QuestionProgressWire?
      if let lp, let rp {
        winner = pickProgress(lp, rp)
      } else {
        winner = lp ?? rp
      }
      guard let winner else { continue }

      progress[id] = winner
      if maxAttempt > tomb {
        deletedProgress.removeValue(forKey: id)
      }
    }

    return (progress, deletedProgress)
  }

  private static func mergeAnswerStates(
    _ a: [String: QuestionAnswerStateWire],
    _ b: [String: QuestionAnswerStateWire]
  ) -> [String: QuestionAnswerStateWire] {
    var out = a
    for (qid, remote) in b {
      guard let local = out[qid] else {
        out[qid] = remote
        continue
      }
      if remote.hasSubmitted, !local.hasSubmitted {
        out[qid] = remote
        continue
      }
      if local.hasSubmitted, remote.hasSubmitted {
        out[qid] = local.isCorrect != nil ? local : remote
      }
    }
    return out
  }

  private static func mergeTwoQuizzes(_ a: QuizStateWire, _ b: QuizStateWire) -> QuizStateWire {
    let winner = a.lastSaved >= b.lastSaved ? a : b
    let loser = a.lastSaved >= b.lastSaved ? b : a
    var merged = winner
    merged.answerStates = mergeAnswerStates(winner.answerStates, loser.answerStates)
    return merged
  }

  private static func mergeQuizzes(
    local: [QuizStateWire],
    remote: [QuizStateWire],
    deletedLocal: [String: Double],
    deletedRemote: [String: Double]
  ) -> (savedQuizzes: [QuizStateWire], deletedQuizzes: [String: Double]) {
    var deletedQuizzes = deletedLocal
    for (id, t) in deletedRemote {
      deletedQuizzes[id] = max(deletedQuizzes[id] ?? 0, t)
    }

    var byId: [String: QuizStateWire] = [:]
    for quiz in local + remote {
      let tomb = deletedQuizzes[quiz.id] ?? 0
      if tomb > quiz.lastSaved { continue }
      if let existing = byId[quiz.id] {
        byId[quiz.id] = mergeTwoQuizzes(existing, quiz)
      } else {
        byId[quiz.id] = quiz
      }
    }

    let savedQuizzes = byId.values
      .sorted { $0.lastSaved > $1.lastSaved }
      .prefix(10)
      .map { $0 }

    return (savedQuizzes, deletedQuizzes)
  }

  private static func mergeVocab(local: VocabBucketsWire, remote: VocabBucketsWire) -> VocabBucketsWire {
    func mergeMaps(
      localBuckets: [String: String],
      localTs: [String: Double],
      remoteBuckets: [String: String],
      remoteTs: [String: Double]
    ) -> (buckets: [String: String], timestamps: [String: Double]) {
      var buckets = localBuckets
      var timestamps = localTs
      for (id, remoteTime) in remoteTs {
        let localTime = timestamps[id] ?? 0
        guard remoteTime > localTime else { continue }
        timestamps[id] = remoteTime
        if let bucket = remoteBuckets[id] {
          buckets[id] = bucket
        } else {
          buckets.removeValue(forKey: id)
        }
      }
      return (buckets, timestamps)
    }

    let words = mergeMaps(
      localBuckets: local.words,
      localTs: local.wordTimestamps,
      remoteBuckets: remote.words,
      remoteTs: remote.wordTimestamps
    )
    let roots = mergeMaps(
      localBuckets: local.roots,
      localTs: local.rootTimestamps,
      remoteBuckets: remote.roots,
      remoteTs: remote.rootTimestamps
    )

    return VocabBucketsWire(
      words: words.buckets,
      roots: roots.buckets,
      wordTimestamps: words.timestamps,
      rootTimestamps: roots.timestamps
    )
  }
}
