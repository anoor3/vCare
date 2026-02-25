//
//  HeroStatusView.swift
//  vCare
//

import SwiftUI

struct HeroStatusView: View {
    let greeting: String
    let entry: CareEntry?
    let moodEmoji: String?
    let energy: Int?
    let medicationsRemaining: Int
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.largeTitle).bold()
                if let entry {
                    Text(entry.date, style: .date)
                        .font(.callout)
                        .foregroundColor(.secondary)
                } else {
                    Text("No check-in logged today")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }

            if let entry {
                HStack(spacing: 16) {
                    metricView(title: "Mood", value: moodEmoji ?? "-", footer: moodDescription(for: entry.mood))
                    metricView(title: "Energy", value: "\(energy ?? 0)%", footer: "Today's energy")
                }

                HStack(spacing: 16) {
                    metricView(title: "Medications", value: "\(medicationsRemaining)", footer: "Remaining today")
                    metricView(title: "Streak", value: "\(streak)", footer: "Days logged")
                }
            } else {
                HStack(spacing: 16) {
                    metricView(title: "Medications", value: "\(medicationsRemaining)", footer: "Remaining today")
                    metricView(title: "Streak", value: "\(streak)", footer: "Days logged")
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
    }

    private func metricView(title: String, value: String, footer: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3).bold()
            Text(footer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moodDescription(for mood: Int) -> String {
        switch mood {
        case 1: return "Very low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Positive"
        default: return "Great"
        }
    }
}
