import Foundation

enum NextDoseLiveActivityStatus: String, Codable, Hashable {
    case upcoming
    case overdue
    case taken
}

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class NextDoseLiveActivityManager {
    static let shared = NextDoseLiveActivityManager()
    private var currentActivity: Activity<NextDoseAttributes>?
    private var currentLogID: UUID?

    func refresh(using log: MedicationLog?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            endCurrentActivity()
            return
        }
        guard let log else {
            endCurrentActivity()
            return
        }
        guard shouldStart(for: log) else {
            endCurrentActivity()
            return
        }
        if currentLogID == log.id, let activity = currentActivity {
            update(activity: activity, with: log)
        } else {
            endCurrentActivity()
            startActivity(for: log)
        }
    }

    func update(logID: UUID, status: NextDoseLiveActivityStatus) {
        guard currentLogID == logID, let activity = currentActivity else { return }
        let remaining = remainingSeconds(for: activity.attributes.scheduledTime)
        let subtitle = subtitle(for: activity.attributes.scheduledTime, status: status)
        let content = NextDoseAttributes.ContentState(status: status,
                                                     remainingSeconds: remaining,
                                                     subtitle: subtitle)
        Task { await activity.update(using: content) }
        if status == .taken {
            endCurrentActivity()
        }
    }

    func end(logID: UUID) {
        guard currentLogID == logID else { return }
        endCurrentActivity()
    }

    private func startActivity(for log: MedicationLog) {
        let status = status(for: log)
        let attributes = NextDoseAttributes(patientName: nil,
                                            medicationName: log.schedule?.name ?? "Medication",
                                            dose: log.schedule?.dose ?? "",
                                            scheduledTime: log.scheduledTime,
                                            logID: log.id.uuidString)
        let remaining = remainingSeconds(for: log.scheduledTime)
        let subtitle = subtitle(for: log.scheduledTime, status: status)
        let state = NextDoseAttributes.ContentState(status: status,
                                                    remainingSeconds: remaining,
                                                    subtitle: subtitle)
        do {
            let activity = try Activity<NextDoseAttributes>.request(attributes: attributes,
                                                                    contentState: state,
                                                                    pushType: nil)
            currentActivity = activity
            currentLogID = log.id
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }

    private func update(activity: Activity<NextDoseAttributes>, with log: MedicationLog) {
        let status = status(for: log)
        let remaining = remainingSeconds(for: log.scheduledTime)
        let subtitle = subtitle(for: log.scheduledTime, status: status)
        let state = NextDoseAttributes.ContentState(status: status,
                                                    remainingSeconds: remaining,
                                                    subtitle: subtitle)
        Task { await activity.update(using: state) }
        if status == .taken {
            endCurrentActivity()
        }
    }

    private func endCurrentActivity() {
        if let activity = currentActivity {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
        currentActivity = nil
        currentLogID = nil
    }

    private func shouldStart(for log: MedicationLog) -> Bool {
        let interval = log.scheduledTime.timeIntervalSinceNow
        return interval <= 3600
    }

    private func status(for log: MedicationLog) -> NextDoseLiveActivityStatus {
        if log.takenAt != nil { return .taken }
        return log.scheduledTime < Date() ? .overdue : .upcoming
    }

    private func remainingSeconds(for date: Date) -> Int {
        Int(date.timeIntervalSinceNow)
    }

    private func subtitle(for scheduled: Date, status: NextDoseLiveActivityStatus) -> String {
        let minutes = Int(abs(scheduled.timeIntervalSinceNow) / 60)
        switch status {
        case .upcoming:
            return "In \(max(1, minutes)) min"
        case .overdue:
            return "Overdue \(max(1, minutes)) min"
        case .taken:
            return "Marked as taken"
        }
    }
}

#else
final class NextDoseLiveActivityManager {
    static let shared = NextDoseLiveActivityManager()
    func refresh(using log: MedicationLog?) {}
    func update(logID: UUID, status: NextDoseLiveActivityStatus) {}
    func end(logID: UUID) {}
}
#endif
