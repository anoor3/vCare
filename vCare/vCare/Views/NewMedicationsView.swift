import SwiftUI

struct NewMedicationsView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @ObservedObject var appState: AppState
    @Binding var highlightedLogID: UUID?
    var onMarkTaken: (MedicationLog) -> Void
    var onSkip: (MedicationLog) -> Void
    var onUndoSkip: (MedicationLog) -> Void
    var onAddMedication: () -> Void

    private let dayparts: [(MedicationTime, String, String)] = [
        (.morning, "Morning", "sun.max.fill"),
        (.afternoon, "Afternoon", "cloud.sun.fill"),
        (.evening, "Evening", "moon.stars.fill"),
        (.night, "Night", "moon.zzz.fill")
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryStrip

                    if let next = viewModel.nextDose {
                        NextDoseHeroCard(log: next,
                                         countdownText: viewModel.countdownText) {
                            onMarkTaken(next)
                        }
                    }

                    timeline
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .onChange(of: highlightedLogID) { id in
                    guard let id else { return }
                    withAnimation(.spring()) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if highlightedLogID == id {
                            highlightedLogID = nil
                        }
                    }
                }
            }
        }
    }

    private var summaryStrip: some View {
        EmptyView()
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Schedule")
                .font(.title2).bold()

            ForEach(dayparts.indices, id: \.self) { index in
                let entry = dayparts[index]
                let logs = logs(for: entry.0)
                TimelineSectionView(title: entry.1,
                                    icon: entry.2,
                                    logs: logs,
                                    indicatorColor: indicatorColor(for: logs),
                                    isLast: index == dayparts.count - 1,
                                    highlightedLogID: highlightedLogID,
                                    cardBuilder: { log in
                                        MedicationCardView(log: log,
                                                           iconName: entry.2,
                                                           statusText: statusDescription(for: log),
                                                           onTake: { onMarkTaken(log) },
                                                           onSkip: { onSkip(log) },
                                                           onUndoSkip: { onUndoSkip(log) },
                                                           isHighlighted: highlightedLogID == log.id)
                                            .id(log.id)
                                    })
            }

            if viewModel.todayLogsSorted.isEmpty {
                MedicationEmptyStateCard(onAdd: onAddMedication)
            }
        }
    }

    private func logs(for time: MedicationTime) -> [MedicationLog] {
        let calendar = Calendar.current
        return viewModel.todayLogsSorted.filter { log in
            let hour = calendar.component(.hour, from: log.scheduledTime)
            return time.contains(hour: hour)
        }
    }

    private func indicatorColor(for logs: [MedicationLog]) -> Color {
        guard !logs.isEmpty else { return Color.secondary.opacity(0.5) }
        if logs.allSatisfy({ $0.status == .taken }) { return .green }
        if logs.contains(where: { $0.status == .missed }) { return .red }
        return .accentColor
    }

    private func statusDescription(for log: MedicationLog) -> String {
        switch log.status {
        case .taken:
            if let takenAt = log.takenAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                return formatter.localizedString(for: takenAt, relativeTo: Date())
            }
            return "Taken"
        case .missed:
            let minutes = Int(Date().timeIntervalSince(log.scheduledTime) / 60)
            return minutes > 0 ? "Missed \(minutes)m ago" : "Missed"
        case .skipped:
            return "Skipped"
        case .upcoming:
            let minutes = Int(log.scheduledTime.timeIntervalSinceNow / 60)
            if minutes <= 0 { return "Due now" }
            if minutes < 60 { return "Due in \(minutes)m" }
            return "Due in \(minutes / 60)h"
        }
    }
}

private struct TimelineSectionView<Content: View>: View {
    var title: String
    var icon: String
    var logs: [MedicationLog]
    var indicatorColor: Color
    var isLast: Bool
    var highlightedLogID: UUID?
    @ViewBuilder var cardBuilder: (MedicationLog) -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(spacing: 0) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.secondary.opacity((logs.isEmpty || isLast) ? 0 : 0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .padding(.top, 6)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Label(title, systemImage: icon)
                        .font(.headline)
                    if logs.isEmpty {
                        Text("No doses")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }

                if logs.isEmpty {
                    Divider()
                } else {
                    ForEach(logs) { log in
                        cardBuilder(log)
                    }
                }
            }
        }
    }
}

struct MedicationEmptyStateCard: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "capsule.portrait")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            Text("No schedules yet")
                .font(.headline)
            Text("Tap Add to start building your medication plan.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Text("Add Medication")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 18, y: 10)
    }
}
