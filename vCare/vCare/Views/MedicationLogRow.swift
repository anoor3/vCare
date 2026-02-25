//
//  MedicationLogRow.swift
//  vCare
//

import SwiftUI

struct MedicationLogRow: View {
    let log: MedicationLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.schedule?.name ?? "Medication")
                        .font(.headline)
                    Text(log.schedule?.dose ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge
            }

            HStack {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if let takenAt = log.takenAt, log.status == .taken {
                    Text("Taken at \(takenAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 4)
    }

    private var statusBadge: some View {
        Text(log.status.displayName)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch log.status {
        case .taken: return .green
        case .upcoming: return .orange
        case .missed: return .red
        case .skipped: return .gray
        }
    }
}
