//
//  ContentView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    private func syncIfNeeded() {
        StudiumCloudSyncService.shared.syncIfNeeded()
    }

    var body: some View {
        MainTabView()
            #if os(macOS)
            .frame(minWidth: 720, minHeight: 520)
            #endif
            .onAppear {
                syncIfNeeded()
                #if os(macOS)
                applyWindowBackground()
                #endif
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    syncIfNeeded()
                case .background:
                    Task { await StudiumCloudSyncService.shared.flushPush() }
                default:
                    break
                }
            }
            #if os(macOS)
            .onChange(of: colorScheme) { _, _ in applyWindowBackground() }
            #endif
    }

    #if os(macOS)
    private func applyWindowBackground() {
        guard let color = NSColor(named: "StudiumBg") else { return }
        for window in NSApp.windows where window.level == .normal {
            window.backgroundColor = color
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
        }
    }
    #endif
}

#Preview {
    ContentView()
}
