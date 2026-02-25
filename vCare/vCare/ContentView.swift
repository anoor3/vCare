//
//  ContentView.swift
//  vCare
//
//  Created by Abdullah Noor on 2/24/26.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case medications
    case insights
    case reset
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(context: context, selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                MedicationView(context: context)
            }
            .tabItem {
                Label("Medications", systemImage: "pills.fill")
            }
            .tag(AppTab.medications)

            NavigationStack {
                InsightsView(context: context)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.insights)

            NavigationStack {
                ResetView()
            }
            .tabItem {
                Label("Calm", systemImage: "wind")
            }
            .tag(AppTab.reset)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
