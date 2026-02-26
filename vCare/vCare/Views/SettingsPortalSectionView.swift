import SwiftUI

struct SettingsPortalSectionView: View {
    @ObservedObject private var appState = AppState.shared
    var openShare: () -> Void
    var openJoin: () -> Void

    var body: some View {
        Group {
            if AppFeatures.familyPortalEnabled {
                Section(header: Text("Family Care Portal")) {
                    if appState.role == .owner {
                        Text("Share a private snapshot of your care history with trusted family members.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Generate Share Code", action: openShare)
                    } else {
                        Text("Connected to \(appState.portalPatientName)")
                        if let updated = appState.portalLastUpdated {
                            Text("Last updated: \(DateFormatter.localizedString(from: updated, dateStyle: .medium, timeStyle: .short))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("Request New Snapshot", action: openJoin)
                        Button("Leave Portal") {
                            appState.leavePortal()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
