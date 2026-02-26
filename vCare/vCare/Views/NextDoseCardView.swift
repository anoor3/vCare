import SwiftUI
import UIKit

struct NextDoseCardView: View {
    let log: MedicationLog
    var countdownText: String
    var urgency: NextDoseUrgency
    var onMarkTaken: () -> Void

    @State private var didConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Dose")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(log.schedule?.name ?? "Medication")
                .font(.title3).bold()
            Text(log.schedule?.dose ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.subheadline)
                Spacer()
                Text(countdownText)
                    .font(.subheadline)
                    .foregroundColor(countdownColor)
            }

            Button(action: confirmTaken) {
                HStack {
                    Spacer()
                    if didConfirm {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    } else {
                        Text("Mark as Taken")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .background(didConfirm ? Color.green : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .scaleEffect(didConfirm ? 0.96 : 1.0)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 8)
    }

    private var countdownColor: Color {
        switch urgency {
        case .normal: return Color.secondary
        case .warning: return .orange
        case .overdue: return .red
        }
    }

    private func confirmTaken() {
        guard !didConfirm else { return }
        didConfirm = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onMarkTaken()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                didConfirm = false
            }
        }
    }
}
