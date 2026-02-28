import SwiftUI

struct MedicationCardView: View {
    let log: MedicationLog
    var iconName: String
    var statusText: String
    var onTake: () -> Void
    var onSkip: () -> Void
    var onUndoSkip: () -> Void
    var isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: iconName).foregroundColor(.accentColor))

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.schedule?.name ?? "Medication")
                        .font(.headline)
                    Text(log.schedule?.dose ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(statusText)
                    .font(.caption).bold()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(statusColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            actionButtons
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isHighlighted ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var actionButtons: some View {
        if log.status == .upcoming || log.status == .missed {
            HStack(spacing: 10) {
                Button(action: onTake) {
                    Text("Take")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.caption).bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
        } else if log.status == .skipped {
            Button(action: onUndoSkip) {
                Text("Undo skip")
                    .font(.caption).bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    )
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        } else if log.status == .taken {
            Label("Taken", systemImage: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(.green)
        }
    }

    private var statusColor: Color {
        switch log.status {
        case .taken: return .green
        case .upcoming: return .blue
        case .missed: return .red
        case .skipped: return .orange
        }
    }

    private var backgroundColor: Color {
        switch log.status {
        case .taken: return Color.green.opacity(0.15)
        case .missed: return Color.red.opacity(0.12)
        case .skipped: return Color.orange.opacity(0.12)
        case .upcoming: return Color(.secondarySystemBackground)
        }
    }

    private var primaryGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.32, green: 0.74, blue: 0.64),
                                Color(red: 0.24, green: 0.52, blue: 0.92)],
                       startPoint: .leading,
                       endPoint: .trailing)
    }
}
