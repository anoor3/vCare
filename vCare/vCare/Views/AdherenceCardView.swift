import SwiftUI

struct AdherenceCardView: View {
    let metric: AdherenceMetric
    let trendDelta: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Medication Adherence")
                    .font(.headline)
                Spacer()
                Image(systemName: "pills.fill")
                    .foregroundColor(.purple)
            }

            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: min(metric.percent, 1))
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(metric.percentDisplay)
                        .font(.title3).bold()
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Taken: \(metric.taken)")
                    Text("Missed: \(metric.missed)")
                    Text("Upcoming: \(metric.upcoming)")
                        .foregroundColor(.secondary)
                    Text(String(format: "Change vs prior: %@%.0f%%", trendDelta >= 0 ? "+" : "", trendDelta * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Upcoming doses aren’t counted as missed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }
}
