//
//  FilterOptions.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import Foundation

// MARK: - Filter Options
struct FilterOptions: Codable, Equatable {
    var program: String?
    var module: String?
    var primaryClassCdDesc: String?
    var skillDesc: String?
    var difficulty: String?
    var seenStatus: SeenStatus
    var isBluebook: BluebookFilter?
    
    enum SeenStatus: String, Codable, CaseIterable {
        case all = "All"
        case seen = "Seen"
        case unseen = "Unseen"
    }
    
    enum BluebookFilter: String, Codable, CaseIterable {
        case all = "All"
        case bluebook = "Bluebook"
        case notBluebook = "Not Bluebook"
    }
    
    init(
        program: String? = nil,
        module: String? = nil,
        primaryClassCdDesc: String? = nil,
        skillDesc: String? = nil,
        difficulty: String? = nil,
        seenStatus: SeenStatus = .all,
        isBluebook: BluebookFilter? = nil
    ) {
        self.program = program
        self.module = module
        self.primaryClassCdDesc = primaryClassCdDesc
        self.skillDesc = skillDesc
        self.difficulty = difficulty
        self.seenStatus = seenStatus
        self.isBluebook = isBluebook
    }
    
    func matches(_ question: Question) -> Bool {
        if let program = program, question.program != program {
            return false
        }
        if let module = module, question.module != module {
            return false
        }
        if let primaryClassCdDesc = primaryClassCdDesc, question.primaryClassCdDesc != primaryClassCdDesc {
            return false
        }
        if let skillDesc = skillDesc, question.skillDesc != skillDesc {
            return false
        }
        if let difficulty = difficulty, question.difficulty != difficulty {
            return false
        }
        if let isBluebook = isBluebook {
            // Check if question is from bluebook - typically questions with "ibn" field are bluebook
            // or we can check origin field if it exists
            let questionIsBluebook = question.ibn != nil || question.content.origin?.lowercased().contains("bluebook") == true
            switch isBluebook {
            case .bluebook:
                if !questionIsBluebook {
                    return false
                }
            case .notBluebook:
                if questionIsBluebook {
                    return false
                }
            case .all:
                break
            }
        }
        return true
    }
}

