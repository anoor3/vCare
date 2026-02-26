import Foundation

struct CareShareProfileDTO: Codable {
    var payloadVersion: Int
    var shareID: String
    var patientDisplayName: String
    var createdAt: Date
    var rangeDaysIncluded: Int
    var careEntries: [CareEntryDTO]
    var medicationSchedules: [MedicationScheduleDTO]
    var medicationLogs: [MedicationLogDTO]
    var insightsSummary: InsightsSummaryDTO?
    var alerts: [AlertDTO]
}

struct CareEntryDTO: Codable {
    var dayKey: String
    var mood: Int
    var energy: Int
    var notes: String?
}

struct MedicationScheduleDTO: Codable {
    var scheduleID: String
    var name: String
    var dose: String
    var times: [String]
    var startDate: Date
    var endDate: Date?
    var reminderEnabled: Bool
}

struct MedicationLogDTO: Codable, Identifiable {
    var id: String { logID }
    var logID: String
    var scheduleID: String
    var dayKey: String
    var scheduledTime: Date
    var takenAt: Date?
}

struct AlertDTO: Codable, Identifiable {
    var id = UUID()
    var type: String
    var title: String
    var body: String
    var severity: String
}

struct InsightsSummaryDTO: Codable {
    var moodAverage: Double
    var energyAverage: Double
    var adherencePercent: Double
    var summaryLines: [String]
}
