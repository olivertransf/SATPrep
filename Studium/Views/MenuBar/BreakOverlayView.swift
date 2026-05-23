//
//  BreakOverlayView.swift
//  Studium
//

#if os(macOS)
import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var viewModel: BreakOverlayViewModel
    @AppStorage("menuBarFontSize") private var menuBarFontSize: Double = 14.0

    /// Answer submitted — record break + hide.
    let onSubmitAndDismiss: () -> Void
    /// X button / double-click outside — just hide.
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // minLength matches the X-button zone (20 padding + 36 button + 20 padding)
                // so top and bottom breathing room appear equal
                Spacer(minLength: 76)
                if let q = viewModel.question {
                    questionCard(for: q)
                        .frame(maxWidth: 740)
                        .padding(.horizontal, 24)
                        .onTapGesture(count: 2) {}
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
                Spacer(minLength: 76)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // X close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .padding(20)
            .help("Close overlay")
            .onTapGesture(count: 2) {}
        }
        // Double-tap anywhere outside the card dismisses without recording
        .onTapGesture(count: 2) { onClose() }
    }

    // MARK: Question card

    @ViewBuilder
    private func questionCard(for q: Question) -> some View {
        VStack(spacing: 0) {
            MenuBarWebView(
                html: buildQuestionHTML(for: q, fontSize: menuBarFontSize + 2),
                selectedOptionId: Binding(
                    get: { viewModel.selectedOptionId },
                    set: { viewModel.selectedOptionId = $0 }
                ),
                revealCorrectId: viewModel.submitted ? viewModel.resolvedCorrectOptionId() : nil,
                revealSelectedId: viewModel.submitted ? viewModel.selectedOptionId : nil
            )
            .frame(maxWidth: .infinity, minHeight: 340)

            Divider()

            if viewModel.submitted {
                submittedFooter
            } else {
                pendingFooter
            }
        }
        .background(Color.systemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.45), radius: 32, y: 12)
    }

    private var submittedFooter: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(viewModel.isCorrect ? .green : .red)
                .font(.title3.weight(.semibold))
            Text(viewModel.isCorrect ? "Correct!" : "Answered.")
                .font(.callout)
            Spacer()
            Button("Dismiss") {
                onSubmitAndDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var pendingFooter: some View {
        HStack {
            Spacer()
            Button("Submit") { viewModel.submit() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.selectedOptionId == nil)
                .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
#endif
