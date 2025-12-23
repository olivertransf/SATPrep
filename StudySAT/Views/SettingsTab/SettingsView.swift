//
//  SettingsView.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var progressManager: ProgressManager
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("Sync"), footer: Text("Sync your progress across all your devices using iCloud. Make sure iCloud is enabled in your device settings and the app has iCloud capability enabled in Xcode.")) {
                    Toggle("iCloud Sync", isOn: $progressManager.isICloudSyncEnabled)
                    
                    if progressManager.isICloudSyncEnabled {
                        HStack {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                            Text("Syncing with iCloud")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            progressManager.manualSync()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Sync Now")
                            }
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

