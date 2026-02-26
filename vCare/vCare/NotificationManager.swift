//
//  NotificationManager.swift
//  vCare
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func schedulePrimaryReminder(for log: MedicationLog) {
        guard log.takenAt == nil else { return }
        guard log.scheduledTime > Date().addingTimeInterval(-60) else { return }
        cancelNotification(for: log)
        let content = buildContent(for: log,
                                   titlePrefix: "Next dose",
                                   bodyPrefix: "It's time to take",
                                   category: .primary)

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: log.scheduledTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = log.id.uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func scheduleMissedFollowUp(for log: MedicationLog) {
        guard log.takenAt == nil else { return }
        let followUpDate = log.scheduledTime.addingTimeInterval(15 * 60)
        guard followUpDate > Date() else { return }
        let content = buildContent(for: log,
                                   titlePrefix: "Missed dose?",
                                   bodyPrefix: "Tap to mark taken or snooze",
                                   category: .followUp)

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: followUpDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = log.id.uuidString + "-follow"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func scheduleDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-summary"])
        var components = DateComponents()
        components.hour = 21
        components.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Daily Medication Summary"
        content.body = "Great work staying on top of medications today."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.summary.rawValue
        let request = UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelNotification(for log: MedicationLog) {
        let identifiers = [log.id.uuidString, log.id.uuidString + "-follow", log.id.uuidString + "-snooze"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let baseIdentifier = identifier
            .replacingOccurrences(of: "-follow", with: "")
            .replacingOccurrences(of: "-snooze", with: "")
        if response.actionIdentifier == NotificationAction.markTaken.rawValue {
            NotificationCenter.default.post(name: .medicationAction, object: baseIdentifier)
            NotificationCenter.default.post(name: .medicationDeepLink, object: baseIdentifier)
        } else if response.actionIdentifier == NotificationAction.remindLater.rawValue {
            scheduleSnooze(from: response.notification.request)
        } else {
            NotificationCenter.default.post(name: .medicationDeepLink, object: baseIdentifier)
        }
        completionHandler()
    }

    private func registerCategories() {
        let takeAction = UNNotificationAction(identifier: NotificationAction.markTaken.rawValue, title: "Mark as Taken", options: [.authenticationRequired])
        let snoozeAction = UNNotificationAction(identifier: NotificationAction.remindLater.rawValue, title: "Remind in 10 min", options: [])
        let primary = UNNotificationCategory(identifier: NotificationCategory.primary.rawValue, actions: [takeAction, snoozeAction], intentIdentifiers: [], options: [.customDismissAction])
        let followUp = UNNotificationCategory(identifier: NotificationCategory.followUp.rawValue, actions: [takeAction, snoozeAction], intentIdentifiers: [], options: [])
        let summary = UNNotificationCategory(identifier: NotificationCategory.summary.rawValue, actions: [], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([primary, followUp, summary])
    }

    private func scheduleSnooze(from request: UNNotificationRequest) {
        let newTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
        let identifier = request.identifier + "-snooze"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        let newRequest = UNNotificationRequest(identifier: identifier, content: request.content, trigger: newTrigger)
        UNUserNotificationCenter.current().add(newRequest, withCompletionHandler: nil)
    }

    private func buildContent(for log: MedicationLog, titlePrefix: String, bodyPrefix: String, category: NotificationCategory) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let name = log.schedule?.name ?? "Medication"
        let dose = log.schedule?.dose ?? ""
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeString = formatter.string(from: log.scheduledTime)
        let minutes = Int(log.scheduledTime.timeIntervalSinceNow / 60)
        let countdown: String
        if minutes >= 0 {
            countdown = "in \(max(1, minutes)) min"
        } else {
            countdown = "overdue by \(max(1, abs(minutes))) min"
        }
        content.title = "\(titlePrefix): \(name)"
        content.subtitle = dose
        content.body = "\(bodyPrefix) at \(timeString) (\(countdown))."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = category.rawValue
        content.userInfo = ["logID": log.id.uuidString]
        content.summaryArgument = name
        content.threadIdentifier = "medications"
        return content
    }
}

enum NotificationAction: String {
    case markTaken
    case remindLater
}

enum NotificationCategory: String {
    case primary
    case followUp
    case summary
}

extension Notification.Name {
    static let medicationDeepLink = Notification.Name("MedicationDeepLink")
    static let medicationAction = Notification.Name("MedicationAction")
}
