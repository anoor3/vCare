import SwiftUI

struct PortalStatusBannerView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        if appState.role == .caregiverPortal {
            HStack {
                Image(systemName: "lock.fill")
                VStack(alignment: .leading) {
                    Text("Read-Only Portal Mode")
                        .font(.headline)
                    Text("Connected to \(appState.portalPatientName)")
                        .font(.caption)
                }
                Spacer()
            }
            .padding()
            .background(Color.yellow.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
        }
    }
}
