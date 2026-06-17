//
//  StudiumFirebaseBootstrap.swift
//  Studium
//

import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import SwiftUI

#if os(iOS)
import UIKit
#endif

enum StudiumFirebaseBootstrap {
  static func configureIfNeeded() {
    guard FirebaseApp.app() == nil else { return }
    FirebaseApp.configure()
  }
}

#if os(iOS)
final class StudiumIOSAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    StudiumFirebaseBootstrap.configureIfNeeded()
    return true
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    GIDSignIn.sharedInstance.handle(url)
  }
}
#endif

@MainActor
enum StudiumSyncLifecycle {
  static func start(authManager: StudiumAuthManager) {
    NotificationCenter.default.addObserver(
      forName: .studiumLocalDataChanged,
      object: nil,
      queue: .main
    ) { note in
      let fromSync = (note.userInfo?["fromSync"] as? Bool) == true
      guard !fromSync else { return }
      Task { @MainActor in
        guard authManager.isSignedIn else { return }
        StudiumCloudSyncService.shared.schedulePush()
      }
    }
  }

  static func onScenePhase(_ phase: ScenePhase, authManager: StudiumAuthManager) {
    switch phase {
    case .active:
      if let uid = authManager.user?.uid {
        Task { await StudiumCloudSyncService.shared.pullAndMerge(uid: uid) }
      }
    case .background:
      Task { await StudiumCloudSyncService.shared.flush() }
    default:
      break
    }
  }
}
