import SwiftUI

struct PortalJoinView: View {
    @State private var tokenText: String = ""
    @State private var importError: String?
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Form {
            Section(header: Text("Join a Care Portal")) {
                Text("Paste the share code provided by the patient.")
                TextEditor(text: $tokenText)
                    .frame(height: 120)
                Button("Import Snapshot") {
                    importToken()
                }
            }
            if let snapshot = appState.portalSnapshot {
                Section(header: Text("Connected")) {
                    Text("You are connected to \(snapshot.patientDisplayName)")
                    if let updated = appState.portalLastUpdated {
                        Text("Last updated: \(DateFormatter.localizedString(from: updated, dateStyle: .medium, timeStyle: .short))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button("Leave Portal") { appState.leavePortal() }
                        .foregroundColor(.red)
                }
            }
            if let error = importError {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func importToken() {
        guard let snapshot = CarePortalManager.shared.importToken(tokenText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            importError = "Unable to import snapshot."
            return
        }
        appState.enterPortal(with: snapshot)
        importError = nil
    }
}
