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

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case "light":  return .light
        case "dark":   return .dark
        default:       return nil   // system
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredScheme)
        }
    }
}
