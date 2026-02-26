#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct NextDoseAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: NextDoseLiveActivityStatus
        var remainingSeconds: Int
        var subtitle: String
    }

    var patientName: String?
    var medicationName: String
    var dose: String
    var scheduledTime: Date
    var logID: String
}

@available(iOS 16.1, *)
struct NextDoseWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NextDoseAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.attributes.medicationName)
                    .font(.headline)
                Text(context.attributes.dose)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if context.state.status == .overdue {
                    Text("Overdue")
                        .bold()
                        .foregroundColor(.red)
                } else {
                    Text("Upcoming")
                        .foregroundColor(.secondary)
                }
                Text(timerText(for: context))
                    .font(.title2).bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.medicationName, systemImage: "pills.fill")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerText(for: context))
                        .font(.title3).bold()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                Image(systemName: "pills.fill")
            } compactTrailing: {
                Text(shortTimerText(for: context))
                    .font(.caption)
            } minimal: {
                Image(systemName: "pills.fill")
            }
        }
    }

    private func timerText(for context: ActivityViewContext<NextDoseAttributes>) -> String {
        switch context.state.status {
        case .upcoming:
            return shortTimerText(for: context)
        case .overdue:
            return "Overdue \(max(1, -context.state.remainingSeconds) / 60)m"
        case .taken:
            return "Taken"
        }
    }

    private func shortTimerText(for context: ActivityViewContext<NextDoseAttributes>) -> String {
        let seconds = max(0, context.state.remainingSeconds)
        if seconds >= 3600 {
            return "\(seconds / 3600)h"
        } else {
            return "\(max(1, seconds / 60))m"
        }
    }
}
#endif
