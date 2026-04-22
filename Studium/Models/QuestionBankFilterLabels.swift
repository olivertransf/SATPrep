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

    /// Practice / filter sheet — bundled sidecar IDs only (`cb-verified-not-on-practice-tests`).
    static let cbVerifiedPoolGroupTitle = "Verified pool"
    static let cbVerifiedChipAll = "All"
    static let cbVerifiedChipOnly = "Verified only"

    // Legacy bluebook filter labels (saved quizzes may still reference `isBluebook`).
    static let practiceTestsAll = "All"
    static let practiceTestsOnly = "Practice tests only"
    static let excludeActiveShort = "Exclude active"

    static func displayTitle(for filter: FilterOptions.BluebookFilter?) -> String {
        guard let filter else { return practiceTestsAll }
        switch filter {
        case .all: return practiceTestsAll
        case .bluebook: return practiceTestsOnly
        case .notBluebook: return excludeActiveShort
        }
    }
}
