//
//  AccountToolbarButton.swift
//  Studium
//

import SwiftUI
import FirebaseAuth

struct AccountToolbarButton: View {
  @ObservedObject var authManager: StudiumAuthManager
  @ObservedObject var syncService: StudiumCloudSyncService

  @State private var busy = false
  #if os(macOS)
  @State private var showAccountPopover = false
  #endif

  #if os(macOS)
  private let iconSize: CGFloat = 22
  #else
  private let iconSize: CGFloat = 28
  #endif

  var body: some View {
    #if os(macOS)
    macToolbarControl
    #else
    Menu {
      accountMenuContent
    } label: {
      accountIcon
    }
    .accessibilityLabel(accessibilityTitle)
    #endif
  }

  #if os(macOS)
  private var macToolbarControl: some View {
    Button {
      showAccountPopover.toggle()
    } label: {
      accountIcon
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showAccountPopover, arrowEdge: .bottom) {
      accountMenuContent
        .frame(minWidth: 240)
        .padding(.vertical, 6)
    }
    .accessibilityLabel(accessibilityTitle)
  }
  #endif

  @ViewBuilder
  private var accountMenuContent: some View {
    #if os(macOS)
    macAccountMenuContent
    #else
    iosAccountMenuContent
    #endif
  }

  #if os(macOS)
  @ViewBuilder
  private var macAccountMenuContent: some View {
  VStack(alignment: .leading, spacing: 0) {
    if let user = authManager.user {
      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName ?? user.email ?? "Signed in")
          .font(.headline)
        if let email = user.email {
          Text(email)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      Divider()
    }

    if authManager.user != nil {
      if let error = syncService.errorMessage, syncService.status == .error {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
          .padding(.horizontal, 12)
          .padding(.bottom, 6)
      }

      Button {
        showAccountPopover = false
        Task { await authManager.syncNow() }
      } label: {
        Label(syncMenuTitle, systemImage: "icloud")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .disabled(syncService.status == .syncing)

      Divider()

      Button(role: .destructive) {
        showAccountPopover = false
        authManager.signOut()
      } label: {
        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    } else {
      Button {
        busy = true
        showAccountPopover = false
        Task {
          await authManager.signInWithGoogle()
          busy = false
        }
      } label: {
        Label("Sign in with Google", systemImage: "person.crop.circle")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .disabled(busy || authManager.isLoading)
    }
  }
  }
  #endif

  @ViewBuilder
  private var iosAccountMenuContent: some View {
    if authManager.user != nil {
      if let user = authManager.user {
        Section {
          Text(user.displayName ?? user.email ?? "Signed in")
          if let email = user.email {
            Text(email)
          }
        }
      }
      Button {
        Task { await authManager.syncNow() }
      } label: {
        Label(syncMenuTitle, systemImage: "icloud")
      }
      .disabled(syncService.status == .syncing)

      if let error = syncService.errorMessage, syncService.status == .error {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }

      Button(role: .destructive) {
        authManager.signOut()
      } label: {
        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
      }
    } else {
      Button {
        busy = true
        Task {
          await authManager.signInWithGoogle()
          busy = false
        }
      } label: {
        Label("Sign in with Google", systemImage: "person.crop.circle")
      }
      .disabled(busy || authManager.isLoading)
    }
  }

  @ViewBuilder
  private var accountIcon: some View {
    ZStack {
      if authManager.isLoading || busy {
        ProgressView()
          .controlSize(.small)
      } else if let url = authManager.user?.photoURL {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
          default:
            fallbackPersonIcon
          }
        }
      } else {
        fallbackPersonIcon
      }
    }
    .frame(width: iconSize, height: iconSize)
    .clipped()
    .clipShape(Circle())
    .overlay(alignment: .bottomTrailing) {
      if authManager.isSignedIn, syncService.status == .synced {
        Circle()
          .fill(Color.green)
          .frame(width: max(5, iconSize * 0.32), height: max(5, iconSize * 0.32))
          .offset(x: 1, y: 1)
      }
    }
    .accessibilityHidden(true)
  }

  private var fallbackPersonIcon: some View {
    Image(systemName: "person.crop.circle.fill")
      .resizable()
      .scaledToFit()
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(.secondary)
  }

  private var accessibilityTitle: String {
    authManager.isSignedIn ? "Account" : "Sign in"
  }

  private var syncMenuTitle: String {
    switch syncService.status {
    case .syncing: "Syncing…"
    case .offline: "Offline"
    case .error: "Sync failed"
    case .synced:
      if let date = syncService.lastSyncedAt {
        "Synced \(date.formatted(date: .omitted, time: .shortened))"
      } else {
        "Synced"
      }
    case .idle: "Sync now"
    }
  }
}
