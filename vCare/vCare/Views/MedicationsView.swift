
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
        Group {
            if AppFeatures.familyPortalEnabled,
               appState.role == .caregiverPortal,
               let snapshot = appState.portalSnapshot {
                portalMedicationsContent(snapshot: snapshot)
                    .padding(24)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        MedicationsHeaderView(adherence: viewModel.adherencePercentage,
                                              taken: viewModel.takenCount,
                                              missed: viewModel.missedCount,
                                              upcoming: viewModel.upcomingCount)
                        NewMedicationsView(viewModel: viewModel,
                                            appState: appState,
                                            highlightedLogID: $highlightedLogID,
                                            onMarkTaken: { log in viewModel.markTaken(logID: log.id) },
                                            onSkip: { log in viewModel.markSkipped(logID: log.id) },
                                            onUndoSkip: { log in viewModel.undoSkip(logID: log.id) },
                                            onAddMedication: { showAddMedication = true })
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button("Manage") { showManageSchedules = true }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showAddMedication = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddMedication, onDismiss: { viewModel.refresh() }) {
            AddMedicationView(schedule: nil) { schedule in
                viewModel.saveSchedule(schedule)
            }
        }
        .sheet(item: $scheduleToEdit, onDismiss: { viewModel.refresh() }) { schedule in
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
        .onReceive(NotificationCenter.default.publisher(for: .medicationDeepLink)) { notification in
            guard let idString = notification.object as? String,
                  let uuid = UUID(uuidString: idString) else { return }
            highlightedLogID = uuid
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

    private func statusText(for log: MedicationLogDTO) -> String {
        if log.takenAt != nil { return "Taken" }
        return log.scheduledTime < Date() ? "Missed" : "Upcoming"
    }
}
