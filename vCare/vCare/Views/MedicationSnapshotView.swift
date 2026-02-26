
import SwiftUI

struct MedicationSnapshotView: View {
    let status: [MedicationTime: MedicationStatus]
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Medication Status")
                        .font(.title3).bold()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                ForEach(MedicationTime.allCases, id: \.self) { time in
                    let state = status[time] ?? .upcoming
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(time.title)
                                .font(.headline)
                            Text(stateText(state))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(stateColor(state))
                            .frame(width: 12, height: 12)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func stateText(_ status: MedicationStatus) -> String {
        switch status {
        case .taken: return "Taken"
        case .upcoming: return "Upcoming"
        case .missed: return "Missed"
        }
    }

    private func stateColor(_ status: MedicationStatus) -> Color {
        switch status {
        case .taken: return .green
        case .upcoming: return .orange
        case .missed: return .red
        }
    }
}
