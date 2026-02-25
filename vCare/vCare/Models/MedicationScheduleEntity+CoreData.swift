//
//  MedicationScheduleEntity+CoreData.swift
//  vCare
//

import CoreData

@objc(MedicationScheduleEntity)
public class MedicationScheduleEntity: NSManagedObject {
}

extension MedicationScheduleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicationScheduleEntity> {
        NSFetchRequest<MedicationScheduleEntity>(entityName: "MedicationScheduleEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dose: String?
    @NSManaged public var frequencyType: String?
    @NSManaged public var timesData: Data?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var colorTag: String?
    @NSManaged public var reminderEnabled: Bool
    @NSManaged public var logs: NSSet?
}

extension MedicationScheduleEntity {
    var times: [Date] {
        guard let data = timesData else { return [] }
        return (try? JSONDecoder().decode([Date].self, from: data)) ?? []
    }

    func setTimes(_ dates: [Date]) {
        timesData = try? JSONEncoder().encode(dates)
    }
}
