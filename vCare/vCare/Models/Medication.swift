//
//  Medication.swift
//  vCare
//

import CoreData
import Foundation

struct Medication: Identifiable, Hashable {
    var id: UUID
    var name: String
    var dose: String
    var time: Date
    var isTaken: Bool
    var section: MedicationTime

    init(id: UUID = UUID(), name: String, dose: String, time: Date, isTaken: Bool = false, section: MedicationTime) {
        self.id = id
        self.name = name
        self.dose = dose
        self.time = time
        self.isTaken = isTaken
        self.section = section
    }

    init(entity: MedicationEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.dose = entity.dose ?? ""
        self.time = entity.time ?? Date()
        self.isTaken = entity.isTaken
        let rawValue = entity.section ?? MedicationTime.morning.rawValue
        self.section = MedicationTime(rawValue: rawValue) ?? .morning
    }

    func apply(to entity: MedicationEntity) {
        entity.id = id
        entity.name = name
        entity.dose = dose
        entity.time = time
        entity.isTaken = isTaken
        entity.section = section.rawValue
    }
}
