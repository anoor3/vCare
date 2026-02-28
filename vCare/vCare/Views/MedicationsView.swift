
import CoreData
import SwiftUI

struct MedicationsView: View {
    @StateObject private var viewModel: MedicationViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var showAddMedication = false
    @State private var showManageSchedules = false
    @State private var scheduleToEdit: MedicationSchedule?
    @State private var highlightedLogID: UUID?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MedicationViewModel(context: context))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    if AppFeatures.familyPortalEnabled {
                        PortalStatusBannerView()
                    }

                    if AppFeatures.familyPortalEnabled,
                       appState.role == .caregiverPortal,
                       let snapshot = appState.portalSnapshot {
                        portalMedicationsContent(snapshot: snapshot)
                    } else {
                        ownerMedicationsContent
                    }
                }
                .padding(24)
            }
            .onReceive(NotificationCenter.default.publisher(for: .medicationDeepLink)) { notification in
                guard let idString = notification.object as? String, let uuid = UUID(uuidString: idString) else { return }
                highlightedLogID = uuid
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(uuid, anchor: .center)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if highlightedLogID == uuid {
                        highlightedLogID = nil
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Manage") {
                    showManageSchedules = true
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddMedication = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddMedication, onDismiss: {
            viewModel.refresh()
        }) {
            AddMedicationView(schedule: nil) { schedule in
                viewModel.saveSchedule(schedule)
            }
        }
        .sheet(item: $scheduleToEdit, onDismiss: {
            viewModel.refresh()
        }) { schedule in
            AddMedicationView(schedule: schedule) { updated in
                viewModel.saveSchedule(updated)
            }
        }
        .sheet(isPresented: $showManageSchedules) {
            ManageSchedulesView(viewModel: viewModel,
                                 onEdit: { schedule in
                                     showManageSchedules = false
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                         scheduleToEdit = schedule
                                     }
                                 },
                                 onClose: { showManageSchedules = false })
        }
        .onAppear { viewModel.updateStatusesOnAppear() }
    }

    private func portalMedicationsContent(snapshot: CareShareProfileDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last updated: \(DateFormatter.localizedString(from: snapshot.createdAt, dateStyle: .medium, timeStyle: .short))")
                .font(.caption)
                .foregroundColor(.secondary)
            if snapshot.medicationLogs.isEmpty {
                ForEach(snapshot.medicationSchedules, id: \.scheduleID) { schedule in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.name)
                            .font(.subheadline).bold()
                        Text(schedule.dose)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            } else {
                ForEach(snapshot.medicationLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.medicationSchedules.first(where: { $0.scheduleID == log.scheduleID })?.name ?? "Medication")
                            .font(.subheadline).bold()
                        Text(DateFormatter.localizedString(from: log.scheduledTime, dateStyle: .none, timeStyle: .short))
                            .font(.caption)
                        .foregroundColor(.secondary)
                    Text(statusText(for: log))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
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

    private func countdownText(for log: MedicationLog) -> String {
        switch log.status {
        case .taken:
            if let takenAt = log.takenAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                return "Taken " + formatter.localizedString(for: takenAt, relativeTo: Date())
            }
            return "Taken"
        case .missed:
            let minutes = minutesUntil(log.scheduledTime)
            return "Missed \(abs(minutes)) min ago"
        case .upcoming:
            let minutes = minutesUntil(log.scheduledTime)
            if minutes > 60 {
                return "Due in \(minutes / 60)h \(minutes % 60)m"
            } else if minutes > 0 {
                return "Due in \(minutes) min"
            } else if minutes == 0 {
                return "Due now"
            } else {
                return "Overdue \(abs(minutes)) min"
            }
        case .skipped:
            return "Skipped"
        }
    }

    private func minutesUntil(_ date: Date) -> Int {
        Int(date.timeIntervalSinceNow / 60)
    }

    @ViewBuilder
    private var ownerMedicationsContent: some View {
        VStack(spacing: 20) {
            MedicationsOverviewHeaderView(taken: viewModel.takenCount,
                                          missed: viewModel.missedCount,
                                          upcoming: viewModel.upcomingCount,
                                          adherence: viewModel.adherencePercentage,
                                          nextDose: viewModel.nextDose,
                                          countdownText: viewModel.countdownText,
                                          urgency: viewModel.nextDoseUrgency,
                                          onMarkNext: {
                                              if let next = viewModel.nextDose {
                                                  withAnimation(.easeInOut) {
                                                      viewModel.markTaken(logID: next.id)
                                                  }
                                              }
                                          })

            if viewModel.todayLogsSorted.isEmpty {
                MedicationEmptyStateCard {
                    showAddMedication = true
                }
            } else {
                ForEach(MedicationTime.allCases, id: \.self) { slot in
                    MedicationSectionCard(time: slot,
                                         logs: logs(for: slot),
                                         highlightedLogID: highlightedLogID,
                                         countdownProvider: countdownText(for:),
                                         onTake: { log in
                                             withAnimation(.easeInOut) {
                                                 viewModel.markTaken(logID: log.id)
                                             }
                                         },
                                         onSkip: { log in
                                             withAnimation(.easeInOut) {
                                                 viewModel.markSkipped(logID: log.id)
                                             }
                                         })
                    .id(slot.rawValue)
                }
            }
        }
    }

    private func statusText(for log: MedicationLogDTO) -> String {
        if log.takenAt != nil { return "Taken" }
        return log.scheduledTime < Date() ? "Missed" : "Upcoming"
    }
}

