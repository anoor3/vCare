import SwiftUI

struct MedicationRowView: View {
    let log: MedicationLog
    var countdownText: String
    var onTake: () -> Void
    var onSkip: () -> Void
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "pills.fill").foregroundColor(statusColor))

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.schedule?.name ?? "Medication")
                        .font(.headline)
                    Text(log.schedule?.dose ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
                statusBadge
            }

            HStack(alignment: .center) {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(countdownText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            if canInteract {
                HStack(spacing: 12) {
                    Button(action: onTake) {
                        Label("Take", systemImage: "checkmark")
                            .font(.subheadline).bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onSkip) {
                        Label("Skip", systemImage: "forward.end")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else if log.status == .taken {
                Label("Taken", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if log.status == .skipped {
                Label("Skipped", systemImage: "arrow.uturn.left")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isHighlighted ? Color.yellow.opacity(0.6) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
    }

    private var canInteract: Bool {
        log.status == .upcoming || log.status == .missed
    }

    private var statusBadge: some View {
        Text(log.status.displayName)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch log.status {
        case .taken: return .green
        case .upcoming: return .orange
        case .missed: return .red
        case .skipped: return .gray
        }
    }
}
