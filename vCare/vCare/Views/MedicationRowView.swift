import SwiftUI

struct MedicationRowView: View {
    let log: MedicationLog
    var onTake: () -> Void
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.schedule?.name ?? "Medication")
                    .font(.subheadline).bold()
                Text(log.schedule?.dose ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(log.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            statusBadge
            if log.status == .upcoming || log.status == .missed {
                Button(action: onTake) {
                    Text("Take")
                        .font(.footnote).bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(isHighlighted ? Color.yellow.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }

    private var statusBadge: some View {
        Text(log.status.displayName)
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch log.status {
        case .taken: return .green
        case .upcoming: return .orange
        case .missed: return .red
        case .skipped: return .gray
        }
    }
}
