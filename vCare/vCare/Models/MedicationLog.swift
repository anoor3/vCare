
import Foundation

enum MedicationLogStatus: String, CaseIterable, Identifiable {
    case upcoming
    case taken
    case missed
    case skipped

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .upcoming: return "orange"
        case .taken: return "green"
        case .missed: return "red"
        case .skipped: return "gray"
        }
    }
}

struct MedicationLog: Identifiable {
    var id: UUID
    var scheduleID: UUID
    var date: Date
    var scheduledTime: Date
    var status: MedicationLogStatus
    var takenAt: Date?
    var notificationID: String?
    var schedule: MedicationSchedule?

    init(id: UUID = UUID(), scheduleID: UUID, date: Date, scheduledTime: Date, status: MedicationLogStatus = .upcoming, takenAt: Date? = nil, notificationID: String? = nil, schedule: MedicationSchedule? = nil) {
        self.id = id
        self.scheduleID = scheduleID
        self.date = date
        self.scheduledTime = scheduledTime
        self.status = status
        self.takenAt = takenAt
        self.notificationID = notificationID
        self.schedule = schedule
    }

    init(entity: MedicationLogEntity) {
        self.id = entity.id ?? UUID()
        self.scheduleID = entity.scheduleID ?? UUID()
        self.date = entity.date ?? Date()
        self.scheduledTime = entity.scheduledTime ?? Date()
        self.status = MedicationLogStatus(rawValue: entity.status ?? "upcoming") ?? .upcoming
        self.takenAt = entity.takenAt
        self.notificationID = entity.notificationID
        if let scheduleEntity = entity.schedule {
            self.schedule = MedicationSchedule(entity: scheduleEntity)
        } else {
            self.schedule = nil
        }
    }

    func apply(to entity: MedicationLogEntity) {
        entity.id = id
        entity.scheduleID = scheduleID
        entity.date = date
        entity.scheduledTime = scheduledTime
        entity.status = status.rawValue
        entity.takenAt = takenAt
        entity.notificationID = notificationID
    }
}
