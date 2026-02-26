
import CoreData

@objc(MedicationLogEntity)
public class MedicationLogEntity: NSManagedObject {
}

extension MedicationLogEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicationLogEntity> {
        NSFetchRequest<MedicationLogEntity>(entityName: "MedicationLogEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var scheduleID: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var scheduledTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var takenAt: Date?
    @NSManaged public var notificationID: String?
    @NSManaged public var schedule: MedicationScheduleEntity?
}
