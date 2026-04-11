//
//  QuestionBankFilterLabels.swift
//  Studium
//
//  Labels aligned with the College Board SAT Question Bank (mypractice.collegeboard.org).
//

import Foundation

enum QuestionBankFilterLabels {
    /// Question Bank uses "Reading and Writing"; JSON module is `english`.
    static func sectionChipTitle(module: String) -> String {
        switch module.lowercased() {
        case "english": return "Reading & Writing"
        case "math": return "Math"
        default: return module.capitalized
        }
    }

    static func sectionNameForSummary(module: String) -> String {
        sectionChipTitle(module: module)
    }

    static let assessmentGroupTitle = "Assessment"
    static let assessmentSAT = "SAT"

    static let sectionSubgroup = "Section"
    static let domainSubgroup = "Domain"
    static let skillSubgroup = "Skill"

    /// CB calls this "Exclude Active Questions" (questions on full-length practice tests).
    static let practiceTestsGroupTitle = "Practice tests"

    static let practiceTestsAll = "All"
    static let practiceTestsOnly = "Practice tests only"
    static let excludeActiveShort = "Exclude active"

    /// Educator Bank scrape (exclude active) — only IDs in bundled sidecar.
    static let cbVerifiedPoolTitle = "CB verified pool"
    static let cbVerifiedPoolAny = "Any"
    static let cbVerifiedPoolOnly = "Verified off practice tests"
    static let cbVerifiedPoolHelp =
        "Only questions whose ID appeared in an Educator Question Bank HTML export with “Exclude Active Questions” on (sidecar JSON in the app bundle)."

    static let practiceTestsHelp =
        "“Exclude active” matches the Question Bank checkbox: hide questions already used on full-length practice tests, when this bank tags them (item booklet id)."

    static func displayTitle(for filter: FilterOptions.BluebookFilter?) -> String {
        guard let filter else { return practiceTestsAll }
        switch filter {
        case .all: return practiceTestsAll
        case .bluebook: return practiceTestsOnly
        case .notBluebook: return excludeActiveShort
        }
    }
}
