//
//  MenuBarQuizView.swift
//  Studium
//

#if os(macOS)
import SwiftUI
import WebKit

// MARK: - Weak proxy to avoid WKWebView retain cycle

final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: MenuBarWebCoordinator?
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(controller, didReceive: message)
    }
}

// MARK: - Coordinator

final class MenuBarWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var onOptionSelected: ((String) -> Void)?
    var loadedHTML: String = ""

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            if message.name == "optionSelected", let id = message.body as? String {
                self.onOptionSelected?(id)
            }
        }
    }
}

// MARK: - WKWebView representable

struct MenuBarWebView: NSViewRepresentable {
    let html: String
    @Binding var selectedOptionId: String?
    var revealCorrectId: String?
    var revealSelectedId: String?

    func makeCoordinator() -> MenuBarWebCoordinator { MenuBarWebCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let ucc = WKUserContentController()
        let proxy = WeakScriptHandler()
        proxy.delegate = context.coordinator
        ucc.add(proxy, name: "optionSelected")

        let config = WKWebViewConfiguration()
        config.userContentController = ucc

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.layer?.backgroundColor = CGColor.clear

        context.coordinator.onOptionSelected = { id in
            selectedOptionId = id
        }

        webView.loadHTMLString(html, baseURL: StudiumHTMLBuilder.contentBaseURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedHTML != html {
            context.coordinator.loadedHTML = html
            webView.loadHTMLString(html, baseURL: StudiumHTMLBuilder.contentBaseURL)
            return
        }
        guard let correctId = revealCorrectId, let selectedId = revealSelectedId else { return }
        let safeCorrect = correctId.replacingOccurrences(of: "'", with: "\\'")
        let safeSelected = selectedId.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("showResult('\(safeCorrect)', '\(safeSelected)');", completionHandler: nil)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: MenuBarWebCoordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "optionSelected")
    }
}

// MARK: - Main menu bar quiz view

// MARK: - Blank marker normalisation

/// SAT question data encodes fill-in blanks as the literal word "blank" (sometimes
/// wrapped in <span class="sr-only">) placed immediately after an underline element.
/// Substitute them with a visible underline so they render correctly.
private func normaliseBlankMarkers(_ html: String) -> String {
    html
        // sr-only span that reads "blank" — just strip it; the underline already shows
        .replacingOccurrences(of: "<span class=\"sr-only\">blank</span>", with: "", options: .caseInsensitive)
        // bare >blank< inside an HTML element
        .replacingOccurrences(of: ">blank<", with: ">______<", options: .caseInsensitive)
        // word "blank" surrounded by whitespace / punctuation
        .replacingOccurrences(of: " blank ", with: " ______ ", options: .caseInsensitive)
        .replacingOccurrences(of: " blank.", with: " ______.", options: .caseInsensitive)
        .replacingOccurrences(of: " blank,", with: " ______,", options: .caseInsensitive)
        .replacingOccurrences(of: " blank:", with: " ______:", options: .caseInsensitive)
        .replacingOccurrences(of: " blank;", with: " ______;", options: .caseInsensitive)
        .replacingOccurrences(of: "(blank)", with: "(______)", options: .caseInsensitive)
}

// MARK: - Shared HTML builder (used by MenuBarQuizView and BreakOverlayView)

