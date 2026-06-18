//
//  SettingsView.swift
//  Studium
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: StudiumAuthManager
    @EnvironmentObject private var syncService: StudiumCloudSyncService
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject private var quizStateManager = QuizStateManager.shared
    @AppStorage("appearanceMode") private var appearanceMode = "light"
    @AppStorage("htmlFontSize") private var htmlFontSize: Double = 16.0
    @AppStorage("passageFontSize") private var passageFontSize: Double = 17.0
    @AppStorage("answerChoiceFontSize") private var answerChoiceFontSize: Double = 15.0
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    #if os(macOS)
    @EnvironmentObject private var breakMonitor: ScreenBreakMonitor
    @AppStorage("menuBarFontSize") private var menuBarFontSize: Double = 14.0
    @AppStorage("menuBarFullScreenBreak") private var menuBarFullScreenBreak: Bool = false
    @AppStorage("breakThresholdMinutes") private var breakThresholdMinutes: Int = 20
    #endif

    @State private var showResetConfirmation = false
    @State private var authBusy = false

    private let accent = Color.accentColor

    var body: some View {
        #if os(iOS)
        NavigationStack {
            Form {
                accountSection

                Section {
                    Picker("Theme", selection: $appearanceMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Question text size")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(Int(htmlFontSize)) pt")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 10) {
                            Text("A")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Slider(value: $htmlFontSize, in: 13...22, step: 1)
                                .tint(accent)
                            Text("A")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Passage text size")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(Int(passageFontSize)) pt")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $passageFontSize, in: 13...22, step: 1)
                            .tint(accent)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Answer choice text size")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(Int(answerChoiceFontSize)) pt")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $answerChoiceFontSize, in: 13...22, step: 1)
                            .tint(accent)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Appearance")
                }

                Section {
                    let attempted = progressManager.progress.values.filter { $0.correct != nil }.count
                    let seen = progressManager.progress.values.filter(\.seen).count
                    LabeledContent("Questions attempted", value: "\(attempted)")
                    LabeledContent("Questions seen", value: "\(seen)")
                    LabeledContent("Saved quizzes", value: "\(quizStateManager.savedQuizzes.count)")
                } header: {
                    Text("Your progress")
                } footer: {
                    Text(authManager.isSignedIn
                         ? "Synced to your account when signed in."
                         : "Progress is stored locally on this device.")
                }

                Section {
                    NavigationLink {
                        StatsView(progressManager: progressManager, questionLoader: questionLoader)
                    } label: {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset all progress")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text(authManager.isSignedIn
                         ? "Reset clears local data and syncs the reset to your account."
                         : "Clears question progress, saved quizzes, and vocab buckets.")
                }

                Section {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("How to Use Studium", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("Help")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(StudiumAppInfo.versionLabel)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navAdaptiveTitle()
            .toolbar { settingsCloseToolbar }
            .alert("Reset all progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    StudiumLocalDataReset.resetAll()
                }
            } message: {
                Text("This will clear all question progress, saved quizzes, and vocab buckets. This cannot be undone.")
            }
        }
        #else
        macSettingsBody
        #endif
    }

    #if os(macOS)
    @ViewBuilder
    private var macSettingsBody: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    accountMacSection

                    FilterStripSectionTitle(text: "Appearance")
                    FilterFormCard(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Theme")
                                .font(.subheadline.weight(.medium))
                            Picker("Theme", selection: $appearanceMode) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Question text size")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(Int(htmlFontSize)) pt")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 10) {
                                Text("A")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Slider(value: $htmlFontSize, in: 13...22, step: 1)
                                    .tint(accent)
                                Text("A")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Passage text size")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(Int(passageFontSize)) pt")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 10) {
                                Text("A")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Slider(value: $passageFontSize, in: 13...22, step: 1)
                                    .tint(accent)
                                Text("A")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Answer choice text size")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(Int(answerChoiceFontSize)) pt")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 10) {
                                Text("A")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Slider(value: $answerChoiceFontSize, in: 13...22, step: 1)
                                    .tint(accent)
                                Text("A")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    FilterStripSectionTitle(text: "Practice")
                    FilterFormCard {
                        NavigationLink {
                            StatsView(progressManager: progressManager, questionLoader: questionLoader)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(accent)
                                    .frame(width: 28, alignment: .center)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Statistics")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("Accuracy, breakdowns, reset progress")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    FilterStripSectionTitle(text: "Menu Bar")
                    FilterFormCard(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Question font size")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(Int(menuBarFontSize)) pt")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 10) {
                                Text("A")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Slider(value: $menuBarFontSize, in: 11...20, step: 1)
                                    .tint(accent)
                                Text("A")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Break reminder")
                                    .font(.subheadline.weight(.medium))
                                Text("Show red indicator and overlay after this many minutes.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Picker("", selection: $breakThresholdMinutes) {
                                ForEach([5, 10, 15, 20, 25, 30, 45, 60], id: \.self) { mins in
                                    Text("\(mins) min").tag(mins)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 90)
                        }

                        Divider()

                        Toggle(isOn: $menuBarFullScreenBreak) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Full-screen break overlay")
                                    .font(.subheadline.weight(.medium))
                                Text("Show a question across your whole screen after 20 minutes.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .tint(accent)

                        if menuBarFullScreenBreak {
                            Button {
                                BreakOverlayManager.shared.show(breakMonitor: breakMonitor)
                            } label: {
                                Label("Preview Overlay", systemImage: "eye")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(accent)
                        }
                    }

                    FilterStripSectionTitle(text: "Your progress")
                    FilterFormCard(spacing: 10) {
                        let attempted = progressManager.progress.values.filter { $0.correct != nil }.count
                        let seen = progressManager.progress.values.filter(\.seen).count
                        HStack {
                            Text("Questions attempted")
                                .font(.subheadline)
                            Spacer()
                            Text("\(attempted)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Questions seen")
                                .font(.subheadline)
                            Spacer()
                            Text("\(seen)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Saved quizzes")
                                .font(.subheadline)
                            Spacer()
                            Text("\(quizStateManager.savedQuizzes.count)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Text(authManager.isSignedIn
                             ? "Synced to your account when signed in."
                             : "Progress is stored locally on this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FilterStripSectionTitle(text: "Data")
                    FilterFormCard(spacing: 10) {
                        Text("Clears question progress, saved quizzes, and vocab buckets.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Text("Reset all progress")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }

                    FilterStripSectionTitle(text: "Help")
                    FilterFormCard {
                        NavigationLink {
                            HelpView()
                        } label: {
                            Label("How to Use Studium", systemImage: "questionmark.circle")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    }

                    FilterStripSectionTitle(text: "About")
                    FilterFormCard {
                        HStack {
                            Text("Version")
                                .font(.subheadline)
                            Spacer()
                            Text(StudiumAppInfo.versionLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .readableContentFrame(maxWidth: LayoutMetrics.settingsReadableMaxWidth)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("Settings")
            .navLargeTitle()
            .toolbar { settingsCloseToolbar }
            .alert("Reset all progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    StudiumLocalDataReset.resetAll()
                }
            } message: {
                Text("This will clear all question progress, saved quizzes, and vocab buckets. This cannot be undone.")
            }
        }
    }
    #endif

    @ToolbarContentBuilder
    private var settingsCloseToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section {
            if authManager.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading account…")
                        .foregroundStyle(.secondary)
                }
            } else if let user = authManager.user {
                LabeledContent("Signed in", value: user.displayName ?? user.email ?? "Account")
                if let email = user.email, user.displayName != nil {
                    LabeledContent("Email", value: email)
                }
                if authManager.isSignedIn {
                    LabeledContent("Cloud sync", value: syncStatusLabel)
                    Button {
                        Task { await authManager.syncNow() }
                    } label: {
                        Label("Sync now", systemImage: "icloud")
                    }
                    .disabled(syncService.status == .syncing)
                }
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    Text("Sign out")
                }
            } else {
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    authBusy = true
                    Task {
                        await authManager.signInWithGoogle()
                        authBusy = false
                    }
                } label: {
                    Label("Sign in with Google", systemImage: "person.crop.circle")
                }
                .disabled(authBusy)
            }
        } header: {
            Text("Account")
        } footer: {
            Text(authManager.isSignedIn
                 ? "Progress syncs across web, iPhone, iPad, and Mac."
                 : "Sign in to sync progress across devices.")
        }
    }

    #if os(macOS)
    @ViewBuilder
    private var accountMacSection: some View {
        FilterStripSectionTitle(text: "Account")
        FilterFormCard(spacing: 12) {
            if authManager.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading account…")
                        .foregroundStyle(.secondary)
                }
            } else if let user = authManager.user {
                HStack {
                    Text("Signed in")
                        .font(.subheadline)
                    Spacer()
                    Text(user.displayName ?? user.email ?? "Account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if authManager.isSignedIn {
                    HStack {
                        Text("Cloud sync")
                            .font(.subheadline)
                        Spacer()
                        Text(syncStatusLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await authManager.syncNow() }
                    } label: {
                        Label("Sync now", systemImage: "icloud")
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncService.status == .syncing)
                }
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    Text("Sign out")
                }
                .buttonStyle(.plain)
            } else {
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    authBusy = true
                    Task {
                        await authManager.signInWithGoogle()
                        authBusy = false
                    }
                } label: {
                    Label("Sign in with Google", systemImage: "person.crop.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(authBusy)
            }
            Text(authManager.isSignedIn
                 ? "Progress syncs across web, iPhone, iPad, and Mac."
                 : "Sign in to sync progress across devices.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private var syncStatusLabel: String {
        switch syncService.status {
        case .syncing: "Syncing…"
        case .offline: "Offline"
        case .error: "Sync failed"
        case .synced:
            if let date = syncService.lastSyncedAt {
                "Synced \(date.formatted(date: .omitted, time: .shortened))"
            } else {
                "Synced"
            }
        case .idle: "Ready"
        }
    }
}

#Preview {
    SettingsView(progressManager: .shared, questionLoader: .shared)
        .environmentObject(StudiumAuthManager.shared)
        .environmentObject(StudiumCloudSyncService.shared)
}
