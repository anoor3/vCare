import SwiftUI

struct MedicationsSummaryCardView: View {
    var completedText: String
    var progress: Double
    var taken: Int
    var missed: Int
    var upcoming: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(completedText)
                .font(.headline)
            ProgressView(value: progress)
                .tint(Color.accentColor)
                .animation(.easeInOut(duration: 0.3), value: progress)
            Text("Adherence \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                statColumn(title: "Taken", value: taken)
                statColumn(title: "Missed", value: missed)
                statColumn(title: "Upcoming", value: upcoming)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
        )
    }

    private func statColumn(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
