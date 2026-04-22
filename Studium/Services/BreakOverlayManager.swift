//
//  BreakOverlayManager.swift
//  Studium
//

#if os(macOS)
import AppKit
import Combine
import SwiftUI

// MARK: - View model

/// Drives the overlay content. Kept alive for the lifetime of the app so the
/// underlying WKWebView is never deallocated — new questions are swapped in
/// by publishing state changes, which causes the web view to reload HTML
/// (via updateNSView) without any teardown.
final class BreakOverlayViewModel: ObservableObject {
    @Published var question: Question?
    @Published var selectedOptionId: String?
    @Published var submitted = false
    @Published var isCorrect = false

    func refresh() {
        selectedOptionId = nil
        submitted = false
        isCorrect = false
        question = QuestionLoader.shared.getMediumAndHardMCQuestions().randomElement()
    }

    func submit() {
        guard let selectedId = selectedOptionId, let q = question else { return }
        isCorrect = checkCorrectness(selectedId: selectedId, question: q)
        submitted = true
    }

    func resolvedCorrectOptionId() -> String? {
        guard let q = question else { return nil }
        let correctAnswers = q.content.displayCorrectAnswer
        let options = q.content.displayAnswerOptions
        for opt in options {
            if correctAnswers.contains(opt.id) { return opt.id }
            if let label = opt.label, correctAnswers.contains(label) { return opt.id }
        }
        return correctAnswers.first
    }

    private func checkCorrectness(selectedId: String, question: Question) -> Bool {
        let correctAnswers = question.content.displayCorrectAnswer
        if correctAnswers.contains(selectedId) { return true }
        let options = question.content.displayAnswerOptions
        if let opt = options.first(where: { $0.id == selectedId }),
           let label = opt.label {
            return correctAnswers.contains(label)
        }
        return false
    }
}

// MARK: - Manager

@MainActor
final class BreakOverlayManager {
    static let shared = BreakOverlayManager()

    private var overlayWindow: NSWindow?
    private let viewModel = BreakOverlayViewModel()
    private weak var breakMonitorRef: ScreenBreakMonitor?

    private init() {}

    func show(breakMonitor: ScreenBreakMonitor) {
        self.breakMonitorRef = breakMonitor

        if overlayWindow == nil {
            // First invocation: build the window + SwiftUI host once
            overlayWindow = buildWindow()
        }

        // Always refresh to a new question before showing
        viewModel.refresh()
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    /// Hides the overlay without releasing the window or its SwiftUI view tree.
    /// Nothing is deallocated — the WKWebView just stops being visible.
    func hide() {
        overlayWindow?.orderOut(nil)
    }

    // MARK: Private

    private func buildWindow() -> NSWindow {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.isReleasedWhenClosed = false

        let view = BreakOverlayView(
            viewModel: viewModel,
            onSubmitAndDismiss: { [weak self] in
                self?.breakMonitorRef?.recordBreak()
                self?.hide()
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )

        window.contentView = NSHostingView(rootView: view)
        return window
    }
}
#endif
