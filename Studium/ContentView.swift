//
//  ContentView.swift
//  Studium
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    private func syncIfNeeded() {
        guard ProgressManager.shared.isICloudSyncEnabled else { return }
        ProgressManager.shared.manualSync()
        QuizStateManager.shared.manualSync()
    }

    var body: some View {
        MainTabView()
            #if os(macOS)
            .frame(minWidth: 720, minHeight: 520)
            #endif
            .onAppear {
                syncIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                syncIfNeeded()
            }
    }
}

#Preview {
    ContentView()
}
