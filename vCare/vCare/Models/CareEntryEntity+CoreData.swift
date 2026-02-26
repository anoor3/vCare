
import CoreData

@objc(CareEntryEntity)
public class CareEntryEntity: NSManagedObject {
}

extension CareEntryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CareEntryEntity> {
        NSFetchRequest<CareEntryEntity>(entityName: "CareEntryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var mood: Int16
    @NSManaged public var energy: Int16
    @NSManaged public var notes: String?
    @NSManaged public var medicationTaken: Bool
}
