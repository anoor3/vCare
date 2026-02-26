import CoreData
import Foundation

final class CarePortalManager {
    static let shared = CarePortalManager()
    private init() {}

    func generateShareToken(context: NSManagedObjectContext, patientName: String, rangeDays: Int = 30) -> String? {
        guard let snapshot = buildSnapshot(context: context, patientName: patientName, rangeDays: rangeDays),
              let payload = CarePortalCrypto.encrypt(snapshot: snapshot) else { return nil }
        return payload.toTokenString()
    }

    func importToken(_ token: String) -> CareShareProfileDTO? {
        guard let payload = CarePortalPayload.decodeToken(token),
              let snapshot = CarePortalCrypto.decrypt(payload: payload) else { return nil }
        return snapshot
    }

    private func buildSnapshot(context: NSManagedObjectContext, patientName: String, rangeDays: Int) -> CareShareProfileDTO? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let start = Calendar.current.date(byAdding: .day, value: -(rangeDays - 1), to: today) else { return nil }

        let careEntries = fetchCareEntries(context: context, start: start)
        let schedules = fetchMedicationSchedules(context: context)
        let logs: [MedicationLogDTO] = []

        let careDTOs = careEntries.map { entry -> CareEntryDTO in
            CareEntryDTO(dayKey: entry.dayKeyString,
                         mood: Int(entry.mood),
                         energy: Int(entry.energy),
                         notes: entry.notes)
        }

        let scheduleDTOs = schedules.map { schedule -> MedicationScheduleDTO in
            MedicationScheduleDTO(scheduleID: schedule.id?.uuidString ?? UUID().uuidString,
                                   name: schedule.name ?? "",
                                   dose: schedule.dose ?? "",
                                   times: schedule.timesAsStrings,
                                   startDate: schedule.time ?? Date(),
                                   endDate: nil,
                                   reminderEnabled: true)
        }

        let logDTOs: [MedicationLogDTO] = []

        let adherencePercent = AdherenceCalculator.adherencePercent(logs: logDTOs)
        let summary = InsightsSummaryDTO(moodAverage: careDTOs.map { Double($0.mood) }.average,
                                         energyAverage: careDTOs.map { Double($0.energy) }.average,
                                         adherencePercent: adherencePercent,
                                         summaryLines: [])

        return CareShareProfileDTO(payloadVersion: 1,
                                   shareID: UUID().uuidString,
                                   patientDisplayName: patientName,
                                   createdAt: Date(),
                                   rangeDaysIncluded: rangeDays,
                                   careEntries: careDTOs,
                                   medicationSchedules: scheduleDTOs,
                                   medicationLogs: logDTOs,
                                   insightsSummary: summary,
                                   alerts: [])
    }

    private func fetchCareEntries(context: NSManagedObjectContext, start: Date) -> [CareEntryEntity] {
        let request = CareEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@", start as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    private func fetchMedicationSchedules(context: NSManagedObjectContext) -> [MedicationEntity] {
        let request = MedicationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

}

private enum AdherenceCalculator {
    static func adherencePercent(logs: [MedicationLogDTO]) -> Double {
        let now = Date()
        var taken = 0
        var missed = 0
        var upcoming = 0
        for log in logs {
            if log.takenAt != nil {
                taken += 1
            } else if log.scheduledTime < now {
                missed += 1
            } else {
                upcoming += 1
            }
        }
        let denominator = max(Double(logs.count - upcoming), 1)
        return Double(taken) / denominator
    }
}

extension CareEntryEntity {
    var dayKeyString: String {
        guard let date = date else { return "" }
        return DateFormatter.dayKeyFormatter.string(from: Calendar.current.startOfDay(for: date))
    }
}

extension MedicationEntity {
    var timesAsStrings: [String] {
        guard let time = time else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return [formatter.string(from: time)]
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
