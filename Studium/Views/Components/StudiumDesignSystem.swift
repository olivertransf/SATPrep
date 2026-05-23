//
//  StudiumDesignSystem.swift
//  Studium
//
//  Typography, spacing, and layout tokens. UI chrome uses SF Pro (system);
//  monospaced only via `statFont` / `questionIdFont` for numbers and debug IDs.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

enum StudiumDesignSystem {

    #if os(iOS)
    static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    #else
    static var isPhone: Bool { false }
    static var isPad: Bool { false }
    #endif

    // MARK: - Spacing scale

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    static let radiusChip: CGFloat = 10
    static let radiusCard: CGFloat = 14
    static let radiusSheet: CGFloat = 16

    static let minTapTarget: CGFloat = 44
    /// Icon-only controls on phone (Filters, delete) — smaller than full 44pt rows.
    static let phoneIconButtonSize: CGFloat = 36
    static let readableMaxWidth: CGFloat = 680

    // MARK: - Practice shell

    static var practiceSidebarFilterPadding: CGFloat {
        if isPhone { return 10 }
        if isPad { return 12 }
        return 14
    }

    /// Filter sidebar — two chip columns with readable labels.
    static let practiceSidebarWidth: CGFloat = 348
    static let practiceSidebarWidthIPad: CGFloat = 368
    static var practiceSidebarPadding: CGFloat { spacingMD }
    static var practiceSidebarFooterPadding: CGFloat { spacingLG }
    static var practiceSidebarHeaderPadding: CGFloat { spacingLG }
    static var practiceMainPaddingH: CGFloat { isPhone ? spacingLG : spacingXL }
    static var practiceMainPaddingTop: CGFloat { isPhone ? 8 : 20 }
    static var practiceMainPaddingBottom: CGFloat { isPhone ? 16 : 28 }
    static var practiceMainSectionSpacing: CGFloat { isPhone ? 12 : 22 }
    static var practicePhoneStickyBarPadding: CGFloat { isPhone ? 12 : spacingLG }
    static var practiceSidebarSectionSpacing: CGFloat { isPhone ? spacingMD : spacingLG }
    static var conceptGridSpacing: CGFloat { isPhone ? 10 : 14 }

    // MARK: - Quiz

    static var quizPanePaddingH: CGFloat { isPhone ? spacingLG : spacingXL }
    static var quizPanePaddingV: CGFloat { isPhone ? spacingMD : spacingLG }
    static var quizBlockSpacing: CGFloat { isPhone ? 14 : 18 }
    static var quizProgressHeaderPaddingH: CGFloat { isPhone ? spacingLG : spacingXL }

    // MARK: - Continue / concept cards

    static var continueCardWidth: CGFloat { isPhone ? 260 : 300 }
    static let continueCardPadding: CGFloat = spacingLG
    static let continueCardSpacing: CGFloat = 10

    static let conceptCardCorner: CGFloat = radiusCard
    static var conceptCardPaddingH: CGFloat { isPhone ? 14 : 18 }
    static var conceptCardHeaderTop: CGFloat { isPhone ? spacingMD : spacingLG }
    static var conceptCardHeaderBottom: CGFloat { isPhone ? spacingSM : spacingMD }
    static var conceptCardHeaderMinHeight: CGFloat { isPhone ? 56 : 72 }
    static var conceptSkillRowVPadding: CGFloat { isPhone ? 10 : spacingMD }
    static var conceptFooterPadding: CGFloat { isPhone ? spacingMD : spacingLG }
    static var conceptPracticeButtonVPadding: CGFloat { isPhone ? 10 : spacingMD }

    // MARK: - Filter controls

    static var filterChipMinHeight: CGFloat { isPhone ? 44 : 50 }
    static var filterSidebarChipMinHeight: CGFloat { 40 }
    static var filterChipHPadding: CGFloat { isPhone ? 10 : spacingMD }
    static var filterChipVPadding: CGFloat { isPhone ? 7 : spacingSM }
    static var orderChoiceMinHeight: CGFloat { isPhone ? 48 : 54 }
    static var orderChoicePaddingH: CGFloat { isPhone ? 10 : spacingMD }
    static var orderChoicePaddingV: CGFloat { isPhone ? spacingSM : 10 }

    static var primaryCTAControlSize: ControlSize {
        #if os(iOS)
        isPhone ? .regular : .large
        #else
        .large
        #endif
    }

    // MARK: - Typography (system)

    static var sectionEyebrow: Font {
        isPhone ? .footnote.weight(.semibold) : .subheadline.weight(.semibold)
    }

    static var browsePageTitle: Font {
        isPhone ? .headline.weight(.semibold) : .title2.weight(.bold)
    }

    static var browsePageSubtitle: Font {
        .subheadline
    }

    static var sidebarGroupTitle: Font { .headline.weight(.semibold) }
    static var conceptCategoryTitle: Font {
        isPhone ? .headline.weight(.semibold) : .title2.weight(.semibold)
    }

    static var conceptCategoryCount: Font {
        isPhone ? .subheadline : .headline
    }

    static var conceptSkillTitle: Font { .body.weight(.medium) }
    static var conceptSkillCount: Font { .body.weight(.semibold) }
    static var conceptPrimaryButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }

    static var continueCardTitle: Font {
        isPhone ? .headline.weight(.semibold) : .title2.weight(.semibold)
    }

    static var continueCardMeta: Font { .body.weight(.medium) }
    static var continueResumeButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }

    static var practiceAllSidebarCount: Font {
        isPhone ? .system(size: 28, weight: .bold) : .system(size: 32, weight: .bold)
    }

    static var practiceAllSidebarLabel: Font {
        isPhone ? .subheadline : .headline
    }

    static var practiceAllSidebarButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }

    /// Large numeric stats (monospaced digits only).
    static var statFont: Font {
        .system(.title, design: .rounded).weight(.bold)
    }

    static var statDigitFont: Font {
        .title.weight(.bold).monospacedDigit()
    }

    static var questionIdFont: Font {
        .caption2.monospaced()
    }
}
