//
//  StudiumHTMLBuilder.swift
//  Studium
//
//  Shared HTML/MathJax entry points for WKWebView consumers.
//

import SwiftUI

enum StudiumHTMLBuilder {
    /// Base URL for `loadHTMLString` so CDN MathJax loads under App Sandbox.
    static let contentBaseURL = URL(string: "https://cdn.jsdelivr.net/")!

    static func build(
        _ content: String,
        colorScheme: ColorScheme,
        fontSize: CGFloat = 16,
        compact: Bool = false,
        profile: HTMLContentProfile = .standard
    ) -> String {
        buildHTMLString(content, colorScheme: colorScheme, fontSize: fontSize, compact: compact, profile: profile)
    }
}
