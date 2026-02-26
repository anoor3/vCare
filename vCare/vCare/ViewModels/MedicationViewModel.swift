//
//  MedicationViewModel.swift
//  vCare
//

import Combine
import CoreData
import Foundation

@MainActor
final class MedicationViewModel: ObservableObject {
    @Published private(set) var schedules: [MedicationSchedule] = []
    @Published private(set) var logs: [MedicationLog] = []
    @Published private(set) var countdownText: String = "--"
    @Published private(set) var nextDoseUrgency: NextDoseUrgency = .normal

    private let context: NSManagedObjectContext
    private let notificationManager = NotificationManager.shared
    private var timerCancellable: AnyCancellable?
    private var actionCancellable: AnyCancellable?
    private var currentDayStart: Date = Calendar.current.startOfDay(for: Date())

    init(context: NSManagedObjectContext) {
        self.context = context
        notificationManager.requestAuthorization()
        notificationManager.scheduleDailySummary()
        actionCancellable = NotificationCenter.default.publisher(for: .medicationAction)
            .compactMap { $0.object as? String }
            .compactMap { UUID(uuidString: $0) }
            .sink { [weak self] id in
                self?.markTaken(logID: id)
            }
        refresh()
        refreshCountdownTimer()
    }

    deinit {
        timerCancellable?.cancel()
        actionCancellable?.cancel()
    }

    func refresh() {
        fetchSchedulesAndLogs()
        generateTodayLogsIfNeeded()
        autoMarkMissedLogs()
        fetchSchedulesAndLogs()
        scheduleNotificationsForToday()
        updateCountdownText()
    }

    var todayLogs: [MedicationLog] {
        logs.filter { Calendar.current.isDateInToday($0.date) }
    }

    var todayLogsSorted: [MedicationLog] {
        todayLogs.sorted { $0.scheduledTime < $1.scheduledTime }
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

    var upcomingCount: Int {
        todayLogs.filter { $0.status == .upcoming }.count
    }

    var adherencePercentage: Double {
        let relevant = todayLogs.filter { $0.status != .skipped }
        guard !relevant.isEmpty else { return 0 }
        return Double(takenCount) / Double(relevant.count)
    }

    var progressFraction: Double { adherencePercentage }

    var nextDose: MedicationLog? {
        upcomingLogs.first
    }

    func generateTodayLogsIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        currentDayStart = today

        for schedule in schedules {
            guard schedule.startDate <= today, schedule.endDate == nil || schedule.endDate! >= today else { continue }
            for time in schedule.times {
                guard let scheduledTime = combine(date: today, with: time) else { continue }
                if !logs.contains(where: { log in
                    log.scheduleID == schedule.id && calendar.isDate(log.date, inSameDayAs: today) && abs(log.scheduledTime.timeIntervalSince(scheduledTime)) < 60
                }) {
                    let entity = MedicationLogEntity(context: context)
                    let identifier = UUID()
                    entity.id = identifier
                    entity.scheduleID = schedule.id
                    entity.date = today
                    entity.scheduledTime = scheduledTime
                    entity.status = MedicationLogStatus.upcoming.rawValue
                    entity.schedule = fetchScheduleEntity(by: schedule.id)
                    entity.notificationID = identifier.uuidString
                }
            }
        }

        if context.hasChanges {
            do { try context.save() } catch { print("Failed to generate logs: \(error)") }
        }
    }

