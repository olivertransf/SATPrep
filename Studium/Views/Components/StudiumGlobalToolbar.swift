//
//  StudiumGlobalToolbar.swift
//  Studium
//

import SwiftUI

struct StudiumGlobalToolbar: ToolbarContent {
  @ObservedObject var authManager: StudiumAuthManager
  @ObservedObject var syncService: StudiumCloudSyncService
  var onOpenSettings: () -> Void

  #if os(macOS)
  private let macIconSize: CGFloat = 22
  private let macIconSpacing: CGFloat = 10
  #endif

  var body: some ToolbarContent {
    #if os(macOS)
    ToolbarItem(placement: .primaryAction) {
      HStack(spacing: macIconSpacing) {
        AccountToolbarButton(authManager: authManager, syncService: syncService)
        settingsButton
      }
      .frame(minWidth: macIconSize * 2 + macIconSpacing)
    }
    #else
    ToolbarItemGroup(placement: .topBarTrailing) {
      AccountToolbarButton(authManager: authManager, syncService: syncService)
      settingsButton
    }
    #endif
  }

  private var settingsButton: some View {
    Button(action: onOpenSettings) {
      Image(systemName: "gearshape")
        #if os(macOS)
        .font(.system(size: 18, weight: .regular))
        .frame(width: macIconSize, height: macIconSize)
        #endif
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Settings")
  }
}
