//
//  PersistenceController.swift
//  vCare
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        for offset in 0..<7 {
            let entry = CareEntryEntity(context: context)
            entry.id = UUID()
            entry.date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())
            entry.mood = Int16(Int.random(in: 1...5))
            entry.energy = Int16(Int.random(in: 40...90))
            entry.notes = "Sample note #\(offset + 1)"
            entry.medicationTaken = Bool.random()
        }

        let times: [MedicationTime] = [.morning, .afternoon, .evening]
        for time in times {
            let medication = MedicationEntity(context: context)
            medication.id = UUID()
            medication.name = "Medication \(time.rawValue.capitalized)"
            medication.dose = "5mg"
            medication.time = Calendar.current.date(bySettingHour: time.hourComponent, minute: 0, second: 0, of: Date())
            medication.section = time.rawValue
            medication.isTaken = false
        }

        let scheduleEntity = MedicationScheduleEntity(context: context)
        scheduleEntity.id = UUID()
        scheduleEntity.name = "Heart Care"
        scheduleEntity.dose = "10mg"
        scheduleEntity.frequencyType = MedicationFrequencyType.daily.rawValue
        scheduleEntity.setTimes([
            Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
        ])
        scheduleEntity.startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        scheduleEntity.endDate = nil
        scheduleEntity.notes = "Sample schedule"
        scheduleEntity.colorTag = "blue"
        scheduleEntity.reminderEnabled = true

        for offset in 0..<3 {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            for time in scheduleEntity.times {
                let log = MedicationLogEntity(context: context)
                log.id = UUID()
                log.scheduleID = scheduleEntity.id
                log.date = day
                log.scheduledTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: time), minute: Calendar.current.component(.minute, from: time), second: 0, of: day)
                log.status = offset == 0 ? "upcoming" : "taken"
                log.takenAt = offset == 0 ? nil : log.scheduledTime
                log.schedule = scheduleEntity
            }
        }

        do {
            try context.save()
        } catch {
            fatalError("Unresolved error \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "vCare")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

enum MedicationTime: String, CaseIterable {
    case morning
    case afternoon
    case evening
    case night

    var hourComponent: Int {
        switch self {
        case .morning: return 8
        case .afternoon: return 13
        case .evening: return 18
        case .night: return 22
        }
    }

    var title: String {
        rawValue.capitalized
    }

    func contains(hour: Int) -> Bool {
        switch self {
        case .morning: return (5..<12).contains(hour)
        case .afternoon: return (12..<17).contains(hour)
        case .evening: return (17..<21).contains(hour)
        case .night: return hour >= 21 || hour < 5
        }
    }
}