    func autoMarkMissedLogs() {
        let request = MedicationLogEntity.fetchRequest()
        do {
            let entities = try context.fetch(request)
            let now = Date()
            var didChange = false
            for entity in entities {
                let previousStatus = MedicationLogStatus(rawValue: entity.status ?? "") ?? .upcoming
                let newStatus = determineStatus(for: entity, now: now)
                if entity.status != newStatus.rawValue {
                    entity.status = newStatus.rawValue
                    didChange = true
                    if newStatus == .missed && previousStatus != .missed {
                        createCareAlertIfNeeded(for: entity)
                        if let id = entity.id, #available(iOS 16.1, *) {
                            NextDoseLiveActivityManager.shared.update(logID: id, status: .overdue)
                        }
                    }
                }
            }
            if didChange {
                try context.save()
            }
        } catch {
            print("Failed to update statuses: \(error)")
        }
    }

    func markTaken(logID: UUID) {
        updateLog(logID: logID, newStatus: .taken, takenAt: Date())
    }

    func markSkipped(logID: UUID) {
        updateLog(logID: logID, newStatus: .skipped, takenAt: nil)
    }

    func updateStatusesOnAppear() {
        handleDayChange()
        autoMarkMissedLogs()
        fetchSchedulesAndLogs()
        updateCountdownText()
    }

    func refreshCountdownTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 60, tolerance: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateStatusesOnAppear()
            }
    }

    func saveSchedule(_ schedule: MedicationSchedule) {
        let entity = fetchScheduleEntity(by: schedule.id) ?? MedicationScheduleEntity(context: context)
        schedule.apply(to: entity)

        do {
            try context.save()
            deleteLogsForToday(scheduleID: schedule.id)
            refresh()
        } catch {
            print("Failed to save schedule: \(error)")
        }
    }

    func deleteSchedule(_ schedule: MedicationSchedule) {
        guard let entity = fetchScheduleEntity(by: schedule.id) else { return }
        context.delete(entity)
        do {
            try context.save()
            refresh()
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
            let scheduleLookup = Dictionary(uniqueKeysWithValues: schedules.map { ($0.id, $0) })
            let now = Date()
            self.logs = logEntities.map { entity in
                var log = MedicationLog(entity: entity)
                log.schedule = scheduleLookup[log.scheduleID]
                log.status = determineStatus(for: entity, now: now)
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
            let currentStatus = determineStatus(for: entity, now: Date())
            guard currentStatus != .taken else { return }
            if newStatus == .taken && entity.takenAt != nil { return }
            entity.status = newStatus.rawValue
            entity.takenAt = takenAt
            try context.save()
            let log = MedicationLog(entity: entity)
            notificationManager.cancelNotification(for: log)
            if newStatus == .missed {
                createCareAlertIfNeeded(for: entity)
            }
            if #available(iOS 16.1, *) {
                let liveStatus: NextDoseLiveActivityStatus
                switch newStatus {
                case .taken: liveStatus = .taken
                case .missed: liveStatus = .overdue
                default: liveStatus = .upcoming
                }
                NextDoseLiveActivityManager.shared.update(logID: logID, status: liveStatus)
            }
            fetchSchedulesAndLogs()
            updateCountdownText()
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

    private func scheduleNotificationsForToday() {
        todayLogs.forEach { log in
            guard log.schedule?.reminderEnabled ?? true else { return }
            guard log.takenAt == nil else {
                notificationManager.cancelNotification(for: log)
                return
            }
            if log.scheduledTime < Date().addingTimeInterval(-120) { return }
            notificationManager.cancelNotification(for: log)
            notificationManager.schedulePrimaryReminder(for: log)
            notificationManager.scheduleMissedFollowUp(for: log)
        }
    }

    private func updateCountdownText() {
        guard let next = nextDose else {
            countdownText = "--"
            nextDoseUrgency = .normal
            return
        }
        let now = Date()
        let interval = next.scheduledTime.timeIntervalSince(now)
        if interval <= 0 {
            countdownText = "Overdue"
            nextDoseUrgency = .overdue
            return
        }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            countdownText = "In \(max(minutes, 1)) min"
        } else {
            countdownText = "In \(minutes / 60)h \(minutes % 60)m"
        }
        if minutes < 30 {
            nextDoseUrgency = .warning
        } else {
            nextDoseUrgency = .normal
        }
        if #available(iOS 16.1, *) {
            NextDoseLiveActivityManager.shared.refresh(using: nextDose)
        }
    }

    private func determineStatus(for entity: MedicationLogEntity, now: Date) -> MedicationLogStatus {
        if entity.takenAt != nil {
            return .taken
        }
        guard let scheduled = entity.scheduledTime else { return .upcoming }
        return scheduled > now ? .upcoming : .missed
    }

    private func handleDayChange() {
        let today = Calendar.current.startOfDay(for: Date())
        guard today > currentDayStart else { return }
        currentDayStart = today
        generateTodayLogsIfNeeded()
        fetchSchedulesAndLogs()
        scheduleNotificationsForToday()
    }

    private func createCareAlertIfNeeded(for entity: MedicationLogEntity) {
        // Placeholder: cloud sync disabled
    }
}

enum NextDoseUrgency {
    case normal
    case warning
    case overdue
}
