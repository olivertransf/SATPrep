//
//  ContentView.swift
//  Studium
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @EnvironmentObject private var authManager: StudiumAuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            #if os(macOS)
            .frame(minWidth: 720, minHeight: 520)
            #endif
            .onAppear {
                #if os(macOS)
                applyWindowBackground()
                #endif
            }
            #if os(macOS)
            .onChange(of: colorScheme) { _, _ in applyWindowBackground() }
            #endif
            .onChange(of: scenePhase) { _, phase in
                StudiumSyncLifecycle.onScenePhase(phase, authManager: authManager)
            }
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
        .environmentObject(StudiumAuthManager.shared)
        .environmentObject(StudiumCloudSyncService.shared)
}
