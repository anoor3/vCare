import Combine
import CoreData
import Foundation

enum CareStatusLevel {
    case stable
    case monitor
    case attention

    var title: String {
        switch self {
        case .stable: return "Stable"
        case .monitor: return "Monitor"
        case .attention: return "Attention Needed"
        }
    }

    var detail: String {
        switch self {
        case .stable: return "Care indicators within normal range"
        case .monitor: return "Energy or mood requires attention"
        case .attention: return "Medication adherence below target"
        }
    }
}

enum TrendDirection {
    case up
    case down
    case stable

    var label: String {
        switch self {
        case .up: return "Rising"
        case .down: return "Declining"
        case .stable: return "Stable"
        }
    }
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var selectedRange: InsightsRange = .seven {
        didSet { computeInsights(range: selectedRange) }
    }
    @Published private(set) var careStatus: CareStatusLevel = .stable
    @Published private(set) var moodSeries: [DayMetric] = []
    @Published private(set) var energySeries: [DayMetric] = []
    @Published private(set) var adherence: AdherenceMetric = .init(totalScheduled: 0, taken: 0, missed: 0, upcoming: 0)
    @Published private(set) var moodAverage: Double = 0
    @Published private(set) var moodDelta: Double = 0
    @Published private(set) var moodStdDeviation: Double = 0
    @Published private(set) var moodTrend: TrendDirection = .stable
    @Published private(set) var energyAverage: Double = 0
    @Published private(set) var energyVariance: Double = 0
    @Published private(set) var energyTrend: TrendDirection = .stable
    @Published private(set) var lowestEnergyMetric: DayMetric?
    @Published private(set) var adherenceTrendDelta: Double = 0
    @Published private(set) var flags: [InsightFlag] = []
    @Published private(set) var summaryBullets: [String] = []
    @Published private(set) var missingCheckins: Int = 0
    @Published private(set) var isEmptyState: Bool = true

    private let context: NSManagedObjectContext
    private let calendar: Calendar
    private let formatter: DateFormatter
    private var cancellable: AnyCancellable?

    init(context: NSManagedObjectContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
        self.formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")

        cancellable = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.computeInsights(range: self?.selectedRange ?? .seven) }

