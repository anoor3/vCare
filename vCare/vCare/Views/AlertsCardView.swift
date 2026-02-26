import SwiftUI

struct AlertsCardView: View {
    let flags: [InsightFlag]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alerts")
                    .font(.headline)
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }

            if flags.isEmpty {
                Text("No alerts. Metrics are within expected ranges.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(flags) { flag in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flag.title)
                            .font(.subheadline).bold()
                        Text(flag.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundColor(for: flag))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }

    private func backgroundColor(for flag: InsightFlag) -> Color {
        switch flag.severity {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.15)
        case .critical: return Color.red.opacity(0.15)
        }
    }
}
