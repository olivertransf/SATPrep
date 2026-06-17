//
//  StudiumUIComponents.swift
//  Studium
//

import SwiftUI

// MARK: - Screen

struct StudiumScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemGroupedBackground)
    }
}

// MARK: - Section header

struct StudiumSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingXS) {
                Text(title)
                    .font(StudiumDesignSystem.browsePageTitle)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(StudiumDesignSystem.browsePageSubtitle)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: StudiumDesignSystem.spacingSM)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Buttons

struct StudiumPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                if let systemImage {
                    Image(systemName: systemImage)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(StudiumDesignSystem.primaryCTAControlSize)
        .disabled(isDisabled)
    }
}

struct StudiumSecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(StudiumDesignSystem.primaryCTAControlSize)
    }
}

// MARK: - Empty state

struct StudiumEmptyState: View {
    let title: String
    var message: String? = nil
    var systemImage: String = "tray"
    var primaryActionTitle: String? = nil
    var primaryAction: (() -> Void)? = nil
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: StudiumDesignSystem.spacingLG) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            VStack(spacing: StudiumDesignSystem.spacingSM) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            VStack(spacing: StudiumDesignSystem.spacingSM) {
                if let primaryActionTitle, let primaryAction {
                    StudiumPrimaryButton(title: primaryActionTitle, action: primaryAction)
                        .frame(maxWidth: 280)
                }
                if let secondaryActionTitle, let secondaryAction {
                    StudiumSecondaryButton(title: secondaryActionTitle, action: secondaryAction)
                }
            }
        }
        .padding(StudiumDesignSystem.spacingXL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Form row

struct StudiumFormRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            Text(label)
                .font(.subheadline.weight(.medium))
            content()
        }
    }
}

// MARK: - Progress bar

struct StudiumProgressBar: View {
    let fraction: Double
    var tint: Color = .accentColor

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.systemGray5)
                Rectangle()
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

// MARK: - Quiz bottom bar (iPhone)

struct QuizBottomBar: View {
    let canGoPrevious: Bool
    let canGoNext: Bool
    let showSubmit: Bool
    let onPrevious: () -> Void
    let onSubmit: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: StudiumDesignSystem.spacingMD) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .frame(minWidth: StudiumDesignSystem.minTapTarget, minHeight: StudiumDesignSystem.minTapTarget)
            }
            .buttonStyle(.bordered)
            .disabled(!canGoPrevious)
            .accessibilityLabel("Previous question")

            if showSubmit {
                Button(action: onSubmit) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: StudiumDesignSystem.minTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Submit answer")
            }

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .frame(minWidth: StudiumDesignSystem.minTapTarget, minHeight: StudiumDesignSystem.minTapTarget)
            }
            .buttonStyle(.bordered)
            .disabled(!canGoNext && showSubmit)
            .accessibilityLabel("Next question")
        }
        .padding(.horizontal, StudiumDesignSystem.spacingLG)
        .padding(.vertical, StudiumDesignSystem.spacingSM)
        .background(Color.systemBackground)
    }
}

// MARK: - Card chrome

private struct StudiumElevatedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let padding: CGFloat
    let cornerRadius: CGFloat
    let showsShadow: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.studiumSeparator.opacity(colorScheme == .dark ? 0.55 : 0.85), lineWidth: 0.5)
            )
            .shadow(
                color: showsShadow ? FilterStyle.elevatedShadowColor(colorScheme: colorScheme) : .clear,
                radius: 3,
                y: 1
            )
    }
}

extension View {
    /// Standard raised card on `systemGroupedBackground` (Settings-style).
    func studiumElevatedCard(
        padding: CGFloat = StudiumDesignSystem.spacingLG,
        cornerRadius: CGFloat = StudiumDesignSystem.radiusCard,
        showsShadow: Bool = true
    ) -> some View {
        modifier(StudiumElevatedCardModifier(padding: padding, cornerRadius: cornerRadius, showsShadow: showsShadow))
    }

    /// Inset search / text field chrome used on Reference and similar screens.
    func studiumInsetField(cornerRadius: CGFloat = 10) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.tertiarySystemFill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.studiumSeparator.opacity(0.45), lineWidth: 0.5)
            )
    }
    /// Subtle upward shadow for sticky footers on grouped backgrounds.
    func studiumTopEdgeShadow() -> some View {
        modifier(StudiumTopEdgeShadowModifier())
    }
}

private struct StudiumTopEdgeShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: FilterStyle.elevatedShadowColor(colorScheme: colorScheme),
            radius: 6,
            y: -2
        )
    }
}

// MARK: - Icon badge

struct StudiumIconBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemImage: String
    let tint: Color
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 10

    var body: some View {
        Image(systemName: systemImage)
            .font(size >= 44 ? .title2 : .title3)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(FilterStyle.iconBadgeFill(tint: tint, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Bundle version (moved below card chrome; version enum follows)

// MARK: - Quiz environment

private struct StudiumTextHighlightingEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var studiumTextHighlightingEnabled: Bool {
        get { self[StudiumTextHighlightingEnabledKey.self] }
        set { self[StudiumTextHighlightingEnabledKey.self] = newValue }
    }
}

/// Passage, stem, or explanation block with a native inset panel around HTML.
struct QuizReadingBlock: View {
    @Environment(\.studiumTextHighlightingEnabled) private var textHighlightingEnabled

    let title: String
    let systemImage: String
    let html: String
    var fontSizeOverride: CGFloat?
    var profile: HTMLContentProfile = .quizFigures
    var compactHTML: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: StudiumDesignSystem.spacingSM) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HTMLContentView(
                htmlContent: html,
                isScrollable: false,
                allowInteraction: textHighlightingEnabled,
                compact: compactHTML,
                fontSizeOverride: fontSizeOverride,
                contentProfile: profile,
                embedded: true,
                textHighlightingEnabled: textHighlightingEnabled
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(StudiumDesignSystem.spacingMD)
            .background(Color.tertiarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

enum StudiumAppInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var versionLabel: String {
        "\(shortVersion) (\(buildNumber))"
    }
}
