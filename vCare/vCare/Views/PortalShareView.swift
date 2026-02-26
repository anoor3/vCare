import SwiftUI
import UIKit

struct PortalShareView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var shareCode: String?
    @State private var showingCopyAlert = false
    @State private var patientName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Family Care Portal")
                .font(.title2).bold()
            Text("Share a private, encrypted snapshot of your care data with trusted family members.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            TextField("Your name", text: $patientName)
                .textFieldStyle(.roundedBorder)
            Button("Generate Share Code") {
                generateCode()
            }
            .buttonStyle(.borderedProminent)

            if let code = shareCode {
                QRCodeGenerator.generate(from: code, size: 240)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 240, height: 240)
                Button("Copy Share Code") {
                    UIPasteboard.general.string = code
                    showingCopyAlert = true
                }
                Text("Last Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Anyone with this code can view your snapshot. Share only with trusted people.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .alert("Share code copied", isPresented: $showingCopyAlert) { Button("OK", role: .cancel) { } }
    }

    private func generateCode() {
        guard let code = CarePortalManager.shared.generateShareToken(context: context, patientName: patientName.isEmpty ? "Patient" : patientName) else { return }
        shareCode = code
    }
}
