//
//  ScreenBreakMonitor.swift
//  Studium
//

#if os(macOS)
import Foundation
import Combine
import AppKit

@MainActor
final class ScreenBreakMonitor: ObservableObject {
    static let defaultThresholdMinutes = 20
    static let thresholdKey = "breakThresholdMinutes"
    private static let lastBreakKey = "studium.screenBreak.lastBreakDate"

    /// User-configurable threshold. Reads live from UserDefaults so changing
    /// the setting takes effect on the next tick (≤ 1 min).
    var breakThresholdMinutes: Int {
        let v = UserDefaults.standard.integer(forKey: Self.thresholdKey)
        return v > 0 ? v : Self.defaultThresholdMinutes
    }

    @Published private(set) var minutesElapsed: Int = 0
    @Published private(set) var needsBreak: Bool = false

    private var lastBreakDate: Date
    private var timer: Timer?
    private var observers: [Any] = []

    init() {
        let stored = UserDefaults.standard.double(forKey: Self.lastBreakKey)
        lastBreakDate = stored > 0 ? Date(timeIntervalSince1970: stored) : Date()
        tick()
        startTimer()
        observeScreen()
    }

    func recordBreak() {
        lastBreakDate = Date()
        UserDefaults.standard.set(lastBreakDate.timeIntervalSince1970, forKey: Self.lastBreakKey)
        tick()
    }

    private func tick() {
        minutesElapsed = Int(Date().timeIntervalSince(lastBreakDate) / 60)
        needsBreak = minutesElapsed >= breakThresholdMinutes
    }

    private func startTimer() {
        let t = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func observeScreen() {
        let center = NSWorkspace.shared.notificationCenter
        let obs = center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.recordBreak() }
        }
        observers = [obs]
    }

    deinit {
        timer?.invalidate()
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
    }
}
#endif
