import SwiftUI

struct NextDoseHeroCard: View {
    let log: MedicationLog
    var countdownText: String
    var onTake: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Next Dose")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(log.schedule?.name ?? "Medication")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text(log.schedule?.dose ?? "")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(log.scheduledTime.formatted(date: .omitted, time: .shortened))
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(countdownText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Button(action: onTake) {
                Text("Take Next Dose")
                    .font(.headline).bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .background(
            LinearGradient(colors: [Color(red: 0.58, green: 0.84, blue: 0.99),
                                    Color(red: 0.25, green: 0.58, blue: 0.97)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
    }
}
