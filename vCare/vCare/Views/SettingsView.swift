import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var activeSheet: SettingsSheet?

    var body: some View {
        NavigationStack {
            Form {
                if AppFeatures.familyPortalEnabled {
                    SettingsPortalSectionView(openShare: { activeSheet = .share }, openJoin: { activeSheet = .join })
                } else {
                    Text("Family portal sharing is currently unavailable.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .share:
                PortalShareView().environment(\.managedObjectContext, context)
            case .join:
                PortalJoinView()
            }
        }
    }
}

private enum SettingsSheet: Identifiable {
    case share, join
    var id: Int { hashValue }
}
