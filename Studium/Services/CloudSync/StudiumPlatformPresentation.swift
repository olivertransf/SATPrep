//
//  StudiumPlatformPresentation.swift
//  Studium
//

import SwiftUI

#if os(iOS)
import UIKit

enum StudiumPlatformPresentation {
  static func rootViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap(\.windows)
    let key = windows.first(where: \.isKeyWindow) ?? windows.first
    var controller = key?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
#elseif os(macOS)
import AppKit

enum StudiumPlatformPresentation {
  static func rootWindow() -> NSWindow? {
    NSApp.keyWindow ?? NSApp.windows.first
  }

  static func rootViewController() -> NSViewController? {
    rootWindow()?.contentViewController ?? NSApp.windows.first?.contentViewController
  }
}
#endif
