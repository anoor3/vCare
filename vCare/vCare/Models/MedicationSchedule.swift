//
//  MedicationSchedule.swift
//  vCare
//

import Foundation

enum MedicationFrequencyType: String, CaseIterable, Identifiable {
    case daily
    case specificDays
    case interval

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .specificDays: return "Specific Days"
        case .interval: return "Interval"
        }
    }
}

struct MedicationSchedule: Identifiable {
    var id: UUID
    var name: String
    var dose: String
    var frequencyType: MedicationFrequencyType
    var times: [Date]
    var startDate: Date
    var endDate: Date?
    var notes: String?
    var colorTag: String?
    var reminderEnabled: Bool

    init(id: UUID = UUID(), name: String, dose: String, frequencyType: MedicationFrequencyType, times: [Date], startDate: Date, endDate: Date? = nil, notes: String? = nil, colorTag: String? = nil, reminderEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.dose = dose
        self.frequencyType = frequencyType
        self.times = times
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.colorTag = colorTag
        self.reminderEnabled = reminderEnabled
    }

    init(entity: MedicationScheduleEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.dose = entity.dose ?? ""
        self.frequencyType = MedicationFrequencyType(rawValue: entity.frequencyType ?? "daily") ?? .daily
        self.times = entity.times
        self.startDate = entity.startDate ?? Date()
        self.endDate = entity.endDate
        self.notes = entity.notes
        self.colorTag = entity.colorTag
        self.reminderEnabled = entity.reminderEnabled
    }

    func apply(to entity: MedicationScheduleEntity) {
        entity.id = id
        entity.name = name
        entity.dose = dose
        entity.frequencyType = frequencyType.rawValue
        entity.setTimes(times)
        entity.startDate = startDate
        entity.endDate = endDate
        entity.notes = notes
        entity.colorTag = colorTag
        entity.reminderEnabled = reminderEnabled
    }
}