private struct MedicationsOverviewHeaderView: View {
    var taken: Int
    var missed: Int
    var upcoming: Int
    var adherence: Double
    var nextDose: MedicationLog?
    var countdownText: String
    var urgency: NextDoseUrgency
    var onMarkNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Overview")
                        .font(.title3).bold()
                    Text("Track progress and stay ahead of upcoming doses.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", adherence * 100))
                    .font(.title).bold()
                    .foregroundColor(.accentColor)
            }

            HStack(spacing: 12) {
                statColumn(title: "Taken", value: taken, color: .green)
                statColumn(title: "Missed", value: missed, color: .red)
                statColumn(title: "Upcoming", value: upcoming, color: .orange)
            }

            if let nextDose {
                Divider()
                NextDoseHighlightCard(log: nextDose,
                                      countdownText: countdownText,
                                      urgency: urgency,
                                      onMarkTaken: onMarkNext)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
    }

    private func statColumn(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title3).bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NextDoseHighlightCard: View {
    let log: MedicationLog
    var countdownText: String
    var urgency: NextDoseUrgency
    var onMarkTaken: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Dose")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(log.schedule?.name ?? "Medication")
                .font(.headline)
            Text(log.schedule?.dose ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .font(.subheadline)
                Spacer()
                Text(countdownText)
                    .font(.subheadline)
                    .foregroundColor(color)
            }

            Button(action: onMarkTaken) {
                HStack {
                    Spacer()
                    Text("Mark as Taken")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }

    private var color: Color {
        switch urgency {
        case .normal: return .green
        case .warning: return .orange
        case .overdue: return .red
        }
    }
}

private struct MedicationEmptyStateCard: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "capsule.portrait")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            Text("No schedules yet")
                .font(.headline)
            Text("Add your first medication to start tracking adherence and reminders.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Text("Add Medication")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)
    }
}

private struct MedicationSectionCard: View {
    var time: MedicationTime
    var logs: [MedicationLog]
    var highlightedLogID: UUID?
    var countdownProvider: (MedicationLog) -> String
    var onTake: (MedicationLog) -> Void
    var onSkip: (MedicationLog) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(time.title)
                    .font(.headline)
                Spacer()
                Text(sectionSummary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if logs.isEmpty {
                Text("No \(time.title.lowercased()) doses scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    ForEach(logs) { log in
                        MedicationRowView(log: log,
                                          countdownText: countdownProvider(log),
                                          onTake: { onTake(log) },
                                          onSkip: { onSkip(log) },
                                          isHighlighted: highlightedLogID == log.id)
                            .id(log.id)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 18, y: 8)
    }

    private var sectionSummary: String {
        guard !logs.isEmpty else { return "" }
        let taken = logs.filter { $0.status == .taken }.count
        if taken == logs.count {
            return "All taken"
        }
        let upcoming = logs.filter { $0.status == .upcoming }.count
        if upcoming == logs.count {
            return "All upcoming"
        }
        return "\(taken) of \(logs.count) taken"
    }
}
