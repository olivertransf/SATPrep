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
  private let macToolbarOuterPadding: CGFloat = 16
  private let macToolbarIconSpacing: CGFloat = 14
  #endif

  var body: some ToolbarContent {
    #if os(macOS)
    ToolbarItemGroup(placement: .primaryAction) {
      HStack(spacing: macToolbarIconSpacing) {
        AccountToolbarButton(authManager: authManager, syncService: syncService)
          .fixedSize()
        settingsButton
          .fixedSize()
      }
      .padding(.horizontal, macToolbarOuterPadding)
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
        .frame(width: macIconSize, height: macIconSize, alignment: .center)
        .contentShape(Rectangle())
        #endif
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Settings")
  }
}
