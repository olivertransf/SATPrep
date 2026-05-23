//
//  HTMLContentView.swift
//  Studium
//
//  Renders HTML/LaTeX content via WKWebView with MathJax support.
//  Supports iOS (UIViewRepresentable) and macOS (NSViewRepresentable).
//

import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif

// MARK: - Weak message-handler proxy

/// WKUserContentController retains message handlers strongly, so we pass this
/// proxy instead — it holds only a weak reference back to the coordinator.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: (NSObject & WKScriptMessageHandler)?

    init(_ delegate: NSObject & WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

extension Notification.Name {
    static let studiumClearQuizHighlights = Notification.Name("studiumClearQuizHighlights")
}

private enum StudiumHighlightScripts {
    static let clearAll = """
    (function() {
        document.querySelectorAll('mark.studium-highlight').forEach(function(mark) {
            var parent = mark.parentNode;
            if (!parent) return;
            while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
            parent.removeChild(mark);
            parent.normalize();
        });
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
            window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
        }
    })();
    """
}

// MARK: - Coordinator (shared by iOS + macOS)

final class HTMLCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var contentHeight: Binding<CGFloat?>
    /// Last HTML string loaded — prevents the infinite re-render loop where
    /// updating contentHeight triggers updateUIView/updateNSView → loadHTMLString
    /// → JS height callback → contentHeight update → updateUIView/updateNSView…
    var lastLoadedHTML: String = ""
    weak var webView: WKWebView?
    var highlightModeActive = false
    private var clearHighlightsObserver: NSObjectProtocol?

    init(contentHeight: Binding<CGFloat?>) {
        self.contentHeight = contentHeight
        super.init()
        clearHighlightsObserver = NotificationCenter.default.addObserver(
            forName: .studiumClearQuizHighlights,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearHighlights()
        }
    }

    deinit {
        if let clearHighlightsObserver {
            NotificationCenter.default.removeObserver(clearHighlightsObserver)
        }
    }

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func syncHighlightMode(active: Bool) {
        highlightModeActive = active
        let flag = active ? "true" : "false"
        webView?.evaluateJavaScript(
            "window.studiumHighlightActive = \(flag);"
                + "if (document.body) document.body.classList.toggle('studium-highlight-mode', \(flag));"
        )
    }

    func clearHighlights() {
        webView?.evaluateJavaScript(StudiumHighlightScripts.clearAll) { [weak self] _, _ in
            self?.webView?.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let num = result as? NSNumber {
                    self?.applyHeight(CGFloat(num.doubleValue))
                }
            }
        }
    }

    // MARK: Height

    /// Called by MathJax startup.ready → promise.then after typesetting.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "heightUpdate" else { return }
        if let num = message.body as? NSNumber {
            applyHeight(CGFloat(num.doubleValue))
        }
    }

    func applyHeight(_ height: CGFloat) {
        guard height.isFinite && height > 0 && height < 10000 else { return }
        DispatchQueue.main.async {
            self.contentHeight.wrappedValue = height
        }
    }

    // MARK: Navigation

    /// Block link navigation so the webview stays on the rendered content.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
    }

    /// Fallback height polling for content that does not trigger MathJax.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        func poll(attempt: Int = 0) {
            let delay: Double = [0.3, 0.8, 1.5][min(attempt, 2)]
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                    let h = (result as? NSNumber).map { CGFloat($0.doubleValue) }
                            ?? (result as? CGFloat)
                    if let h, h.isFinite && h > 0 && h < 10000 {
                        DispatchQueue.main.async { self.contentHeight.wrappedValue = h }
                    } else if attempt < 2 {
                        poll(attempt: attempt + 1)
                    }
                }
            }
        }
        poll()
        syncHighlightMode(active: highlightModeActive)
    }
}

// MARK: - WKWebView factory (shared)

