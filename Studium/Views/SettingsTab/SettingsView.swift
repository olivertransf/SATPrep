//
//  SettingsView.swift
//  Studium
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject private var quizStateManager = QuizStateManager.shared
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("htmlFontSize") private var htmlFontSize: Double = 16.0

    private let accent = Color.accentColor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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

                    FilterStripSectionTitle(text: "Sync")
                    FilterFormCard(spacing: 10) {
                        Toggle("iCloud Sync", isOn: Binding(
                            get: { progressManager.isICloudSyncEnabled },
                            set: { newValue in
                                progressManager.isICloudSyncEnabled = newValue
                                quizStateManager.isICloudSyncEnabled = newValue
                            }
                        ))
                        .tint(accent)

                        if progressManager.isICloudSyncEnabled {
                            HStack(spacing: 8) {
                                Image(systemName: "icloud.fill")
                                    .foregroundStyle(accent)
                                Text("Syncing with iCloud")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                progressManager.manualSync()
                                quizStateManager.manualSync()
                            } label: {
                                Label("Sync Now", systemImage: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(accent)
                        }

                        Text("Sync progress and saved quizzes across devices. Enable iCloud for this app in Settings.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    FilterStripSectionTitle(text: "About")
                    FilterFormCard {
                        HStack {
                            Text("Version")
                                .font(.subheadline)
                            Spacer()
                            Text("1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .readableContentFrame(maxWidth: {
                    #if os(macOS)
                    LayoutMetrics.macSettingsMaxContentWidth
                    #else
                    LayoutMetrics.settingsStyleMaxContentWidth
                    #endif
                }())
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("Settings")
            .navLargeTitle()
        }
    }
}

#Preview {
    SettingsView(progressManager: .shared, questionLoader: .shared)
}
