import Charts
import SwiftUI

struct MoodTrendCardView: View {
    let series: [DayMetric]
    let average: Double
    let delta: Double
    var trend: TrendDirection = .stable

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Mood Trend")
                        .font(.headline)
                    Text(String(format: "%@ • Avg %.1f (%@%.1f)", trend.label, average, delta >= 0 ? "+" : "", delta))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "face.smiling")
                    .foregroundColor(.orange)
            }

            Chart {
                ForEach(series) { metric in
                    if let value = metric.value {
                        LineMark(
                            x: .value("Date", metric.date),
                            y: .value("Mood", value)
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", metric.date),
                            y: .value("Mood", value)
                        )
                        .symbolSize(40)
                    }
                }
            }
            .chartYScale(domain: 1...5)
            .frame(height: 180)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }
}
