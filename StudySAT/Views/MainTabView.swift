//
//  MainTabView.swift
//  StudySAT
//
//  Created by Oliver Tran on 12/23/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var questionLoader = QuestionLoader.shared
    @StateObject private var progressManager = ProgressManager.shared
    @State private var filters = FilterOptions()
    @State private var showFilters = true // Show filters first
    @State private var selectedTab = 0
    @State private var hasAppliedFilters = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var filteredQuestions: [Question] {
        questionLoader.getFilteredQuestions(filters: filters, progressManager: progressManager)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Quiz Tab
            NavigationStack {
                if !hasAppliedFilters {
                    filterFirstView
                } else {
                    QuizView(
                        questionLoader: questionLoader,
                        progressManager: progressManager,
                        questions: filteredQuestions,
                        filters: $filters,
                        showFilters: $showFilters,
                        onEndQuiz: {
                            hasAppliedFilters = false
                            filters = FilterOptions()
                        }
                    )
                }
            }
            .tabItem {
                Label("Quiz", systemImage: "questionmark.circle")
            }
            .tag(0)
            
            // Stats Tab
            StatsView(
                progressManager: progressManager,
                questionLoader: questionLoader
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(1)
            
            // Settings Tab
            SettingsView(progressManager: progressManager)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .sheet(isPresented: $showFilters) {
            FilterView(
                questionLoader: questionLoader,
                progressManager: progressManager,
                filters: $filters,
                isPresented: $showFilters,
                onApply: {
                    // Only mark filters as applied when "Start Quiz" is clicked
                    hasAppliedFilters = true
                }
            )
        }
        .onAppear {
            // Show filters immediately if not applied yet
            if !hasAppliedFilters {
                showFilters = true
            }
        }
    }
    
    private var filterFirstView: some View {
        VStack(spacing: 20) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Select Filters to Start")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Choose your filters to begin your quiz")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Filters") {
                showFilters = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

