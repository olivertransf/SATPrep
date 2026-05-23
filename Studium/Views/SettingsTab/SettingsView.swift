//
//  SettingsView.swift
//  Studium
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var progressManager: ProgressManager
    @ObservedObject var questionLoader: QuestionLoader
    @ObservedObject private var quizStateManager = QuizStateManager.shared
    @ObservedObject private var vocabBucketStore = VocabBucketStore.shared
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @AppStorage("htmlFontSize") private var htmlFontSize: Double = 16.0
    @AppStorage("passageFontSize") private var passageFontSize: Double = 17.0
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    #if os(macOS)
    @EnvironmentObject private var breakMonitor: ScreenBreakMonitor
    @AppStorage("menuBarFontSize") private var menuBarFontSize: Double = 14.0
    @AppStorage("menuBarFullScreenBreak") private var menuBarFullScreenBreak: Bool = false
    @AppStorage("breakThresholdMinutes") private var breakThresholdMinutes: Int = 20
    #endif

    private let accent = Color.accentColor

    var body: some View {
        #if os(iOS)
        NavigationStack {
            Form {
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
                } header: {
                    Text("Appearance")
                }

                Section {
                    CloudSyncSettingsSection()
                } header: {
                    Text("Cloud sync")
                } footer: {
                    Text("Progress, quizzes, and vocab sync to Supabase (same as the web app).")
                }

                Section {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("How to Use Studium", systemImage: "questionmark.circle")
                    }
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

                    FilterStripSectionTitle(text: "Cloud sync")
                    FilterFormCard(spacing: 10) {
                        CloudSyncSettingsSection()
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
        }
    }
    #endif
}

#Preview {
    SettingsView(progressManager: .shared, questionLoader: .shared)
}
