import SwiftUI

struct MedicationRowView: View {
    let log: MedicationLog
    var countdownText: String
    var onTake: () -> Void
    var onSkip: () -> Void
    var onUndoSkip: () -> Void
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "pills.fill").foregroundColor(.accentColor))

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
                if !countdownText.isEmpty {
                    Text(countdownText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
            }

            if canInteract {
                HStack(spacing: 10) {
                    actionButton(title: "Take", icon: "checkmark", color: .green, action: onTake)
                    actionButton(title: "Skip", icon: "pause", color: .orange, action: onSkip)
                }
            } else if log.status == .taken {
                Label("Taken", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if log.status == .skipped {
                HStack {
                    Text("Marked as skipped")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Undo") { onUndoSkip() }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isHighlighted ? Color.accentColor.opacity(0.4) : Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
        .accessibilityElement(children: .combine)
    }

    private var canInteract: Bool {
        log.status == .upcoming || log.status == .missed
    }

    private var statusBadge: some View {
        Text(log.status.displayName)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
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

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
