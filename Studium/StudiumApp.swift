//
//  StudiumApp.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI
#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if NSApp.windows.contains(where: { $0.isVisible && $0.isKeyWindow }) {
            NSApp.setActivationPolicy(.regular)
        }
    }
}
#endif

@main
struct StudiumApp: App {
    // "system" | "light" | "dark"  — default follows the OS
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @Environment(\.scenePhase) private var scenePhase
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
        WindowGroup(id: "main") {
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
