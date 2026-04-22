//
//  StudiumApp.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

@main
struct StudiumApp: App {
    // "system" | "light" | "dark"  — default follows the OS
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @Environment(\.scenePhase) private var scenePhase
    #if os(macOS)
    @StateObject private var breakMonitor = ScreenBreakMonitor()
    @AppStorage("menuBarFullScreenBreak") private var menuBarFullScreenBreak: Bool = false
    #endif

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case "light":  return .light
        case "dark":   return .dark
        default:       return nil
        }
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredScheme)
                .environmentObject(breakMonitor)
                .onChange(of: breakMonitor.needsBreak) { _, needsBreak in
                    if needsBreak && menuBarFullScreenBreak {
                        BreakOverlayManager.shared.show(breakMonitor: breakMonitor)
                    }
                }
        }
        .defaultSize(width: 1100, height: 760)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { syncAllManagers() }
        }

        MenuBarExtra {
            MenuBarQuizView()
                .environmentObject(breakMonitor)
        } label: {
            Image(systemName: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(breakMonitor.needsBreak ? Color.red : Color.green)
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredScheme)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { syncAllManagers() }
        }
        #endif
    }

    private func syncAllManagers() {
        ProgressManager.shared.manualSync()
        QuizStateManager.shared.manualSync()
        VocabBucketStore.shared.manualSync()
    }
}
