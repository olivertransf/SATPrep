//
//  HelpView.swift
//  Studium
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("Practice") {
                Label("Save & Exit keeps your quiz in Progress on the Practice tab.", systemImage: "square.and.arrow.down")
                Label("Resume saved quizzes from the Continue strip.", systemImage: "play.circle")
                Label("Filters narrow the question bank; concept cards start a focused set.", systemImage: "line.3.horizontal.decrease.circle")
            }
            Section("Quiz") {
                Label("Use the question menu (Q n/total) to jump between items.", systemImage: "list.number")
                Label("Adjust passage and question text size from the Aa toolbar button.", systemImage: "textformat.size")
                Label("Report rendering issues with the question ID shown under Q n/total.", systemImage: "number")
            }
            Section("Sync") {
                Label("Enable Cloud Sync in Settings with your sync password (same as the web app).", systemImage: "icloud")
                Label("Use Sync Now to refresh from Supabase after practicing on another device.", systemImage: "arrow.clockwise")
            }
            #if os(macOS)
            Section("Menu bar & breaks") {
                Label("The menu bar icon turns red when a screen break is due.", systemImage: "menubar.rectangle")
                Label("Optional full-screen break overlay appears after the threshold you set.", systemImage: "rectangle.inset.filled")
            }
            #endif
            Section("Shortcuts") {
                Label("Arrow keys: previous / next question", systemImage: "keyboard")
                Label("Return: submit answer (when not yet submitted)", systemImage: "return")
            }
        }
        .navigationTitle("How to Use Studium")
        .navInlineTitle()
    }
}
