import Foundation

struct DayMetric: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double?
    let label: String
    let isMissing: Bool
}

struct AdherenceMetric {
    let totalScheduled: Int
    let taken: Int
    let missed: Int
    let upcoming: Int

    var percent: Double {
        let denominator = max(Double(totalScheduled - upcoming), 1)
        return denominator == 0 ? 0 : Double(taken) / denominator
    }

    var percentDisplay: String {
        String(format: "%.0f%%", percent * 100)
    }
}

struct InsightFlag: Identifiable {
    enum Severity {
        case info
        case warning
        case critical

        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
    }

    let id = UUID()
    let title: String
    let detail: String
    let severity: Severity
}
