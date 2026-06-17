//
//  StudiumApp.swift
//  Studium
//

import SwiftUI
#if os(macOS)
import AppKit
#endif
import GoogleSignIn

#if os(macOS)
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

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            _ = GIDSignIn.sharedInstance.handle(url)
        }
    }
}
#endif

@main
struct StudiumApp: App {
    @StateObject private var authManager = StudiumAuthManager.shared
    @StateObject private var syncService = StudiumCloudSyncService.shared

    init() {
        StudiumFirebaseBootstrap.configureIfNeeded()
        StudiumLegacyDataCleanup.runIfNeeded()
    }

    @AppStorage("appearanceMode") private var appearanceMode = "light"
    #if os(iOS)
    @UIApplicationDelegateAdaptor(StudiumIOSAppDelegate.self) private var iosAppDelegate
    #endif
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
                .environmentObject(authManager)
                .environmentObject(syncService)
                .environmentObject(breakMonitor)
                .onAppear { StudiumSyncLifecycle.start(authManager: authManager) }
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
                .onChange(of: breakMonitor.needsBreak) { _, needsBreak in
                    if needsBreak && menuBarFullScreenBreak {
                        BreakOverlayManager.shared.show(breakMonitor: breakMonitor)
                    }
                }
        }
        .defaultSize(width: 1100, height: 760)

        MenuBarExtra {
            MenuBarQuizView()
                .environmentObject(breakMonitor)
                .environmentObject(authManager)
                .environmentObject(syncService)
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
                .environmentObject(authManager)
                .environmentObject(syncService)
                .onAppear { StudiumSyncLifecycle.start(authManager: authManager) }
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
        #endif
    }
}
