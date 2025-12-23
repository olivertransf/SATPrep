//
//  StudySATApp.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

@main
struct StudySATApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
