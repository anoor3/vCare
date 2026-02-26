
import CoreData

@objc(MedicationEntity)
public class MedicationEntity: NSManagedObject {
}

extension MedicationEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicationEntity> {
        NSFetchRequest<MedicationEntity>(entityName: "MedicationEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var dose: String?
    @NSManaged public var time: Date?
    @NSManaged public var isTaken: Bool
    @NSManaged public var section: String?
}
