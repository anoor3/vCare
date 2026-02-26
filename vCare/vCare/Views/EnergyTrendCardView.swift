import Charts
import SwiftUI

struct EnergyTrendCardView: View {
    let series: [DayMetric]
    let average: Double
    let lowest: DayMetric?
    var trend: TrendDirection = .stable
    var variance: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Energy")
                        .font(.headline)
                    Text(String(format: "%@ • Avg %.0f%%", trend.label, average))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "Variance %.0f", variance))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
            }

            Chart {
                ForEach(series) { metric in
                    if let value = metric.value {
                        BarMark(
                            x: .value("Date", metric.date),
                            y: .value("Energy", value)
                        )
                        .foregroundStyle(color(for: metric))
                    }
                }
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }

    private func color(for metric: DayMetric) -> Color {
        guard let lowestDate = lowest?.date, metric.date == lowestDate else { return Color.accentColor.opacity(0.7) }
        return Color.red.opacity(0.8)
    }
}
