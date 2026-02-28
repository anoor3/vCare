
import SwiftUI

enum AppTab: Hashable {
    case home
    case medications
    case insights
    case settings
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var appState = AppState.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView(context: context, selectedTab: $appState.selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                MedicationsView(context: context)
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

            if AppFeatures.familyPortalEnabled {
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .medicationDeepLink)) { _ in
            appState.selectedTab = .medications
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