func buildQuestionHTML(for q: Question, fontSize: Double) -> String {
    let stem = normaliseBlankMarkers(q.content.displayStem ?? "")
    let options = q.content.displayAnswerOptions
    let stimulusHTML: String = {
        guard let s = q.content.displayStimulus, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return "<div class=\"stimulus\">\(normaliseBlankMarkers(s))</div>"
    }()
    let rationaleHTML: String = {
        guard let r = q.content.displayRationale, !r.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return "<div class=\"rationale\" id=\"rationale\">\(r)</div>"
    }()
    let optionsHTML = options.map { opt in
        let safeId = opt.id.replacingOccurrences(of: "\"", with: "&quot;")
                          .replacingOccurrences(of: "'", with: "\\'")
        let label = opt.label ?? ""
        let content = normaliseBlankMarkers(opt.content)
        return """
        <div class="option" data-id="\(safeId)" onclick="selectOption('\(safeId)')">
          <span class="label">\(label)</span>
          <span class="content">\(content)</span>
        </div>
        """
    }.joined(separator: "\n")
    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <script>
      window.MathJax = {
        tex: { inlineMath: [['$','$'],['\\\\(','\\\\)']], displayMath: [['$$','$$'],['\\\\[','\\\\]']] },
        options: { skipHtmlTags: ['script','noscript','style','textarea'] }
      };
    </script>
    <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js" async></script>
    <style>
      :root { color-scheme: light dark; }
      * { box-sizing: border-box; }
      body {
        font-family: -apple-system, system-ui;
        font-size: \(fontSize)px;
        line-height: 1.6;
        margin: 0;
        padding: 16px 20px 12px;
        background: transparent;
        color: -apple-system-label;
      }
      .stimulus {
        border-radius: 8px;
        padding: 10px 12px;
        margin-bottom: 12px;
        font-size: \(fontSize - 1)px;
        line-height: 1.6;
        border: 1px solid rgba(128,128,128,0.25);
      }
      .stem { margin-bottom: 12px; }
      .options { display: flex; flex-direction: column; gap: 5px; }
      .option {
        display: flex;
        gap: 10px;
        align-items: flex-start;
        padding: 8px 10px;
        border-radius: 7px;
        border: 1px solid rgba(128,128,128,0.3);
        cursor: pointer;
        transition: border-color 0.12s, background 0.12s;
        user-select: none;
      }
      .option:hover { border-color: #007AFF; background: rgba(0,122,255,0.06); }
      .option.selected { border-color: #007AFF; background: rgba(0,122,255,0.10); }
      .option.correct { background: rgba(52,199,89,0.15) !important; border-color: #34C759 !important; }
      .option.wrong   { background: rgba(255,59,48,0.12)  !important; border-color: #FF3B30 !important; }
      .label { font-weight: 700; color: #007AFF; min-width: 14px; flex-shrink: 0; margin-top: 1px; }
      .option.correct .label { color: #34C759; }
      .option.wrong   .label { color: #FF3B30; }
      .content { flex: 1; }
      .rationale {
        display: none;
        margin-top: 14px;
        padding: 10px 12px;
        border-radius: 8px;
        border-left: 3px solid #007AFF;
        background: rgba(0,122,255,0.07);
        font-size: \(fontSize - 2)px;
        line-height: 1.6;
      }
      .rationale.visible { display: block; }
    </style>
    </head>
    <body>
    \(stimulusHTML)
    <div class="stem">\(stem)</div>
    <div class="options">
    \(optionsHTML)
    </div>
    \(rationaleHTML)
    <script>
    var currentSelected = null;
    var locked = false;
    function selectOption(id) {
      if (locked) return;
      currentSelected = id;
      document.querySelectorAll('.option').forEach(function(el) {
        el.classList.toggle('selected', el.dataset.id === id);
      });
      window.webkit.messageHandlers.optionSelected.postMessage(id);
    }
    function showResult(correctId, selectedId) {
      locked = true;
      document.querySelectorAll('.option').forEach(function(el) {
        var eid = el.dataset.id;
        el.classList.remove('selected', 'correct', 'wrong');
        if (eid === correctId) { el.classList.add('correct'); }
        else if (eid === selectedId && eid !== correctId) { el.classList.add('wrong'); }
        el.onclick = null;
      });
      var r = document.getElementById('rationale');
      if (r) { r.classList.add('visible'); }
    }
    </script>
    </body>
    </html>
    """
}

// MARK: - Main menu bar quiz view

struct MenuBarQuizView: View {
    @EnvironmentObject var breakMonitor: ScreenBreakMonitor
    @AppStorage("menuBarFontSize") private var menuBarFontSize: Double = 14.0
    @Environment(\.openWindow) private var openWindow

    @State private var question: Question?
    @State private var selectedOptionId: String?
    @State private var submitted = false
    @State private var isCorrect = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            if let q = question {
                MenuBarWebView(
                    html: buildHTML(for: q),
                    selectedOptionId: $selectedOptionId,
                    revealCorrectId: submitted ? resolvedCorrectOptionId(for: q) : nil,
                    revealSelectedId: submitted ? selectedOptionId : nil
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                footerBar(for: q)
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading questions…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 620, height: 780)
        .background(Color.systemGroupedBackground)
        .onAppear { loadQuestion() }
        .onReceive(QuestionLoader.shared.$isLoading) { loading in
            if !loading && question == nil { pickQuestion() }
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(breakMonitor.needsBreak ? Color.red : Color.green)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("New question") { loadQuestion() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
            Button("Open") {
                NSApp.setActivationPolicy(.regular)
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .help("Quit Studium")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statusText: String {
        if breakMonitor.needsBreak {
            return "Screen time: \(breakMonitor.minutesElapsed)m — answer to unlock"
        }
        let remaining = breakMonitor.breakThresholdMinutes - breakMonitor.minutesElapsed
        return "\(breakMonitor.minutesElapsed)m screen time · \(remaining)m until break"
    }

    // MARK: Footer

    @ViewBuilder
    private func footerBar(for q: Question) -> some View {
        Divider()
        if submitted {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
                Text(isCorrect ? "Correct! Timer reset." : "Answered — timer reset.")
                    .font(.callout)
                Spacer()
                Button("New question") { loadQuestion() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        } else {
            HStack {
                Spacer()
                Button("Submit") { submitAnswer(for: q) }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedOptionId == nil)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: Logic

    private func loadQuestion() {
        question = nil
        selectedOptionId = nil
        submitted = false
        isCorrect = false
        if !QuestionLoader.shared.isLoading { pickQuestion() }
    }

    private func pickQuestion() {
        question = QuestionLoader.shared.getMediumAndHardMCQuestions().randomElement()
    }

    private func submitAnswer(for q: Question) {
        guard let selectedId = selectedOptionId else { return }
        isCorrect = checkCorrectness(selectedId: selectedId, question: q)
        submitted = true
        breakMonitor.recordBreak()
    }

    private func resolvedCorrectOptionId(for q: Question) -> String? {
        let correctAnswers = q.content.displayCorrectAnswer
        let options = q.content.displayAnswerOptions
        // correctAnswer may be an option ID or a label like "A"
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

    // MARK: HTML builder

    private func buildHTML(for q: Question) -> String {
        buildQuestionHTML(for: q, fontSize: menuBarFontSize)
    }
}
#endif
