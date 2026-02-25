//
//  MedicationCardView.swift
//  vCare
//

import SwiftUI

struct MedicationCardView: View {
    let medication: Medication
    let status: MedicationStatus
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.headline)
                        Text(medication.dose)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    statusBadge
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(medication.time, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: status)
    }

    private var backgroundColor: Color {
        switch status {
        case .taken:
            return Color.green.opacity(0.15)
        case .upcoming:
            return Color(.systemBackground)
        case .missed:
            return Color.red.opacity(0.12)
        }
    }

    private var statusBadge: some View {
        let text: String
        let color: Color

        switch status {
        case .taken:
            text = "Taken"
            color = .green
        case .upcoming:
            text = "Upcoming"
            color = .orange
        case .missed:
            text = "Missed"
            color = .red
        }

        return Text(text)
            .font(.caption).bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