        computeInsights(range: selectedRange)
    }

    func computeInsights(range: InsightsRange) {
        let today = dayKey(Date())
        guard let rangeStart = calendar.date(byAdding: .day, value: -(range.days - 1), to: today),
              let rangeEnd = calendar.date(byAdding: .day, value: 1, to: today),
              let previousStart = calendar.date(byAdding: .day, value: -range.days, to: rangeStart) else { return }
        let previousEnd = rangeStart

        let entries = fetchCareEntries(start: previousStart, end: rangeEnd)
        let logs = fetchMedicationLogs(start: previousStart, end: rangeEnd)

        let entriesByDay = Dictionary(grouping: entries, by: { dayKey($0.date) })
        let logsByDay = Dictionary(grouping: logs, by: { dayKey($0.scheduledTime) })

        var moodValues: [Double] = []
        var energyValues: [Double] = []
        var moodMissing = 0
        var energyMissing = 0
        var moodMetrics: [DayMetric] = []
        var energyMetrics: [DayMetric] = []
        var correlationScore = 0
        var lowestEnergy: DayMetric?
        var consecutiveEnergyLow = 0
        var energyLowStreak = 0
        var moodTrendSequence = 0
        var previousMoodValue: Double?
        var missingDays = 0

        for offset in 0..<range.days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: rangeStart) else { continue }
            let key = dayKey(day)
            let dayEntries = entriesByDay[key]
            if let dayEntries = dayEntries {
                let moodDay = dayEntries.map { Double($0.mood) }.average
                let energyDay = dayEntries.map { Double($0.energy) }.average
                moodValues.append(moodDay)
                energyValues.append(energyDay)
                let metric = DayMetric(date: day, value: moodDay, label: dayLabel(day), isMissing: false)
                moodMetrics.append(metric)
                let energyMetric = DayMetric(date: day, value: energyDay, label: dayLabel(day), isMissing: false)
                energyMetrics.append(energyMetric)

                if let currentLowest = lowestEnergy {
                    if let metricValue = energyMetric.value, let lowestValue = currentLowest.value, metricValue < lowestValue {
                        lowestEnergy = energyMetric
                    }
                } else {
                    lowestEnergy = energyMetric
                }

                if energyDay < 40 {
                    consecutiveEnergyLow += 1
                } else {
                    energyLowStreak = max(energyLowStreak, consecutiveEnergyLow)
                    consecutiveEnergyLow = 0
                }

                if let previous = previousMoodValue {
                    if moodDay < previous { moodTrendSequence += 1 } else { moodTrendSequence = 0 }
                }
                previousMoodValue = moodDay
            } else {
                missingDays += 1
                moodMissing += 1
                energyMissing += 1
                moodMetrics.append(DayMetric(date: day, value: nil, label: dayLabel(day), isMissing: true))
                energyMetrics.append(DayMetric(date: day, value: nil, label: dayLabel(day), isMissing: true))
            }

            let dayLogs = logsByDay[key] ?? []
            let missedCount = dayLogs.filter { logStatus($0) == .missed }.count
            if missedCount > 0, let dayEntries = dayEntries, dayEntries.map({ Double($0.mood) }).average <= 2 {
                correlationScore += 1
            }
        }
        energyLowStreak = max(energyLowStreak, consecutiveEnergyLow)

        moodSeries = moodMetrics
        energySeries = energyMetrics
        lowestEnergyMetric = lowestEnergy
        moodAverage = moodValues.average
        moodStdDeviation = moodValues.standardDeviation
        energyAverage = energyValues.average
        energyVariance = energyValues.variance

        let previousMoodAverage: Double = entries.filter { $0.date >= previousStart && $0.date < previousEnd }.map { Double($0.mood) }.average
        moodDelta = moodAverage - previousMoodAverage
        moodTrend = trendDirection(for: moodDelta)

        let previousEnergyAverage: Double = entries.filter { $0.date >= previousStart && $0.date < previousEnd }.map { Double($0.energy) }.average
        let energyDelta = energyAverage - previousEnergyAverage
        energyTrend = trendDirection(for: energyDelta)

        let currentLogs = logs.filter { $0.scheduledTime >= rangeStart && $0.scheduledTime < rangeEnd }
        let previousLogs = logs.filter { $0.scheduledTime >= previousStart && $0.scheduledTime < previousEnd }
        adherence = computeAdherence(on: currentLogs)
        let previousAdherence = computeAdherence(on: previousLogs)
        adherenceTrendDelta = adherence.percent - previousAdherence.percent

        let correlationTriggered = correlationScore >= 2

        flags = buildFlags(adherence: adherence,
                           consecutiveMissed: maxConsecutiveMissed(in: logsByDay, rangeStart: rangeStart, days: range.days),
                           moodDeclineDays: moodTrendSequence,
                           energyLowStreak: energyLowStreak,
                           missingDays: missingDays,
                           correlation: correlationTriggered)

        summaryBullets = buildSummary(moodAvg: moodAverage,
                                      moodDelta: moodDelta,
                                      energyAvg: energyAverage,
                                      energyDelta: energyDelta,
                                      adherence: adherence,
                                      adherenceTrend: adherenceTrendDelta,
                                      correlation: correlationTriggered,
                                      missedDays: missingDays)

        careStatus = evaluateCareStatus(moodDelta: moodDelta,
                                        energyAvg: energyAverage,
                                        adherencePercent: adherence.percent)

        missingCheckins = moodMissing
        isEmptyState = moodSeries.allSatisfy { $0.value == nil } && adherence.totalScheduled == 0
    }

    private func fetchCareEntries(start: Date, end: Date) -> [CareEntry] {
        let request = CareEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return (try? context.fetch(request).map { CareEntry(entity: $0) }) ?? []
    }

    private func fetchMedicationLogs(start: Date, end: Date) -> [MedicationLog] {
        let request = MedicationLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "scheduledTime >= %@ AND scheduledTime < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledTime", ascending: true)]
        return (try? context.fetch(request).map { MedicationLog(entity: $0) }) ?? []
    }

    private func computeAdherence(on logs: [MedicationLog]) -> AdherenceMetric {
        var taken = 0
        var missed = 0
        var upcoming = 0
        let now = Date()
        for log in logs {
            switch logStatus(log) {
            case .taken: taken += 1
            case .missed: missed += 1
            case .upcoming: upcoming += 1
            default: break
            }
        }
        return AdherenceMetric(totalScheduled: logs.count, taken: taken, missed: missed, upcoming: upcoming)
    }

    private func buildFlags(adherence: AdherenceMetric,
                            consecutiveMissed: Int,
                            moodDeclineDays: Int,
                            energyLowStreak: Int,
                            missingDays: Int,
                            correlation: Bool) -> [InsightFlag] {
        var items: [InsightFlag] = []
        if adherence.percent < 0.8 {
            let severity: InsightFlag.Severity = adherence.percent < 0.6 ? .critical : .warning
            items.append(InsightFlag(title: "Low adherence",
                                     detail: "Adherence at \(adherence.percentDisplay).",
                                     severity: severity))
        }
        if consecutiveMissed >= 2 {
            items.append(InsightFlag(title: "Consecutive missed doses",
                                     detail: "Missed \(consecutiveMissed) doses in a row.",
                                     severity: .warning))
        }
        if moodDeclineDays >= 2 {
            items.append(InsightFlag(title: "Mood declining",
                                     detail: "Mood dropped on multiple consecutive days.",
                                     severity: .info))
        }
        if energyLowStreak >= 3 {
            items.append(InsightFlag(title: "Low energy streak",
                                     detail: "Energy below 40% for \(energyLowStreak) days.",
                                     severity: .info))
        }
        if missingDays >= 2 {
            items.append(InsightFlag(title: "Missing check-ins",
                                     detail: "Check-ins missing on \(missingDays) days.",
                                     severity: .info))
        }
        if correlation {
            items.append(InsightFlag(title: "Medication-mood correlation",
                                     detail: "Lower mood observed on days medication was missed.",
                                     severity: .warning))
        }
        return items
    }

    private func buildSummary(moodAvg: Double,
                              moodDelta: Double,
                              energyAvg: Double,
                              energyDelta: Double,
                              adherence: AdherenceMetric,
                              adherenceTrend: Double,
                              correlation: Bool,
                              missedDays: Int) -> [String] {
        var bullets: [String] = []
        let moodLine = String(format: "• Mood: %@ (Avg %.1f, %@%.1f vs prior)", moodTrend.label, moodAvg, moodDelta >= 0 ? "+" : "", moodDelta)
        bullets.append(moodLine)
        let energyLine = String(format: "• Energy: %@ (Avg %.0f%%)", energyTrend.label, energyAvg)
        bullets.append(energyLine)
        let adherenceLine = String(format: "• Adherence: %@ (%d taken, %d missed, %@%.0f%% vs prior)", adherence.percentDisplay, adherence.taken, adherence.missed, adherenceTrend >= 0 ? "+" : "", adherenceTrend * 100)
        bullets.append(adherenceLine)
        if correlation {
            bullets.append("• Correlation: Mood decline observed on missed days")
        } else if missedDays > 0 {
            bullets.append("• Check-ins: Missing on \(missedDays) days")
        }
        return bullets
    }

    private func trendDirection(for delta: Double) -> TrendDirection {
        let threshold = 0.1
        if delta > threshold { return .up }
        if delta < -threshold { return .down }
        return .stable
    }

    private func evaluateCareStatus(moodDelta: Double, energyAvg: Double, adherencePercent: Double) -> CareStatusLevel {
        if adherencePercent < 0.75 { return .attention }
        if moodDelta < -0.3 { return .monitor }
        if energyAvg < 45 { return .monitor }
        return .stable
    }

    private func maxConsecutiveMissed(in logsByDay: [Date: [MedicationLog]], rangeStart: Date, days: Int) -> Int {
        var maxRun = 0
        var current = 0
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: rangeStart) else { continue }
            let dayLogs = logsByDay[dayKey(day)] ?? []
            let missed = dayLogs.filter { logStatus($0) == .missed }.count
            if missed > 0 {
                current += missed
            } else {
                maxRun = max(maxRun, current)
                current = 0
            }
        }
        return max(maxRun, current)
    }

    private func logStatus(_ log: MedicationLog) -> MedicationLogStatus {
        if log.takenAt != nil || log.status == .taken { return .taken }
        if log.status == .skipped { return .missed }
        return log.scheduledTime < Date() ? .missed : .upcoming
    }

    private func dayKey(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func dayLabel(_ date: Date) -> String {
        formatter.string(from: date)
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    var variance: Double {
        guard count > 1 else { return 0 }
        let avg = average
        let squared = map { pow($0 - avg, 2) }
        return squared.reduce(0, +) / Double(count - 1)
    }

    var standardDeviation: Double {
        sqrt(variance)
    }
}
