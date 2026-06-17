//
//  HelpView.swift
//  Studium
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("Practice") {
                Label("Start from Home with Math or Reading & Writing quick-start cards.", systemImage: "house")
                Label("Save & Exit keeps your quiz on the Practice tab.", systemImage: "square.and.arrow.down")
                Label("Resume saved quizzes from Home or the Practice continue strip.", systemImage: "play.circle")
                Label("Filters narrow the question bank; concept cards start a focused set.", systemImage: "line.3.horizontal.decrease.circle")
            }
            Section("Progress") {
                Label("View accuracy and breakdowns from Home or Settings → Statistics.", systemImage: "chart.bar.fill")
            }
            Section("Quiz") {
                Label("Use the question menu (Q n/total) to jump between items.", systemImage: "list.number")
                Label("Adjust passage and question text size from the Aa toolbar button.", systemImage: "textformat.size")
                Label("Report rendering issues with the question ID shown under Q n/total.", systemImage: "number")
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
