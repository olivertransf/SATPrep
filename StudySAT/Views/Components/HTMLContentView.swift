//
//  HTMLContentView.swift
//  StudySAT
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
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = isScrollable
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = isScrollable
        webView.scrollView.showsHorizontalScrollIndicator = false
        // Always enable interaction so tables can be scrolled horizontally.
        // Link navigation is blocked in the coordinator's decidePolicyFor method.
        webView.isUserInteractionEnabled = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlString = wrapHTML(htmlContent)
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        // Height will be updated in didFinish navigation delegate
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(contentHeight: $contentHeight)
    }
    
    private func wrapHTML(_ content: String) -> String {
        let isDark = colorScheme == .dark
        let backgroundColor = isDark ? "#000000" : "#FFFFFF"
        let textColor = isDark ? "#FFFFFF" : "#000000"
        
        // Replace blank placeholders - remove screen reader text and ensure underscores are visible
        var processedContent = content
            // Remove screen reader only blank text
            .replacingOccurrences(of: "<span class=\"sr-only\">blank</span>", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "<span class=\"sr-only\">Blank</span>", with: "")
            .replacingOccurrences(of: "<span class=\"sr-only\">BLANK</span>", with: "")
            // Replace standalone "blank" words (not in HTML tags) with underscores
            .replacingOccurrences(of: ">blank<", with: ">______<", options: .caseInsensitive)
            .replacingOccurrences(of: " blank ", with: " ______ ", options: .caseInsensitive)
            .replacingOccurrences(of: " blank.", with: " ______.", options: .caseInsensitive)
            .replacingOccurrences(of: " blank,", with: " ______,", options: .caseInsensitive)
            .replacingOccurrences(of: " blank:", with: " ______:", options: .caseInsensitive)
            .replacingOccurrences(of: " blank;", with: " ______;", options: .caseInsensitive)
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/mml-chtml.js"></script>
            <script>
                window.MathJax = {
                    options: {
                        skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code'],
                        ignoreHtmlClass: 'tex2jax_ignore',
                        processHtmlClass: 'tex2jax_process'
                    }
                };
            </script>
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
                    padding: 10px;
                    word-wrap: break-word;
                    overflow: visible;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                    margin: 8px auto;
                    border-radius: 4px;
                }
                ul, ol {
                    padding-left: 20px;
                    margin: 8px 0;
                }
                li {
                    margin: 4px 0;
                }
                blockquote {
                    border-left: 3px solid \(isDark ? "#555" : "#ccc");
                    padding-left: 12px;
                    margin: 8px 0;
                    color: \(isDark ? "#aaa" : "#666");
                }
                sup, sub {
                    font-size: 0.75em;
                    line-height: 0;
                }
                math {
                    font-size: 1.1em;
                    display: inline-block;
                }
                mfrac {
                    display: inline-block;
                    vertical-align: middle;
                }
                mi, mn, mo {
                    font-family: 'Times New Roman', serif;
                }
                p {
                    margin: 8px 0;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 8px 0;
                    font-size: 14px;
                }
                table, th, td {
                    border: 1px solid \(isDark ? "#444" : "#ccc");
                }
                th, td {
                    padding: 8px 10px;
                    text-align: left;
                    vertical-align: top;
                }
                th {
                    background-color: \(isDark ? "#1a1a1a" : "#f0f0f0");
                    font-weight: 600;
                }
                tr:nth-child(even) {
                    background-color: \(isDark ? "#111" : "#fafafa");
                }
                /* Scrollable table wrapper (injected via JS below) */
                .table-scroll-wrapper {
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                    margin: 8px 0;
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
                .MathJax {
                    font-size: 1.1em !important;
                }
            </style>
        </head>
        <body>
            \(processedContent)
            <script>
                // Wrap tables in scrollable containers
                document.querySelectorAll('table').forEach(function(table) {
                    if (!table.parentElement.classList.contains('table-scroll-wrapper')) {
                        var wrapper = document.createElement('div');
                        wrapper.className = 'table-scroll-wrapper';
                        table.parentNode.insertBefore(wrapper, table);
                        wrapper.appendChild(table);
                    }
                });

                if (window.MathJax && window.MathJax.typesetPromise) {
                    MathJax.typesetPromise().then(function() {
                        // Update height after MathJax renders
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.heightUpdate) {
                            var height = document.body.scrollHeight;
                            window.webkit.messageHandlers.heightUpdate.postMessage(height);
                        }
                    }).catch(function(err) {
                        console.log('MathJax rendering error:', err);
                    });
                }
            </script>
        </body>
        </html>
        """
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var contentHeight: CGFloat?
        
        init(contentHeight: Binding<CGFloat?>) {
            _contentHeight = contentHeight
        }
        
        func updateHeight(_ height: CGFloat) {
            // Validate height is finite and positive
            guard height.isFinite && height > 0 && height < 10000 else {
                return
            }
            contentHeight = height
        }
        
        // Block link navigation so the web view stays on the rendered content
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Wait for MathJax to potentially render, then get content height
            // Try multiple times to account for MathJax rendering
            func updateHeight(attempt: Int = 0) {
                let delay = attempt == 0 ? 0.3 : (attempt == 1 ? 0.8 : 1.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    webView.evaluateJavaScript("document.body.scrollHeight") { (result, error) in
                        if let height = result as? CGFloat, height.isFinite && height > 0 && height < 10000 {
                            DispatchQueue.main.async {
                                self.contentHeight = height
                            }
                        } else if attempt < 2 {
                            // Try again if we haven't exceeded max attempts
                            updateHeight(attempt: attempt + 1)
                        }
                    }
                }
            }
            updateHeight()
        }
    }
}
