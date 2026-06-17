//
//  StudiumInlineMathRepair.swift
//  Studium
//
//  Port of studium-web/src/utils/repairInlineMathTex.ts — fixes spoken-math inside \( … \).
//

import Foundation

enum StudiumInlineMathRepair {
    private static let open = "\\("
    private static let close = "\\)"

    private static let fracSuffix: [String: String] = [
        "half": "2", "halves": "2",
        "third": "3", "thirds": "3",
        "fourth": "4", "fourths": "4", "quarter": "4", "quarters": "4",
        "fifth": "5", "fifths": "5",
        "sixth": "6", "sixths": "6",
        "seventh": "7", "sevenths": "7",
        "eighth": "8", "eighths": "8",
        "ninth": "9", "ninths": "9",
        "tenth": "10", "tenths": "10",
    ]

    private static let ordinalRoot: [String: String] = [
        "square": "2", "cube": "3", "fourth": "4", "fifth": "5",
        "sixth": "6", "seventh": "7", "eighth": "8", "ninth": "9", "tenth": "10",
    ]

    static func repairHTML(_ html: String) -> String {
        var out = ""
        var i = html.startIndex
        while i < html.endIndex {
            guard let start = html.range(of: open, range: i..<html.endIndex) else {
                out += html[i...]
                break
            }
            out += html[i..<start.lowerBound]
            let bodyStart = start.upperBound
            guard let end = html.range(of: close, range: bodyStart..<html.endIndex) else {
                out += html[start.lowerBound...]
                break
            }
            let inner = String(html[bodyStart..<end.lowerBound])
            out += open + repairInner(inner) + close
            i = end.upperBound
        }
        return out
    }

