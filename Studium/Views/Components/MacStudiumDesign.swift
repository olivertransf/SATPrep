//
//  MacStudiumDesign.swift
//  Studium
//
//  Typography, spacing, and layout tokens for macOS. Keeps the Mac UI readable and
//  avoids oversized empty regions inside cards.
//

import SwiftUI

/// Visual design constants used from `#if os(macOS)` code paths (safe to reference on all platforms).
enum MacStudiumDesign {

    // MARK: - Practice shell

    static let practiceSidebarWidth: CGFloat = 312
    static let practiceSidebarPadding: CGFloat = 16
    static let practiceMainPaddingH: CGFloat = 24
    static let practiceMainPaddingTop: CGFloat = 20
    static let practiceMainPaddingBottom: CGFloat = 28
    static let practiceMainSectionSpacing: CGFloat = 22
    static let practiceSidebarSectionSpacing: CGFloat = 16
    static let conceptGridSpacing: CGFloat = 14

    // MARK: - Quiz

    static let quizPanePaddingH: CGFloat = 24
    static let quizPanePaddingV: CGFloat = 16
    static let quizBlockSpacing: CGFloat = 18
    static let quizProgressHeaderPaddingH: CGFloat = 24

    // MARK: - Continue / concept cards

    static let continueCardWidth: CGFloat = 300
    static let continueCardPadding: CGFloat = 16
    static let continueCardSpacing: CGFloat = 10

    static let conceptCardCorner: CGFloat = 14
    static let conceptCardPaddingH: CGFloat = 18
    static let conceptCardHeaderTop: CGFloat = 16
    static let conceptCardHeaderBottom: CGFloat = 12
    static let conceptSkillRowVPadding: CGFloat = 12
    static let conceptFooterPadding: CGFloat = 16
    static let conceptPracticeButtonVPadding: CGFloat = 12

    // MARK: - Filter controls (sidebar)

    static let filterChipMinHeight: CGFloat = 42
    static let filterChipHPadding: CGFloat = 12
    static let filterChipVPadding: CGFloat = 8
    static let orderChoiceMinHeight: CGFloat = 54
    static let orderChoicePaddingH: CGFloat = 12
    static let orderChoicePaddingV: CGFloat = 10

    // MARK: - Typography (macOS uses larger defaults than iPhone)

    static var sectionEyebrow: Font { .subheadline.weight(.semibold) }
    static var browsePageTitle: Font { .largeTitle.weight(.bold) }
    static var browsePageSubtitle: Font { .title3.weight(.regular) }
    static var sidebarGroupTitle: Font { .headline.weight(.semibold) }
    static var conceptCategoryTitle: Font { .title2.weight(.semibold) }
    static var conceptCategoryCount: Font { .headline.weight(.regular) }
    static var conceptSkillTitle: Font { .body.weight(.medium) }
    static var conceptSkillCount: Font { .body.monospacedDigit().weight(.semibold) }
    static var conceptPrimaryButton: Font { .headline.weight(.semibold) }
    static var continueCardTitle: Font { .title2.weight(.semibold) }
    static var continueCardMeta: Font { .body.weight(.medium) }
    static var practiceAllSidebarCount: Font { .system(size: 32, weight: .bold, design: .rounded) }
    static var practiceAllSidebarLabel: Font { .headline.weight(.regular) }
    static var practiceAllSidebarButton: Font { .headline.weight(.semibold) }
}
