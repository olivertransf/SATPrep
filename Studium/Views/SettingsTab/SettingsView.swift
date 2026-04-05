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

    private let accent = Color.accentColor

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FilterStripSectionTitle(text: "Appearance")
                    FilterFormCard {
                        Picker("Theme", selection: $appearanceMode) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
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
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView(progressManager: .shared, questionLoader: .shared)
}