    private static func repairInner(_ inner: String) -> String {
        var fixed = inner.trimmingCharacters(in: .whitespacesAndNewlines)
        while fixed.hasSuffix("\\") { fixed.removeLast() }

        fixed = replace(fixed, pattern: #"\s+\+\s+or\s+-\s+"#, options: [.caseInsensitive], with: " \\pm ")
        fixed = replace(fixed, pattern: #"\bor\s+-\b"#, options: [.caseInsensitive], with: "\\pm")

        fixed = replace(fixed, pattern: #"\bthe\s*-?\s*fraction\s+(.+?)\s+over\s+(.+?)\s+end\s+fraction\b"#, options: [.caseInsensitive]) { m in
            "\\frac{\(m[1].trimmingCharacters(in: .whitespaces))}{\(m[2].trimmingCharacters(in: .whitespaces))}"
        }

        fixed = replace(fixed, pattern: #"(\d+)-(half|third|fourth|quarter|fifth|sixth|seventh|eighth|ninth|tenth)\b"#, options: [.caseInsensitive]) { m in
            let den = fracSuffix[m[2].lowercased()] ?? m[2]
            return "\\frac{\(m[1])}{\(den)}"
        }

        fixed = replace(fixed, pattern: #"(\w+)\s+subscript\s+(\w+)\b"#, options: [.caseInsensitive]) { m in
            "\(m[1])_{\(m[2])}"
        }

        fixed = replace(fixed, pattern: #"(\S+)\s+to\s+the\s+power\s+(\\frac\{[^}]+\}\{[^}]+\})"#, options: [.caseInsensitive]) { m in
            "\(m[1])^{\(m[2])}"
        }

        fixed = replace(fixed, pattern: #"(\S+)\s+to\s+the\s+power\s+of\s+(.+?)(?=\s*(?:$|\)|,|\\times|\\cdot|\+|-))"#, options: [.caseInsensitive]) { m in
            "\(m[1])^{\(normalizeExponentBody(m[2]))}"
        }

        fixed = replace(fixed, pattern: #"(\S+)\s+to\s+the\s+power\s+(-?[\w.]+)\b"#, options: [.caseInsensitive]) { m in
            "\(m[1])^{\(m[2])}"
        }

        let rootKeys = ordinalRoot.keys.sorted { $0.count > $1.count }.joined(separator: "|")
        fixed = replace(
            fixed,
            pattern: "\\bthe\\s+(\(rootKeys))\\s+root\\s+of\\s+(.+?)(?:\\s+end\\s+root)?(?=\\s*(?:$|[=,+\\-)]|\\\\times|\\\\cdot))",
            options: [.caseInsensitive]
        ) { m in
            let n = ordinalRoot[m[1].lowercased()] ?? "2"
            let body = m[2].trimmingCharacters(in: .whitespaces)
            return n == "2" ? "\\sqrt{\(body)}" : "\\sqrt[\(n)]{\(body)}"
        }

        fixed = replace(fixed, pattern: #"\bthe cube root of\s+(.+?)(?=\s*(?:$|[=,+\-)]|(?:\s+end\s+root)))"#, options: [.caseInsensitive]) { m in
            "\\sqrt[3]{\(m[1].trimmingCharacters(in: .whitespaces))}"
        }

        fixed = replace(fixed, pattern: #"\\sqrt\{([^}]+)\}\s*\+\s*([^+\s]+(?:\s+[^+\s]+)*?)\s+end\s+root"#, options: [.caseInsensitive]) { m in
            "\\sqrt{\(m[1].trimmingCharacters(in: .whitespaces)) + \(m[2].trimmingCharacters(in: .whitespaces))}"
        }

        fixed = replace(fixed, pattern: #"\s+end\s+root\b"#, options: [.caseInsensitive], with: "")
        fixed = replace(fixed, pattern: #"\s+end\s+fraction\b"#, options: [.caseInsensitive], with: "")
        fixed = replace(fixed, pattern: #"\s+end\s+power\b"#, options: [.caseInsensitive], with: "")

        fixed = replace(fixed, pattern: #"\braised\s+to\s+(?:the\s+)?\\frac\{([^}]+)\}\{([^}\s]+)\s+power\}"#, options: [.caseInsensitive]) { m in
            "^{\\frac{\(m[1])}{\(m[2])}}"
        }
        fixed = replace(fixed, pattern: #"\braised\s+to\s+(?:the\s+)?\\frac\{([^}]+)\}\{([^}]+)\}\s+power\b"#, options: [.caseInsensitive]) { m in
            "^{\\frac{\(m[1])}{\(m[2])}}"
        }
        fixed = replace(fixed, pattern: #"\braised\s+to\s+the\s+(.+?)\s+power\b"#, options: [.caseInsensitive]) { m in
            "^{\(normalizeExponentBody(m[1]))}"
        }
        fixed = replace(fixed, pattern: #"([^\s^]+)\s+raised\s+to\s+the\s+(-?[\w.]+)\s+power\b"#, options: [.caseInsensitive]) { m in
            "\(m[1])^{\(m[2])}"
        }

        fixed = replace(fixed, pattern: #"(\w)\s*\^\s*\{([^}]+)\}"#, with: "$1^{$2}")

        fixed = replace(fixed, pattern: #"\bparenthesis\s+(.+?)\s*\)"#, options: [.caseInsensitive]) { m in
            "(\(m[1].trimmingCharacters(in: .whitespaces)))"
        }

        fixed = replace(fixed, pattern: #"([a-zA-Z])\s*\(\s*open\s*\)\s*parenthesis\s+([^)]+?)\s*\)"#, options: [.caseInsensitive]) { m in
            let arg = m[2].replacingOccurrences(of: " ", with: "")
            return "\(m[1])(\(arg))"
        }
        fixed = replace(fixed, pattern: #"\b([a-zA-Z])\s+of\s+(\([^()]*\))"#, options: [.caseInsensitive]) { m in
            "\(m[1])\(m[2])"
        }
        fixed = replace(fixed, pattern: #"\b([a-zA-Z])\s+of\s+([a-zA-Z0-9]+)\b"#, options: [.caseInsensitive]) { m in
            "\(m[1])(\(m[2]))"
        }
        fixed = replace(fixed, pattern: #"\bf\((\d+)\)\s+x\b"#, with: "f($1x)")

        let sufPat = fracSuffix.keys.sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        fixed = replace(
            fixed,
            pattern: "(\\d+)\\s+(\(sufPat))\\b",
            options: [.caseInsensitive]
        ) { m in
            let den = fracSuffix[m[2].lowercased()] ?? m[2]
            return "\\frac{\(m[1])}{\(den)}"
        }

        return fixed
    }

    private static func normalizeExponentBody(_ body: String) -> String {
        let exp = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = exp.range(of: #"\s+over\s+"#, options: [.regularExpression, .caseInsensitive]) {
            let num = String(exp[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let den = String(exp[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            return "\\frac{\(num)}{\(den)}"
        }
        return exp.replacingOccurrences(of: " ", with: "")
    }

    private static func replace(
        _ input: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        with template: String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: template)
    }

    private static func replace(
        _ input: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        transform: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return input }
        let ns = input as NSString
        let range = NSRange(location: 0, length: ns.length)
        var result = ""
        var last = 0
        regex.enumerateMatches(in: input, options: [], range: range) { match, _, _ in
            guard let match else { return }
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            var groups: [String] = []
            for i in 0..<match.numberOfRanges {
                let r = match.range(at: i)
                groups.append(r.location != NSNotFound ? ns.substring(with: r) : "")
            }
            result += transform(groups)
            last = match.range.location + match.range.length
        }
        result += ns.substring(from: last)
        return result
    }
}
