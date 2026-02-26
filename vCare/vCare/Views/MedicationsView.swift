//
//  MedicationView.swift
//  vCare
//

import CoreData
import SwiftUI
import UIKit

struct MedicationsView: View {
    @StateObject private var viewModel: MedicationViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var showAddMedication = false
    @State private var editingSchedule: MedicationSchedule?
    @State private var showSchedule = false
    @State private var highlightedLogID: UUID?
    @State private var scheduleToDelete: MedicationSchedule?

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

                    if viewModel.schedules.isEmpty {
                        emptySchedulePrompt
                    } else {
                        scheduleManagementSection
                    }

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
                                    }, onUndo: {
                                        withAnimation(.easeInOut) {
                                            viewModel.markAsUpcoming(logID: log.id)
                                        }
                                    }, isHighlighted: highlightedLogID == log.id)
                                    .id(log.id)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if log.status == .upcoming || log.status == .missed {
                                            Button {
                                                viewModel.markTaken(logID: log.id)
                                            } label: {
                                                Label("Taken", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                        }

                                        if log.status == .upcoming {
                                            Button {
                                                viewModel.markSkipped(logID: log.id)
                                            } label: {
                                                Label("Skip", systemImage: "forward.end")
                                            }
                                            .tint(.orange)
                                        }

                                        if log.status == .taken || log.status == .skipped {
                                            Button {
                                                viewModel.markAsUpcoming(logID: log.id)
                                            } label: {
                                                Label("Undo", systemImage: "arrow.uturn.backward")
                                            }
                                            .tint(.gray)
                                        }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingSchedule = nil
                    showAddMedication = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddMedication, onDismiss: {
            editingSchedule = nil
            viewModel.refresh()
        }) {
            AddMedicationView(schedule: editingSchedule) { schedule in
                viewModel.saveSchedule(schedule)
            }
        }
        .onAppear {
            viewModel.updateStatusesOnAppear()
            showSchedule = viewModel.nextDose == nil
        }
        .onChange(of: viewModel.nextDose?.id) { newValue in
            if newValue == nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSchedule = true
                }
            }
        }
        .confirmationDialog("Delete medication?", item: $scheduleToDelete) { schedule in
            Button("Delete \(schedule.name)", role: .destructive) {
                viewModel.deleteSchedule(schedule)
            }
            Button("Cancel", role: .cancel) { scheduleToDelete = nil }
        }
    }

    private var emptySchedulePrompt: some View {
        VStack(spacing: 12) {
            Text("No medications saved")
                .font(.headline)
            Text("Add a medication schedule to start tracking doses.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                editingSchedule = nil
                showAddMedication = true
            } label: {
                Label("Add Medication", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 6)
    }

    private var scheduleManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Medications")
                    .font(.headline)
                Spacer()
                Button {
                    editingSchedule = nil
                    showAddMedication = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }

            ForEach(viewModel.schedules) { schedule in
                scheduleRow(for: schedule)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }

    private func scheduleRow(for schedule: MedicationSchedule) -> some View {
        HStack(alignment: .center, spacing: 12) {
            scheduleBadge(for: schedule)
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.subheadline).bold()
                Text(schedule.dose)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formattedTimes(for: schedule))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                Button("Edit") {
                    editingSchedule = schedule
                    showAddMedication = true
                }
                Button("Delete", role: .destructive) {
                    scheduleToDelete = schedule
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func scheduleBadge(for schedule: MedicationSchedule) -> some View {
        Group {
            if let data = schedule.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let symbol = schedule.iconSymbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundColor(.accentColor)
            } else {
                let letter = schedule.name.first.map { String($0).uppercased() } ?? "M"
                Text(letter)
                    .font(.subheadline).bold()
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 40, height: 40)
        .background(schedule.photoData == nil ? Color(.secondarySystemBackground) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formattedTimes(for schedule: MedicationSchedule) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let times = schedule.times.sorted().map { formatter.string(from: $0) }
        if times.isEmpty { return "No times scheduled" }
        return times.joined(separator: ", ")
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
