//
//  StudiumAuthManager.swift
//  Studium
//

import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import GoogleSignIn

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class StudiumAuthManager: ObservableObject {
  static let shared = StudiumAuthManager()

  @Published private(set) var user: User?
  @Published private(set) var isLoading = true
  @Published var errorMessage: String?

  private var authListener: AuthStateDidChangeListenerHandle?

  private init() {
    authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      Task { @MainActor in
        self?.user = user
        self?.isLoading = false
        StudiumCloudSyncService.shared.setUser(uid: user?.uid)
        if let user {
          await StudiumCloudSyncService.shared.pullAndMerge(uid: user.uid)
          await self?.upsertUserProfile(user)
        }
      }
    }
  }

  var isSignedIn: Bool { user != nil }

  func signInWithGoogle() async {
    errorMessage = nil
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      errorMessage = "Firebase is not configured."
      return
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

    #if os(iOS)
    guard let presenter = StudiumPlatformPresentation.rootViewController() else {
      errorMessage = "Could not present sign-in."
      return
    }
    #elseif os(macOS)
    guard let presenter = StudiumPlatformPresentation.rootWindow() else {
      errorMessage = "Could not present sign-in."
      return
    }
    #endif

    do {
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
      guard let idToken = result.user.idToken?.tokenString else {
        errorMessage = "Missing Google ID token."
        return
      }
      let accessToken = result.user.accessToken.tokenString
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
      _ = try await Auth.auth().signIn(with: credential)
    } catch {
      let ns = error as NSError
      if ns.domain == GIDSignInError.errorDomain, ns.code == GIDSignInError.canceled.rawValue {
        return
      }
      if let reason = ns.userInfo[NSLocalizedFailureReasonErrorKey] as? String, !reason.isEmpty {
        errorMessage = reason
      } else {
        errorMessage = error.localizedDescription
      }
    }
  }

  func signOut() {
    errorMessage = nil
    do {
      try Auth.auth().signOut()
      GIDSignIn.sharedInstance.signOut()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func syncNow() async {
    guard let uid = user?.uid else { return }
    StudiumCloudSyncService.shared.setUser(uid: uid)
    await StudiumCloudSyncService.shared.flush()
  }

  private func upsertUserProfile(_ user: User) async {
    let ref = Firestore.firestore().collection("users").document(user.uid)
    let now = FieldValue.serverTimestamp()
    do {
      let snap = try await ref.getDocument()
      var fields: [String: Any] = [
        "email": user.email as Any,
        "displayName": user.displayName as Any,
        "photoURL": user.photoURL?.absoluteString as Any,
        "updatedAt": now,
        "lastSignInAt": now,
      ]
      if !snap.exists {
        fields["createdAt"] = now
      }
      try await ref.setData(fields, merge: true)
    } catch {
      // Profile upsert failure should not block study flow.
    }
  }
}
