import SwiftUI

struct CareStatusCardView: View {
    let level: CareStatusLevel

    private var color: Color {
        switch level {
        case .stable: return .green
        case .monitor: return .yellow
        case .attention: return .red
        }
    }

    private var icon: String {
        switch level {
        case .stable: return "checkmark.circle.fill"
        case .monitor: return "exclamationmark.circle.fill"
        case .attention: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(.headline)
                Text(level.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }
}