private func makeWebView(coordinator: HTMLCoordinator) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.userContentController.add(WeakScriptMessageHandler(coordinator), name: "heightUpdate")
    #if os(iOS) || os(visionOS)
    config.allowsInlineMediaPlayback = true
    let pagePrefs = WKWebpagePreferences()
    pagePrefs.preferredContentMode = .recommended
    config.defaultWebpagePreferences = pagePrefs
    #elseif os(macOS)
    // Sandboxed macOS: ensure auxiliary processes can load pages (matches default web behavior).
    let pagePrefs = WKWebpagePreferences()
    pagePrefs.allowsContentJavaScript = true
    config.defaultWebpagePreferences = pagePrefs
    #endif

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = coordinator

    #if os(iOS) || os(visionOS)
    webView.isOpaque = false
    webView.backgroundColor = .clear
    webView.scrollView.backgroundColor = .clear
    // Scrolling is controlled per-instance in updateUIView; start disabled.
    webView.scrollView.isScrollEnabled = false
    webView.scrollView.bounces = false
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.scrollView.showsHorizontalScrollIndicator = false
    webView.isUserInteractionEnabled = true
    #elseif os(macOS)
    // Avoid an opaque AppKit backing layer painting over document content (blank webview).
    webView.setValue(false, forKey: "drawsBackground")
    #endif

    return webView
}

// MARK: - Load helper

/// Load HTML only when the content actually changed.
/// Calling loadHTMLString on every SwiftUI update would reset the webview on
/// every contentHeight update, creating an infinite reload loop.
///
/// NOTE: do NOT mutate contentHeight here — this function is called from
/// updateUIView/updateNSView (i.e. during a SwiftUI view-update pass) and any
/// synchronous @State/@Binding write during that pass causes "undefined
/// behavior", which in practice causes SwiftUI to tear down and recreate the
/// WKWebView, leaving content permanently blank.
/// Base URL for `loadHTMLString` so subresources (e.g. MathJax CDN) resolve consistently on macOS.
private let htmlContentBaseURL = StudiumHTMLBuilder.contentBaseURL

/// Layout + typography intent for HTML blocks (passages vs question media).
enum HTMLContentProfile: String {
    case standard = "studium-profile-standard"
    case passage = "studium-profile-passage"
    case quizFigures = "studium-profile-quizfig"
}

private func loadIfNeeded(_ html: String, into webView: WKWebView, coordinator: HTMLCoordinator) {
    guard html != coordinator.lastLoadedHTML else { return }
    coordinator.lastLoadedHTML = html
    webView.loadHTMLString(html, baseURL: htmlContentBaseURL)
}

// MARK: - HTML builder

