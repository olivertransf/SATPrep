//
//  HTMLContentView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI
import WebKit

struct HTMLContentView: UIViewRepresentable {
    let htmlContent: String
    let isScrollable: Bool
    let allowInteraction: Bool
    @Environment(\.colorScheme) var colorScheme
    @Binding var contentHeight: CGFloat?

    init(htmlContent: String, isScrollable: Bool = true, allowInteraction: Bool = false, contentHeight: Binding<CGFloat?> = .constant(nil)) {
        self.htmlContent = htmlContent
        self.isScrollable = isScrollable
        self.allowInteraction = allowInteraction
        self._contentHeight = contentHeight
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Use a weak proxy so the message handler doesn't create a retain cycle
        configuration.userContentController.add(
            WeakScriptMessageHandler(context.coordinator),
            name: "heightUpdate"
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = isScrollable
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = isScrollable
        webView.scrollView.showsHorizontalScrollIndicator = false
        // Always enable interaction so tables can scroll horizontally.
        // Link navigation is blocked in the coordinator's decidePolicyFor method.
        webView.isUserInteractionEnabled = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlString = wrapHTML(htmlContent)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }

    // MARK: - HTML Builder

    private func wrapHTML(_ content: String) -> String {
        let isDark = colorScheme == .dark
        // Match iOS system grouped content (not pure black — better for PNG graphs & math bitmaps).
        let backgroundColor = isDark ? "#1C1C1E" : "#FFFFFF"
        let textColor = isDark ? "#EBEBF5" : "#000000"
        let mutedText = isDark ? "#AEAEB2" : "#666666"
        let tableBorder = isDark ? "#48484A" : "#D1D1D6"
        let tableHeaderBg = isDark ? "#2C2C2E" : "#F2F2F7"
        let tableRowAlt = isDark ? "#252528" : "#FAFAFA"
        let bodyClass = isDark ? "studysat-dark" : "studysat-light"

        // Replace blank placeholders
        let processedContent = content
            .replacingOccurrences(of: "<span class=\"sr-only\">blank</span>", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "<span class=\"sr-only\">Blank</span>", with: "")
            .replacingOccurrences(of: "<span class=\"sr-only\">BLANK</span>", with: "")
            .replacingOccurrences(of: ">blank<", with: ">______<", options: .caseInsensitive)
            .replacingOccurrences(of: " blank ", with: " ______ ", options: .caseInsensitive)
            .replacingOccurrences(of: " blank.", with: " ______.", options: .caseInsensitive)
            .replacingOccurrences(of: " blank,", with: " ______,", options: .caseInsensitive)
            .replacingOccurrences(of: " blank:", with: " ______:", options: .caseInsensitive)
            .replacingOccurrences(of: " blank;", with: " ______;", options: .caseInsensitive)

        // ESCAPING NOTE:
        // Swift \\\\( → HTML \\( → JS string '\\(' = \(  ← correct MathJax delimiter
        // Swift \\(   → HTML \(  → JS string '\('  = (   ← WRONG (JS drops the backslash)
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <meta name="color-scheme" content="light dark">
            <script>
                // MathJax config MUST be set before the async script loads.
                window.MathJax = {
                    tex: {
                        inlineMath: [['\\\\(', '\\\\)']],
                        displayMath: [['\\\\[', '\\\\]']],
                        tags: 'none'
                    },
                    chtml: {
                        scale: 1,
                        matchFontHeight: true,
                        mtextInheritFont: true
                    },
                    options: {
                        skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code'],
                        ignoreHtmlClass: 'tex2jax_ignore',
                        processHtmlClass: 'tex2jax_process'
                    },
                    startup: {
                        typeset: true,
                        ready() {
                            MathJax.startup.defaultReady();
                            // Report height AFTER MathJax finishes typesetting
                            MathJax.startup.promise.then(function() {
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                                    window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                                }
                            });
                        }
                    }
                };
            </script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html, body {
                    width: 100%;
                    margin: 0;
                    padding: 0;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 16px;
                    line-height: 1.6;
                    color: \(textColor);
                    background-color: \(backgroundColor);
                    margin: 0;
                    padding: 8px;
                    word-wrap: break-word;
                    overflow: visible;
                }
                /* Native MathML follows page text color */
                math {
                    color: inherit;
                }
                /* MathJax v3 CHTML + SVG output */
                mjx-container {
                    color: \(textColor) !important;
                }
                mjx-container svg {
                    color: inherit;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    object-fit: contain;
                    display: block;
                    margin: 6px auto;
                    border-radius: 4px;
                }
                /* College Board formula bitmaps: black ink on transparent — unreadable on dark background */
                body.studysat-dark span.math-container,
                body.studysat-dark .math-container {
                    background-color: rgba(255, 255, 255, 0.96) !important;
                    padding: 5px 10px !important;
                    border-radius: 8px !important;
                    display: inline-block !important;
                    max-width: 100% !important;
                    box-sizing: border-box !important;
                    vertical-align: middle !important;
                    box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.06);
                }
                body.studysat-dark span.math-container img,
                body.studysat-dark .math-container img {
                    margin: 0 auto;
                }
                /* Standalone graphs / large figures (often black on white PNG) */
                body.studysat-dark figure > img,
                body.studysat-dark p > img:only-child {
                    background-color: rgba(255, 255, 255, 0.96);
                    padding: 8px;
                    border-radius: 10px;
                    box-sizing: border-box;
                    box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.06);
                }
                ul, ol {
                    padding-left: 20px;
                    margin: 8px 0;
                }
                li {
                    margin: 4px 0;
                }
                blockquote {
                    border-left: 3px solid \(isDark ? "#636366" : "#D1D1D6");
                    padding-left: 12px;
                    margin: 8px 0;
                    color: \(mutedText);
                }
                sup, sub {
                    font-size: 0.75em;
                    line-height: 0;
                }
                p {
                    margin: 8px 0;
                }
                figure {
                    margin: 0;
                    max-width: 100%;
                }
                figure.table {
                    display: block;
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 6px 0;
                    font-size: 14px;
                    color: \(textColor);
                }
                table, th, td {
                    border: 1px solid \(tableBorder);
                }
                table.table_Borderless,
                table.table_Borderless th,
                table.table_Borderless td {
                    border: none !important;
                }
                th, td {
                    padding: 6px 8px;
                    text-align: left;
                    vertical-align: middle;
                    color: inherit;
                }
                th {
                    background-color: \(tableHeaderBg);
                    font-weight: 600;
                }
                tr:nth-child(even) {
                    background-color: \(tableRowAlt);
                }
                tr:nth-child(odd) {
                    background-color: transparent;
                }
                /* Math/bitmaps inside table cells */
                td .math-container, th .math-container {
                    vertical-align: middle;
                }
                /* Scrollable table wrapper (injected via JS) */
                .table-scroll-wrapper {
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                    margin: 6px 0;
                    max-width: 100%;
                    -ms-overflow-style: none;
                    scrollbar-width: thin;
                }
                .sr-only {
                    position: absolute;
                    width: 1px;
                    height: 1px;
                    padding: 0;
                    margin: -1px;
                    overflow: hidden;
                    clip: rect(0, 0, 0, 0);
                    white-space: nowrap;
                    border-width: 0;
                }
                /* Let WebKit and MathJax handle math element styling natively —
                   do NOT override math, mfrac, mi, mn, mo here as custom CSS
                   fights the browser's MathML layout engine and causes distortion. */
            </style>
        </head>
        <body class="\(bodyClass)">
            \(processedContent)
            <script>
                (function() {
                    // Scrollable wrappers for wide tables (nested <figure class="table"> safe)
                    document.querySelectorAll('table').forEach(function(table) {
                        var p = table.parentElement;
                        if (p && p.classList.contains('table-scroll-wrapper')) return;
                        var wrapper = document.createElement('div');
                        wrapper.className = 'table-scroll-wrapper';
                        table.parentNode.insertBefore(wrapper, table);
                        wrapper.appendChild(table);
                    });
                    // Ping height after images (coordinate-plane PNGs) decode
                    function reportHeight() {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                            window.webkit.messageHandlers.heightUpdate.postMessage(document.body.scrollHeight);
                        }
                    }
                    var imgs = document.querySelectorAll('img');
                    var pending = imgs.length;
                    if (pending === 0) return;
                    imgs.forEach(function(img) {
                        if (img.complete) {
                            pending--;
                        } else {
                            img.addEventListener('load', function() {
                                pending--;
                                if (pending <= 0) reportHeight();
                            });
                            img.addEventListener('error', function() {
                                pending--;
                                if (pending <= 0) reportHeight();
                            });
                        }
                    });
                    if (pending <= 0) reportHeight();
                })();
            </script>
        </body>
        </html>
        """
    }

    // MARK: - Weak Script Message Handler (prevents retain cycle)

    /// WKUserContentController holds a strong reference to message handlers, so we
    /// pass this proxy instead. It holds a weak reference back to the coordinator.
    final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
        weak var delegate: (NSObject & WKScriptMessageHandler)?

        init(_ delegate: NSObject & WKScriptMessageHandler) {
            self.delegate = delegate
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            delegate?.userContentController(userContentController, didReceive: message)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var contentHeight: CGFloat?

        init(contentHeight: Binding<CGFloat?>) {
            _contentHeight = contentHeight
        }

        // Called by the MathJax startup.ready → promise.then callback after typesetting
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "heightUpdate" else { return }
            // JS scrollHeight is an integer; bridge via NSNumber to be safe
            if let num = message.body as? NSNumber {
                applyHeight(CGFloat(num.doubleValue))
            }
        }

        func applyHeight(_ height: CGFloat) {
            guard height.isFinite && height > 0 && height < 10000 else { return }
            DispatchQueue.main.async {
                self.contentHeight = height
            }
        }

        // Block link navigation so the web view stays on the rendered content
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // Fallback height polling for content that doesn't use MathJax
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            func pollHeight(attempt: Int = 0) {
                let delay: Double = attempt == 0 ? 0.3 : (attempt == 1 ? 0.8 : 1.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                        if let h = result as? CGFloat, h.isFinite && h > 0 && h < 10000 {
                            DispatchQueue.main.async { self.contentHeight = h }
                        } else if let h = (result as? NSNumber).map({ CGFloat($0.doubleValue) }),
                                  h.isFinite && h > 0 && h < 10000 {
                            DispatchQueue.main.async { self.contentHeight = h }
                        } else if attempt < 2 {
                            pollHeight(attempt: attempt + 1)
                        }
                    }
                }
            }
            pollHeight()
        }
    }
}
