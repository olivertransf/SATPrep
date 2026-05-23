//
//  QuizOptionContent.swift
//  Studium
//

import Foundation

enum QuizOptionContent {
    /// True when the option must render in `HTMLContentView` (math, images, tables, rich HTML).
    static func needsHTMLRendering(_ html: String) -> Bool {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let lower = trimmed.lowercased()
        if lower.contains("<img") || lower.contains("math-img") || lower.contains("math-container") {
            return true
        }
        if lower.contains("<table") || lower.contains("<svg") || lower.contains("<math") {
            return true
        }
        if trimmed.contains("\\(") || trimmed.contains("\\[") || trimmed.contains("$$") {
            return true
        }
        if lower.contains("class=\"math") || lower.contains("role=\"math\"") {
            return true
        }

        guard trimmed.contains("<") else { return false }

        let plain = plainText(from: trimmed)
        if plain.isEmpty { return true }

        // Simple wrappers only: one block tag around plain text.
        if isSingleParagraphWrapper(trimmed, plain: plain) {
            return false
        }

        return true
    }

    static func plainText(from html: String) -> String {
        var s = html
        s = s.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "<p[^>]*>", with: "", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        s = StudiumHTMLEntities.decode(s)
        let lines = s.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: " ")
    }

    private static func isSingleParagraphWrapper(_ html: String, plain: String) -> Bool {
        let pattern = #"^\s*<p[^>]*>([\s\S]*)</p>\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges >= 2,
              let innerRange = Range(match.range(at: 1), in: html) else {
            return false
        }
        let inner = String(html[innerRange])
        return plainText(from: inner) == plain
    }

}
