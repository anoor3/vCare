import SwiftUI
import UIKit

struct MedicationRowView: View {
    let log: MedicationLog
    var onTake: () -> Void
    var onUndo: (() -> Void)? = nil
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView
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
            } else if (log.status == .taken || log.status == .skipped), let onUndo {
                Button(action: onUndo) {
                    Text("Undo")
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

    private var iconView: some View {
        Group {
            if let photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
            } else if let symbol = log.schedule?.iconSymbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            } else {
                Text(initialLetter)
                    .font(.subheadline).bold()
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .background(photoImage == nil ? Color(.secondarySystemBackground) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var initialLetter: String {
        guard let name = log.schedule?.name, let first = name.first else { return "M" }
        return String(first).uppercased()
    }

    private var photoImage: UIImage? {
        guard let data = log.schedule?.photoData else { return nil }
        return UIImage(data: data)
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
