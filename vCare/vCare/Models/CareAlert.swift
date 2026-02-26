import Foundation

struct CareAlert {
    let id: UUID
    let dayKey: String
    let createdAt: Date
    let type: String
    let title: String
    let body: String
    let relatedLogID: UUID?
    let severity: String
    var isResolved: Bool

    init(log: MedicationLog, type: String = "missedDose", severity: String = "warning") {
        self.id = UUID()
        self.dayKey = DateFormatter.dayKeyFormatter.string(from: log.scheduledTime)
        self.createdAt = Date()
        self.type = type
        self.title = "Missed dose"
        self.body = "Medication \(log.schedule?.name ?? "") was missed."
        self.relatedLogID = log.id
        self.severity = severity
        self.isResolved = false
    }
}
