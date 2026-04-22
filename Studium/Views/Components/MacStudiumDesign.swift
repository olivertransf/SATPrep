//
//  MacStudiumDesign.swift
//  Studium
//
//  Shared typography, spacing, and layout tokens for iOS, iPadOS, and macOS.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Visual design constants for Studium on every platform.
enum MacStudiumDesign {

    #if os(iOS)
    private static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    private static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    #else
    private static var isPhone: Bool { false }
    private static var isPad: Bool { false }
    #endif

    /// Inner padding for the Practice filter column (tighter than general sidebar chrome).
    static var practiceSidebarFilterPadding: CGFloat {
        if isPhone { return 10 }
        if isPad { return 12 }
        return 14
    }

    // MARK: - Practice shell

    static let practiceSidebarWidth: CGFloat = 312
    /// Slightly wider filter column in iPad `NavigationSplitView` sidebars.
    static let practiceSidebarWidthIPad: CGFloat = 340
    static var practiceSidebarPadding: CGFloat { isPhone ? 12 : 16 }
    static var practiceMainPaddingH: CGFloat { isPhone ? 16 : 24 }
    static var practiceMainPaddingTop: CGFloat { isPhone ? 10 : 20 }
    static var practiceMainPaddingBottom: CGFloat { isPhone ? 18 : 28 }
    static var practiceMainSectionSpacing: CGFloat { isPhone ? 14 : 22 }
    static var practiceSidebarSectionSpacing: CGFloat { isPhone ? 12 : 16 }
    static var conceptGridSpacing: CGFloat { isPhone ? 10 : 14 }

    // MARK: - Quiz

    static var quizPanePaddingH: CGFloat { isPhone ? 16 : 24 }
    static var quizPanePaddingV: CGFloat { isPhone ? 12 : 16 }
    static var quizBlockSpacing: CGFloat { isPhone ? 14 : 18 }
    static var quizProgressHeaderPaddingH: CGFloat { isPhone ? 16 : 24 }

    // MARK: - Continue / concept cards

    static var continueCardWidth: CGFloat { isPhone ? 260 : 300 }
    static let continueCardPadding: CGFloat = 16
    static let continueCardSpacing: CGFloat = 10

    static let conceptCardCorner: CGFloat = 14
    static var conceptCardPaddingH: CGFloat { isPhone ? 14 : 18 }
    static var conceptCardHeaderTop: CGFloat { isPhone ? 12 : 16 }
    static var conceptCardHeaderBottom: CGFloat { isPhone ? 8 : 12 }
    static var conceptCardHeaderMinHeight: CGFloat { isPhone ? 56 : 72 }
    static var conceptSkillRowVPadding: CGFloat { isPhone ? 10 : 12 }
    static var conceptFooterPadding: CGFloat { isPhone ? 12 : 16 }
    static var conceptPracticeButtonVPadding: CGFloat { isPhone ? 10 : 12 }

    // MARK: - Filter controls (sidebar)

    static var filterChipMinHeight: CGFloat { isPhone ? 38 : 42 }
    static var filterChipHPadding: CGFloat { isPhone ? 10 : 12 }
    static var filterChipVPadding: CGFloat { isPhone ? 7 : 8 }
    static var orderChoiceMinHeight: CGFloat { isPhone ? 48 : 54 }
    static var orderChoicePaddingH: CGFloat { isPhone ? 10 : 12 }
    static var orderChoicePaddingV: CGFloat { isPhone ? 8 : 10 }

    // MARK: - Primary actions

    static var primaryCTAControlSize: ControlSize {
        #if os(iOS)
        isPhone ? .regular : .large
        #else
        .large
        #endif
    }

    // MARK: - Typography (macOS / iPad use larger hierarchy than iPhone)

    static var sectionEyebrow: Font {
        isPhone ? .footnote.weight(.semibold) : .subheadline.weight(.semibold)
    }

    static var browsePageTitle: Font {
        isPhone
            ? .system(.title2, design: .monospaced).weight(.bold)
            : .system(.largeTitle, design: .monospaced).weight(.bold)
    }

    static var browsePageSubtitle: Font {
        isPhone
            ? .system(.subheadline, design: .monospaced).weight(.regular)
            : .system(.title3, design: .monospaced).weight(.regular)
    }

    static var sidebarGroupTitle: Font { .system(.headline, design: .monospaced).weight(.semibold) }
    static var conceptCategoryTitle: Font {
        isPhone
            ? .system(.headline, design: .monospaced).weight(.semibold)
            : .system(.title2, design: .monospaced).weight(.semibold)
    }

    static var conceptCategoryCount: Font {
        isPhone
            ? .system(.subheadline, design: .monospaced).weight(.regular)
            : .system(.headline, design: .monospaced).weight(.regular)
    }

    static var conceptSkillTitle: Font { .system(.body, design: .monospaced).weight(.medium) }
    static var conceptSkillCount: Font { .system(.body, design: .monospaced).weight(.semibold) }
    static var conceptPrimaryButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }

    static var continueCardTitle: Font {
        isPhone
            ? .system(.headline, design: .monospaced).weight(.semibold)
            : .system(.title2, design: .monospaced).weight(.semibold)
    }

    static var continueCardMeta: Font { .system(.body, design: .monospaced).weight(.medium) }

    static var continueResumeButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }
    static var practiceAllSidebarCount: Font {
        isPhone
            ? .system(size: 28, weight: .bold, design: .monospaced)
            : .system(size: 32, weight: .bold, design: .monospaced)
    }

    static var practiceAllSidebarLabel: Font {
        isPhone
            ? .system(.subheadline, design: .monospaced).weight(.regular)
            : .system(.headline, design: .monospaced).weight(.regular)
    }

    static var practiceAllSidebarButton: Font {
        isPhone ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
    }
}
