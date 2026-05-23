//
//  StudiumHTMLEntities.swift
//  Studium
//

import Foundation

enum StudiumHTMLEntities {
  private static let namedReplacements: [(String, String)] = [
    ("&mdash;", "\u{2014}"),
    ("&ndash;", "\u{2013}"),
    ("&hellip;", "\u{2026}"),
    ("&ldquo;", "\u{201C}"),
    ("&rdquo;", "\u{201D}"),
    ("&lsquo;", "\u{2018}"),
    ("&rsquo;", "\u{2019}"),
    ("&nbsp;", " "),
    ("&quot;", "\""),
    ("&#39;", "'"),
    ("&apos;", "'"),
    ("&lt;", "<"),
    ("&gt;", ">"),
    ("&amp;", "&"),
  ]

  static func decode(_ text: String) -> String {
    var result = text
    for (entity, character) in namedReplacements where entity != "&amp;" {
      result = result.replacingOccurrences(of: entity, with: character, options: .caseInsensitive)
    }
    result = decodeNumericEntities(in: result, pattern: #"&#(\d+);"#) { code in
      guard code >= 0, code <= 0x10FFFF else { return nil }
      return String(UnicodeScalar(code)!)
    }
    result = decodeNumericEntities(in: result, pattern: #"&#x([0-9A-Fa-f]+);"#) { code in
      guard code >= 0, code <= 0x10FFFF else { return nil }
      return String(UnicodeScalar(code)!)
    }
    return result.replacingOccurrences(of: "&amp;", with: "&", options: .caseInsensitive)
  }

  private static func decodeNumericEntities(
    in text: String,
    pattern: String,
    scalar: (Int) -> String?
  ) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
    let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
    let matches = regex.matches(in: text, range: nsRange).reversed()
    var result = text
    for match in matches {
      guard match.numberOfRanges >= 2,
            let fullRange = Range(match.range, in: result),
            let codeRange = Range(match.range(at: 1), in: result),
            let code = Int(result[codeRange]),
            let replacement = scalar(code)
      else { continue }
      result.replaceSubrange(fullRange, with: replacement)
    }
    return result
  }
}