func buildHTMLString(
    _ content: String,
    colorScheme: ColorScheme,
    fontSize: CGFloat = 16,
    compact: Bool = false,
    profile: HTMLContentProfile = .standard
) -> String {
    let isDark = colorScheme == .dark
    // Match studium-web `index.css` / `buildHtml` surfaces.
    let bg          = isDark ? "#111111" : "#FFFFFF"
    let fg          = isDark ? "#F5F5F7" : "#0A0A0A"
    let border      = isDark ? "#242424" : "#E6E6E6"
    let headerBg    = isDark ? "#171717" : "#F0F3F9"
    let rowAlt      = isDark ? "#171717" : "#F6F8FC"
    let bodyClass   = isDark ? "studysat-dark" : "studysat-light"
    let densityClass = compact ? "studium-html-compact" : "studium-html-comfortable"
    let highlightFill = isDark ? "rgba(202, 138, 4, 0.45)" : "#FDE68A"

    let processed = StudiumHTMLEntities.decode(content)
        .replacingOccurrences(of: "<span class=\"sr-only\">blank</span>", with: "", options: .caseInsensitive)
        .replacingOccurrences(of: "<span class=\"sr-only\">Blank</span>", with: "")
        .replacingOccurrences(of: "<span class=\"sr-only\">BLANK</span>", with: "")
        .replacingOccurrences(of: ">blank<", with: ">______<", options: .caseInsensitive)
        .replacingOccurrences(of: " blank ", with: " ______ ", options: .caseInsensitive)
        .replacingOccurrences(of: " blank.", with: " ______.", options: .caseInsensitive)
        .replacingOccurrences(of: " blank,", with: " ______,", options: .caseInsensitive)
        .replacingOccurrences(of: " blank:", with: " ______:", options: .caseInsensitive)
        .replacingOccurrences(of: " blank;", with: " ______;", options: .caseInsensitive)

    // Swift \\\\( → HTML \\( → JS '\\(' = \(  ← correct MathJax inline delimiter
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, viewport-fit=cover, user-scalable=no">
        <meta name="color-scheme" content="light dark">
        <script>
        window.MathJax = {
            tex: {
                inlineMath: [['\\\\(', '\\\\)']],
                displayMath: [['\\\\[', '\\\\]']],
                tags: 'none',
                /* noerrors: bad TeX becomes a small inline error instead of aborting / corrupting later math on the page */
                packages: {'[+]': ['ams', 'newcommand', 'configmacros', 'noerrors']}
            },
            /* CHTML output stays crisp on iPad for both inline and display/aligned math. */
            chtml: {
                scale: 1,
                displayAlign: 'center',
                matchFontHeight: false
            },
            options: {
                skipHtmlTags: ['script','noscript','style','textarea','pre','code'],
                ignoreHtmlClass: 'tex2jax_ignore',
                processHtmlClass: 'tex2jax_process'
            },
            startup: {
                typeset: true,
                ready() {
                    MathJax.startup.defaultReady();
                    function postH() {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                            window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                        }
                    }
                    MathJax.startup.promise.then(function() {
                        postH();
                        requestAnimationFrame(function() { requestAnimationFrame(postH); });
                        /* aligned / display blocks often finish layout after first paint; late heights avoid WKWebView stuck at wrong size (looks like “all math broke”) */
                        [40, 120, 280, 600].forEach(function(ms) { setTimeout(postH, ms); });
                    }).catch(function() { postH(); });
                }
            }
        };
        </script>
        <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
        <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { width: 100%; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display', 'Helvetica Neue', system-ui, sans-serif;
            font-size: \(fontSize)px;
            line-height: 1.7;
            color: \(fg);
            background-color: \(bg);
            padding: \(compact ? "3px 2px 6px" : "4px 2px 14px");
            word-wrap: break-word;
            overflow-x: hidden;
            -webkit-text-size-adjust: 100%;
            text-rendering: optimizeLegibility;
            -webkit-font-smoothing: antialiased;
        }
        /* Let block math extend horizontally; clipping + scroll on mjx caused soft, scaled display on iPad. */
        body.studium-profile-quizfig {
            overflow-x: visible !important;
        }
        html:has(body.studium-profile-quizfig) {
            overflow-x: visible;
        }
        /* Comfortable question / explanation HTML: match passage inset (compact rows stay tight via studium-html-compact). */
        body.studium-html-comfortable.studium-profile-quizfig {
            padding: 12px 16px 16px !important;
            line-height: 1.65 !important;
        }
        body.studium-highlight-mode {
            -webkit-user-select: text;
            user-select: text;
            cursor: text;
        }
        body:not(.studium-highlight-mode) {
            -webkit-user-select: none;
            user-select: none;
        }
        body.studium-highlight-mode ::selection {
            background-color: \(highlightFill);
            color: inherit;
        }
        mark.studium-highlight {
            background-color: \(highlightFill) !important;
            color: inherit !important;
            border-radius: 2px;
            padding: 0 1px;
            box-decoration-break: clone;
            -webkit-box-decoration-break: clone;
        }
        /* Question-bank HTML frequently contains inline style="color:#000000" on spans/paragraphs.
           Force all text to the correct colour so it's visible against the background.
           We only override color (not background) to avoid wiping table/math backgrounds. */
        * { color: \(fg) !important; }
        body { background-color: \(bg); }
        math { color: inherit; }
        mjx-container { color: \(fg) !important; filter: none !important; opacity: 1 !important; }
        mjx-container[jax="CHTML"] { font-size: 1em !important; }
        mjx-container mjx-math { font-kerning: normal; }
        img:not(.math-img):not([role="math"]) {
            max-width: 100%; height: auto; object-fit: contain;
            display: block; margin: 10px auto; border-radius: 6px;
        }
        /* Retina sharpness: PNG bitmaps from the CB bank are 1x assets.
           JS sets a DPR-aware maxWidth so they never upscale on 2x/3x screens.
           image-rendering hint reduces interpolation artifacts if any residual upsampling occurs. */
        img[src^="data:image/png"] {
            image-rendering: -webkit-optimize-contrast;
        }
        /* SAT bank inline equation images: keep inline; do not inherit diagram centering/block layout. */
        .math-container .math-img,
        .math-container img[role="math"],
        .math_expression img[role="math"],
        img.math-img[role="math"] {
            display: inline-block !important;
            vertical-align: middle !important;
            margin: 0 0.08em !important;
            max-width: none !important;
            width: auto !important;
            height: auto !important;
            border-radius: 0 !important;
            object-fit: contain;
            image-rendering: -webkit-optimize-contrast;
            image-rendering: crisp-edges;
        }
        /* Block diagrams: allow larger than body text column (still capped for very wide windows). */
        figure > img:not(.math-img):not([role="math"]),
        p > img:only-child:not(.math-img):not([role="math"]) {
            max-width: min(100%, 760px) !important;
            width: auto !important;
            margin: 16px auto !important;
        }
        figure { max-width: min(100%, 800px); margin-inline: auto; }
        /* White plate only for block diagrams in dark mode — not MathJax math. */
        body.studysat-dark figure > img:not(.math-img):not([role="math"]),
        body.studysat-dark p > img:only-child:not(.math-img):not([role="math"]),
        body.studysat-dark .standalone_image img,
        body.studysat-dark .choice_paragraph img[src^="data:image"] {
            background-color: rgba(255,255,255,0.97) !important;
            padding: 14px 16px !important;
            border-radius: 12px !important;
            box-sizing: border-box !important;
            box-shadow: inset 0 0 0 1px rgba(0,0,0,0.06) !important;
        }
        /* Standalone SVG diagrams in typical SAT wrappers; exclude MathJax below. */
        body.studysat-dark figure > svg,
        body.studysat-dark p > svg:only-child {
            background-color: rgba(255,255,255,0.97) !important;
            padding: 14px 16px !important;
            border-radius: 12px !important;
            box-sizing: border-box !important;
            max-width: min(100%, 760px) !important;
            width: auto !important;
            height: auto !important;
            display: block !important;
            margin: 16px auto !important;
            box-shadow: inset 0 0 0 1px rgba(0,0,0,0.08) !important;
        }
        body.studysat-dark mjx-container svg {
            background: none !important;
            padding: 0 !important;
            margin: 0 !important;
            box-shadow: none !important;
            border-radius: 0 !important;
            max-width: none !important;
            width: auto !important;
            height: auto !important;
            shape-rendering: geometricPrecision;
        }
        /* Light mode: same larger diagram sizing without white mat. */
        body.studysat-light figure > svg,
        body.studysat-light p > svg:only-child {
            max-width: min(100%, 760px) !important;
            display: block !important;
            margin: 16px auto !important;
        }
        h1, h2, h3, h4, h5, h6 {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif;
            font-weight: 600;
            line-height: 1.3;
            margin: 16px 0 8px;
            letter-spacing: -0.01em;
        }
        h1 { font-size: 1.5em; }
        h2 { font-size: 1.3em; }
        h3 { font-size: 1.15em; }
        h4, h5, h6 { font-size: 1em; }
        p { margin: 0 0 \(compact ? "8px" : "12px"); }
        p:last-child { margin-bottom: 0; }
        ul, ol { padding-left: 22px; margin: 0 0 12px; }
        li { margin: 5px 0; line-height: 1.6; }
        li:last-child { margin-bottom: 0; }
        ul ul, ol ol, ul ol, ol ul { margin: 4px 0; }
        strong, b { font-weight: 600; }
        em, i { font-style: italic; }
        blockquote {
            border-left: 3px solid \(isDark ? "#636366" : "#C7C7CC");
            padding: 4px 0 4px 14px;
            margin: 12px 0;
            opacity: 0.85;
        }
        code {
            font-family: 'SF Mono', 'Menlo', 'Courier New', monospace;
            font-size: 0.875em;
            background-color: \(isDark ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.06)");
            padding: 2px 5px;
            border-radius: 4px;
        }
        pre {
            font-family: 'SF Mono', 'Menlo', 'Courier New', monospace;
            font-size: 0.875em;
            background-color: \(isDark ? "rgba(255,255,255,0.07)" : "rgba(0,0,0,0.04)");
            border: 1px solid \(border);
            padding: 12px 14px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 12px 0;
            line-height: 1.5;
            -webkit-overflow-scrolling: touch;
        }
        pre code { background: none; padding: 0; border-radius: 0; font-size: inherit; }
        sup, sub { font-size: 0.75em; line-height: 0; }
        figure { margin: 0; max-width: 100%; }
        figure.table { display: block; overflow-x: auto; -webkit-overflow-scrolling: touch; }
        table {
            width: 100%; border-collapse: collapse;
            margin: 4px 0; font-size: 14.5px; color: \(fg);
            border-radius: 8px; overflow: hidden;
        }
        table, th, td { border: 1px solid \(border); }
        table.table_Borderless,
        table.table_Borderless th,
        table.table_Borderless td { border: none !important; }
        th, td { padding: 9px 12px; text-align: left; vertical-align: middle; color: inherit; }
        th {
            background-color: \(headerBg);
            font-weight: 600;
            font-size: 13px;
            letter-spacing: 0.01em;
        }
        tr:nth-child(even) { background-color: \(rowAlt); }
        tr:nth-child(odd)  { background-color: transparent; }
        .table-scroll-wrapper {
            overflow-x: auto; -webkit-overflow-scrolling: touch;
            margin: 12px 0; max-width: 100%; scrollbar-width: thin;
            border-radius: 8px;
        }
        .sr-only {
            position: absolute; width: 1px; height: 1px; padding: 0;
            margin: -1px; overflow: hidden; clip: rect(0,0,0,0);
            white-space: nowrap; border-width: 0;
        }
        /* CHTML math blocks: keep display spacing stable and avoid clipping. */
        mjx-container[jax="CHTML"][display="true"] {
            margin: 14px 0 !important;
            overflow: visible !important;
            max-width: 100% !important;
        }
        /* Inline math: keep tight to surrounding text. */
        mjx-container[jax="CHTML"][display="false"] {
            overflow: visible !important;
        }
        /* Reading passages: roomier measure (font size comes from Swift `fontSize`). */
        body.studium-profile-passage {
            padding: 22px 28px 28px !important;
            line-height: 1.82 !important;
        }
        body.studium-profile-passage p { margin-bottom: 14px !important; }
        /* Stems, choices, explanations: larger diagram cap than reference / compact rows. */
        body.studium-profile-quizfig figure > img:not(.math-img):not([role="math"]),
        body.studium-profile-quizfig p > img:only-child:not(.math-img):not([role="math"]) {
            max-width: min(100%, 940px) !important;
            margin: 22px auto !important;
        }
        body.studium-profile-quizfig figure { max-width: min(100%, 980px); }
        body.studium-profile-quizfig figure > svg,
        body.studium-profile-quizfig p > svg:only-child {
            max-width: min(100%, 940px) !important;
            margin: 22px auto !important;
        }
        body.studysat-dark.studium-profile-quizfig figure > img:not(.math-img):not([role="math"]),
        body.studysat-dark.studium-profile-quizfig p > img:only-child:not(.math-img):not([role="math"]) {
            padding: 16px 18px !important;
        }
        body.studysat-dark.studium-profile-quizfig figure > svg,
        body.studysat-dark.studium-profile-quizfig p > svg:only-child {
            padding: 16px 18px !important;
        }
        </style>
    </head>
    <body class="\(bodyClass) \(profile.rawValue) \(densityClass)">
        \(processed)
        <script>
        (function() {
            // CB bank images are 1x PNG bitmaps (242–480px wide).
            // On Retina (DPR=2/3) the browser upsamples them if CSS logical pixels > natural pixels.
            // Fix: cap each image's CSS max-width at naturalWidth/DPR so it maps 1:1 to device pixels.
            function scaleRasterImages() {
                var dpr = window.devicePixelRatio || 1;
                document.querySelectorAll('img[src^="data:image"]').forEach(function(img) {
                    var apply = function() {
                        if (!img.naturalWidth) return;
                        // 1:1 device-pixel mapping = no GPU upsampling = crisp
                        img.style.maxWidth = Math.round(img.naturalWidth / dpr) + 'px';
                        img.style.width = '100%';
                        img.style.height = 'auto';
                    };
                    if (img.complete && img.naturalWidth) apply();
                    else img.addEventListener('load', apply, { once: true });
                });
            }

            scaleRasterImages();
            setTimeout(scaleRasterImages, 80);
            setTimeout(scaleRasterImages, 220);

            // Wrap tables in a scroll-safe container
            document.querySelectorAll('table').forEach(function(t) {
                var p = t.parentElement;
                if (p && p.classList.contains('table-scroll-wrapper')) return;
                var w = document.createElement('div');
                w.className = 'table-scroll-wrapper';
                t.parentNode.insertBefore(w, t);
                w.appendChild(t);
            });
            // Report height after images load (for coordinate-plane PNGs)
            function reportHeight() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                    window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                }
            }
            var imgs = document.querySelectorAll('img');
            var pending = imgs.length;
            if (pending === 0) return;
            imgs.forEach(function(img) {
                if (img.complete) { pending--; }
                else {
                    img.addEventListener('load',  function() { if (--pending <= 0) reportHeight(); });
                    img.addEventListener('error', function() { if (--pending <= 0) reportHeight(); });
                }
            });
            if (pending <= 0) reportHeight();
        })();
        </script>
        <script>
        // Re-report height whenever the body reflows (e.g. split-pane drag changes pane width).
        // ResizeObserver fires after each layout — postMessage is async so no SwiftUI re-render loop.
        (function() {
            function postH() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                    window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                }
            }
            if (typeof ResizeObserver !== 'undefined') {
                new ResizeObserver(postH).observe(document.body);
            }
        })();
        </script>
        <script>
        (function() {
            window.studiumHighlightActive = false;

            function reportHeight() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                    window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                }
            }

            function applyHighlightFromSelection() {
                if (!window.studiumHighlightActive) return;
                var sel = window.getSelection();
                if (!sel || sel.isCollapsed || sel.rangeCount === 0) return;
                var range = sel.getRangeAt(0);
                if (!document.body.contains(range.commonAncestorContainer)) return;
                var mark = document.createElement('mark');
                mark.className = 'studium-highlight';
                mark.setAttribute('data-studium-highlight', '1');
                try {
                    range.surroundContents(mark);
                } catch (e) {
                    var fragment = range.extractContents();
                    mark.appendChild(fragment);
                    range.insertNode(mark);
                }
                sel.removeAllRanges();
                reportHeight();
            }

            document.addEventListener('mouseup', function() {
                setTimeout(applyHighlightFromSelection, 0);
            });
        })();
        </script>
    </body>
    </html>
    """
}

// MARK: - iOS representable (internal)

#if os(iOS)
private struct _HTMLUIRepresentable: UIViewRepresentable {
    let htmlContent: String
    let isScrollable: Bool
    let allowInteraction: Bool
    let compact: Bool
    let fontSizeOverride: CGFloat?
    let contentProfile: HTMLContentProfile
    let textHighlightingEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("htmlFontSize") private var storedFontSize: Double = 16.0
    @Binding var contentHeight: CGFloat?

    init(
        htmlContent: String,
        isScrollable: Bool = false,
        allowInteraction: Bool = false,
        compact: Bool = false,
        fontSizeOverride: CGFloat? = nil,
        contentProfile: HTMLContentProfile = .standard,
        textHighlightingEnabled: Bool = false,
        contentHeight: Binding<CGFloat?> = .constant(nil)
    ) {
        self.htmlContent = htmlContent
        self.isScrollable = isScrollable
        self.allowInteraction = allowInteraction
        self.compact = compact
        self.fontSizeOverride = fontSizeOverride
        self.contentProfile = contentProfile
        self.textHighlightingEnabled = textHighlightingEnabled
        self._contentHeight = contentHeight
    }

    func makeCoordinator() -> HTMLCoordinator { HTMLCoordinator(contentHeight: $contentHeight) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = makeWebView(coordinator: context.coordinator)
        context.coordinator.attach(webView: webView)
        webView.scrollView.isScrollEnabled = isScrollable
        webView.scrollView.showsVerticalScrollIndicator = isScrollable
        applyInteractionSettings(to: webView, coordinator: context.coordinator)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.contentHeight = $contentHeight
        context.coordinator.attach(webView: webView)
        applyInteractionSettings(to: webView, coordinator: context.coordinator)
        let fontPx = fontSizeOverride ?? CGFloat(storedFontSize)
        loadIfNeeded(
            buildHTMLString(
                htmlContent,
                colorScheme: colorScheme,
                fontSize: fontPx,
                compact: compact,
                profile: contentProfile
            ),
            into: webView,
            coordinator: context.coordinator
        )
        context.coordinator.syncHighlightMode(active: textHighlightingEnabled)
    }

    private func applyInteractionSettings(to webView: WKWebView, coordinator: HTMLCoordinator) {
        webView.isUserInteractionEnabled = allowInteraction
        if #available(iOS 14.5, *) {
            webView.configuration.preferences.isTextInteractionEnabled = allowInteraction
        }
        coordinator.syncHighlightMode(active: textHighlightingEnabled)
    }
}

// MARK: - macOS representable (internal)

#elseif os(macOS)
/// Pins `WKWebView` to the proposed SwiftUI size. A bare `WKWebView` often gets zero
/// intrinsic width in `VStack(alignment: .leading)` / split columns, so nothing draws.
private final class WKWebViewContainer: NSView {
    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }
}

private struct _HTMLNSRepresentable: NSViewRepresentable {
    let htmlContent: String
    let isScrollable: Bool
    let allowInteraction: Bool
    let compact: Bool
    let fontSizeOverride: CGFloat?
    let contentProfile: HTMLContentProfile
    let textHighlightingEnabled: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("htmlFontSize") private var storedFontSize: Double = 16.0
    @Binding var contentHeight: CGFloat?

    init(
        htmlContent: String,
        isScrollable: Bool = false,
        allowInteraction: Bool = false,
        compact: Bool = false,
        fontSizeOverride: CGFloat? = nil,
        contentProfile: HTMLContentProfile = .standard,
        textHighlightingEnabled: Bool = false,
        contentHeight: Binding<CGFloat?> = .constant(nil)
    ) {
        self.htmlContent = htmlContent
        self.isScrollable = isScrollable
        self.allowInteraction = allowInteraction
        self.compact = compact
        self.fontSizeOverride = fontSizeOverride
        self.contentProfile = contentProfile
        self.textHighlightingEnabled = textHighlightingEnabled
        self._contentHeight = contentHeight
    }

    func makeCoordinator() -> HTMLCoordinator { HTMLCoordinator(contentHeight: $contentHeight) }

    func makeNSView(context: Context) -> WKWebViewContainer {
        let webView = makeWebView(coordinator: context.coordinator)
        context.coordinator.attach(webView: webView)
        applyInteractionSettings(to: webView, coordinator: context.coordinator)
        return WKWebViewContainer(webView: webView)
    }

    func updateNSView(_ container: WKWebViewContainer, context: Context) {
        context.coordinator.contentHeight = $contentHeight
        context.coordinator.attach(webView: container.webView)
        applyInteractionSettings(to: container.webView, coordinator: context.coordinator)
        let fontPx = fontSizeOverride ?? CGFloat(storedFontSize)
        loadIfNeeded(
            buildHTMLString(
                htmlContent,
                colorScheme: colorScheme,
                fontSize: fontPx,
                compact: compact,
                profile: contentProfile
            ),
            into: container.webView,
            coordinator: context.coordinator
        )
        context.coordinator.syncHighlightMode(active: textHighlightingEnabled)
    }

    private func applyInteractionSettings(to webView: WKWebView, coordinator: HTMLCoordinator) {
        if #available(macOS 11.3, *) {
            webView.configuration.preferences.isTextInteractionEnabled = allowInteraction
        }
        coordinator.syncHighlightMode(active: textHighlightingEnabled)
    }
}
#endif

// MARK: - Public self-sizing HTMLContentView

/// Renders HTML/LaTeX content with automatic height sizing — no external binding needed.
/// Set `fillViewport: true` in split-pane passage columns so the web view fills its container
/// and scrolls internally (matching the web's `fillViewport` prop on `HtmlBlock`).
struct HTMLContentView: View {
    let htmlContent: String
    var isScrollable: Bool = false
    var allowInteraction: Bool = false
    var compact: Bool = false
    var fontSizeOverride: CGFloat? = nil
    var contentProfile: HTMLContentProfile = .standard
    var fillViewport: Bool = false
    var textHighlightingEnabled: Bool = false

    @State private var measuredHeight: CGFloat? = nil

    init(
        htmlContent: String,
        isScrollable: Bool = false,
        allowInteraction: Bool = false,
        compact: Bool = false,
        fontSizeOverride: CGFloat? = nil,
        contentProfile: HTMLContentProfile = .standard,
        fillViewport: Bool = false,
        textHighlightingEnabled: Bool = false
    ) {
        self.htmlContent = htmlContent
        self.isScrollable = isScrollable
        self.allowInteraction = allowInteraction
        self.compact = compact
        self.fontSizeOverride = fontSizeOverride
        self.contentProfile = contentProfile
        self.fillViewport = fillViewport
        self.textHighlightingEnabled = textHighlightingEnabled
    }

    private var frameHeight: CGFloat {
        guard let h = measuredHeight, h > 0 else { return compact ? 24 : 60 }
        return max(h, compact ? 24 : 48)
    }

    var body: some View {
        if fillViewport {
            platformRepresentable(.constant(nil))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            platformRepresentable($measuredHeight)
                .frame(height: frameHeight)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func platformRepresentable(_ binding: Binding<CGFloat?>) -> some View {
        #if os(iOS)
        _HTMLUIRepresentable(
            htmlContent: htmlContent,
            isScrollable: fillViewport || isScrollable,
            allowInteraction: allowInteraction,
            compact: compact,
            fontSizeOverride: fontSizeOverride,
            contentProfile: contentProfile,
            textHighlightingEnabled: textHighlightingEnabled,
            contentHeight: binding
        )
        #elseif os(macOS)
        _HTMLNSRepresentable(
            htmlContent: htmlContent,
            isScrollable: isScrollable,
            allowInteraction: allowInteraction,
            compact: compact,
            fontSizeOverride: fontSizeOverride,
            contentProfile: contentProfile,
            textHighlightingEnabled: textHighlightingEnabled,
            contentHeight: binding
        )
        #endif
    }
}
