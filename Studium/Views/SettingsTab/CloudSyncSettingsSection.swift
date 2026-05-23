//
//  CloudSyncSettingsSection.swift
//  Studium
//

import SwiftUI

struct CloudSyncSettingsSection: View {
    @ObservedObject private var cloud = StudiumCloudSyncService.shared
    @State private var password = ""
    @FocusState private var passwordFocused: Bool

    var body: some View {
        Group {
            if !cloud.isConfigured {
                Text("Add StudiumSync.plist (copy from StudiumSync.plist.example) with your Supabase URL and key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if cloud.isActive {
                HStack(spacing: 8) {
                    Image(systemName: cloud.isSyncing ? "arrow.triangle.2.circlepath" : "icloud.fill")
                        .foregroundStyle(Color.accentColor)
                    if let synced = cloud.lastSyncedAt {
                        Text("Last synced \(synced.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(cloud.isSyncing ? "Syncing…" : "Connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let err = cloud.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    Task { await cloud.pullAndMerge() }
                } label: {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                }
                .disabled(cloud.isSyncing)
                Button(role: .destructive) {
                    cloud.signOut()
                } label: {
                    Label("Disconnect", systemImage: "icloud.slash")
                }
            } else {
                SecureField("Sync password", text: $password)
                    .textContentType(.password)
                    .focused($passwordFocused)
                Button {
                    Task {
                        let ok = await cloud.unlock(password: password)
                        if ok { password = "" }
                    }
                } label: {
                    Text(cloud.isSyncing ? "Connecting…" : "Enable Cloud Sync")
                }
                .disabled(password.isEmpty || cloud.isSyncing)
                if let err = cloud.lastError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text("Uses the same Supabase backup as studium-web. Enter your sync password once.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
