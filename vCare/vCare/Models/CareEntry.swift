
import CoreData
import Foundation

struct CareEntry: Identifiable, Hashable {
    var id: UUID
    var date: Date
    var mood: Int
    var energy: Int
    var notes: String
    var medicationTaken: Bool

    init(id: UUID = UUID(), date: Date = Date(), mood: Int = 3, energy: Int = 50, notes: String = "", medicationTaken: Bool = false) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energy = energy
        self.notes = notes
        self.medicationTaken = medicationTaken
    }

    init(entity: CareEntryEntity) {
        self.id = entity.id ?? UUID()
        self.date = entity.date ?? Date()
        self.mood = Int(entity.mood)
        self.energy = Int(entity.energy)
        self.notes = entity.notes ?? ""
        self.medicationTaken = entity.medicationTaken
    }

    func apply(to entity: CareEntryEntity) {
        entity.id = id
        entity.date = date
        entity.mood = Int16(mood)
        entity.energy = Int16(energy)
        entity.notes = notes
        entity.medicationTaken = medicationTaken
    }
}
