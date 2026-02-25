//
//  MedicationViewModel.swift
//  vCare
//

import CoreData
import Foundation

@MainActor
final class MedicationViewModel: ObservableObject {
    @Published private(set) var schedules: [MedicationSchedule] = []
    @Published private(set) var logs: [MedicationLog] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        refresh()
    }

    func refresh() {
        fetchSchedulesAndLogs()
        generateDailyLogsIfNeeded()
        autoMarkMissedLogs()
        fetchSchedulesAndLogs()
    }

    var todayLogs: [MedicationLog] {
        logs.filter { Calendar.current.isDateInToday($0.date) }
    }

    var upcomingLogs: [MedicationLog] {
        logs.filter { $0.status == .upcoming }.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var takenCount: Int {
        todayLogs.filter { $0.status == .taken }.count
    }

    var missedCount: Int {
        todayLogs.filter { $0.status == .missed }.count
    }

    var adherencePercentage: Double {
        let relevant = todayLogs.filter { $0.status != .skipped }
        guard !relevant.isEmpty else { return 0 }
        return Double(takenCount) / Double(relevant.count)
    }

    var nextMedication: MedicationLog? {
        upcomingLogs.first
    }

    func autoMarkMissedLogs() {
        let request = MedicationLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@ AND scheduledTime < %@", MedicationLogStatus.upcoming.rawValue, Date() as NSDate)
        do {
            let entities = try context.fetch(request)
            entities.forEach { entity in
                entity.status = MedicationLogStatus.missed.rawValue
            }
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Failed to mark missed logs: \(error)")
        }
    }

    func markTaken(logID: UUID) {
        updateLog(logID: logID, newStatus: .taken, takenAt: Date())
    }

    func markSkipped(logID: UUID) {
        updateLog(logID: logID, newStatus: .skipped, takenAt: nil)
    }

    func generateDailyLogsIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for schedule in schedules {
            guard schedule.startDate <= today, schedule.endDate == nil || schedule.endDate! >= today else { continue }
            for time in schedule.times {
                guard let scheduledTime = combine(date: today, with: time) else { continue }
                if !logs.contains(where: { log in
                    log.scheduleID == schedule.id && calendar.isDate(log.date, inSameDayAs: today) && abs(log.scheduledTime.timeIntervalSince(scheduledTime)) < 60
                }) {
                    let entity = MedicationLogEntity(context: context)
                    entity.id = UUID()
                    entity.scheduleID = schedule.id
                    entity.date = today
                    entity.scheduledTime = scheduledTime
                    entity.status = MedicationLogStatus.upcoming.rawValue
                    entity.schedule = fetchScheduleEntity(by: schedule.id)
                }
            }
        }

        if context.hasChanges {
            do { try context.save() } catch { print("Failed to generate logs: \(error)") }
        }
    }

    func saveSchedule(_ schedule: MedicationSchedule) {
        let entity = fetchScheduleEntity(by: schedule.id) ?? MedicationScheduleEntity(context: context)
        schedule.apply(to: entity)

        do {
            try context.save()
            deleteLogsForToday(scheduleID: schedule.id)
            generateDailyLogsIfNeeded()
            fetchSchedulesAndLogs()
        } catch {
            print("Failed to save schedule: \(error)")
        }
    }

    func deleteSchedule(_ schedule: MedicationSchedule) {
        guard let entity = fetchScheduleEntity(by: schedule.id) else { return }
        context.delete(entity)
        do {
            try context.save()
            fetchSchedulesAndLogs()
        } catch {
            print("Failed to delete schedule: \(error)")
        }
    }

    private func fetchSchedulesAndLogs() {
        do {
            let scheduleEntities = try context.fetch(MedicationScheduleEntity.fetchRequest())
            let schedules = scheduleEntities.map { MedicationSchedule(entity: $0) }
            self.schedules = schedules

            let logRequest = MedicationLogEntity.fetchRequest()
            logRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationLogEntity.scheduledTime, ascending: true)]
            let logEntities = try context.fetch(logRequest)
            let scheduleDict = Dictionary(uniqueKeysWithValues: schedules.map { ($0.id, $0) })
            self.logs = logEntities.map { entity in
                var log = MedicationLog(entity: entity)
                log.schedule = scheduleDict[log.scheduleID]
                return log
            }
        } catch {
            print("Failed to fetch schedules/logs: \(error)")
        }
    }

    private func fetchScheduleEntity(by id: UUID) -> MedicationScheduleEntity? {
        let request = MedicationScheduleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func updateLog(logID: UUID, newStatus: MedicationLogStatus, takenAt: Date?) {
        let request = MedicationLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", logID as CVarArg)
        request.fetchLimit = 1
        do {
            guard let entity = try context.fetch(request).first else { return }
            entity.status = newStatus.rawValue
            entity.takenAt = takenAt
            try context.save()
            fetchSchedulesAndLogs()
        } catch {
            print("Failed to update log: \(error)")
        }
    }

    private func combine(date: Date, with time: Date) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        return calendar.date(from: combined)
    }

    private func deleteLogsForToday(scheduleID: UUID) {
        let request = MedicationLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "scheduleID == %@ AND date >= %@", scheduleID as CVarArg, Calendar.current.startOfDay(for: Date()) as NSDate)
        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            try context.save()
        } catch {
            print("Failed to delete logs: \(error)")
        }
    }
}
