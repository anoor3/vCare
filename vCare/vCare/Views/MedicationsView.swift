
import CoreData
import SwiftUI

struct MedicationsView: View {
    @StateObject private var viewModel: MedicationViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var showAddMedication = false
    @State private var showManageSchedules = false
    @State private var scheduleToEdit: MedicationSchedule?
    @State private var showSchedule = false
    @State private var highlightedLogID: UUID?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MedicationViewModel(context: context))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if AppFeatures.familyPortalEnabled {
                        PortalStatusBannerView()
                    }
                    MedicationsSummaryCardView(
                        completedText: "\(viewModel.takenCount) of \(max(viewModel.todayLogs.count, 1)) completed",
                        progress: viewModel.progressFraction,
                        taken: viewModel.takenCount,
                        missed: viewModel.missedCount,
                        upcoming: viewModel.upcomingCount
                    )

                if AppFeatures.familyPortalEnabled,
                   appState.role == .caregiverPortal,
                   let snapshot = appState.portalSnapshot {
                    portalMedicationsContent(snapshot: snapshot)
                } else if let next = viewModel.nextDose {
                    NextDoseCardView(log: next, countdownText: viewModel.countdownText, urgency: viewModel.nextDoseUrgency) {
                        withAnimation(.easeInOut) {
                            viewModel.markTaken(logID: next.id)
                        }
                    }
                }

                if !(AppFeatures.familyPortalEnabled && appState.role == .caregiverPortal) {
                    DisclosureGroup(isExpanded: $showSchedule) {
                        VStack(spacing: 8) {
                            if viewModel.todayLogsSorted.isEmpty {
                                Text("No medications scheduled today")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                ForEach(viewModel.todayLogsSorted) { log in
                                    MedicationRowView(log: log, onTake: {
                                        withAnimation(.easeInOut) {
                                            viewModel.markTaken(logID: log.id)
                                        }
                                    }, isHighlighted: highlightedLogID == log.id)
                                    .id(log.id)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.markTaken(logID: log.id)
                                        } label: {
                                            Label("Taken", systemImage: "checkmark")
                                        }
                                        .tint(.green)

                                        Button {
                                            viewModel.markSkipped(logID: log.id)
                                        } label: {
                                            Label("Skip", systemImage: "forward.end")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                        }
                        .padding(.top, 12)
                    } label: {
                        HStack {
                            Text("Today's Schedule (\(viewModel.todayLogsSorted.count))")
                                .font(.headline)
                            Spacer()
                            Image(systemName: showSchedule ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
                }
            }
            .padding(24)
        }
        .onReceive(NotificationCenter.default.publisher(for: .medicationDeepLink)) { notification in
                guard let idString = notification.object as? String, let uuid = UUID(uuidString: idString) else { return }
                showSchedule = true
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

    private func statusText(for log: MedicationLogDTO) -> String {
        if log.takenAt != nil { return "Taken" }
        return log.scheduledTime < Date() ? "Missed" : "Upcoming"
    }
}
