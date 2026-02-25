//
//  MedicationView.swift
//  vCare
//

import CoreData
import SwiftUI

struct MedicationView: View {
    @StateObject private var viewModel: MedicationViewModel
    @State private var showAddMedication = false
    @State private var editingSchedule: MedicationSchedule?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: MedicationViewModel(context: context))
    }

    var body: some View {
        List {
            Section {
                summaryCard
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Next dose")) {
                if let next = viewModel.nextMedication {
                    nextMedicationCard(next)
                } else {
                    Text("All caught up for today")
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Today's schedule")) {
                if viewModel.todayLogs.isEmpty {
                    Text("No medications scheduled today")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.todayLogs.sorted(by: { $0.scheduledTime < $1.scheduledTime })) { log in
                        MedicationLogRow(log: log)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    withAnimation { viewModel.markTaken(logID: log.id) }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                } label: {
                                    Label("Taken", systemImage: "checkmark")
                                }
                                .tint(.green)

                                Button {
                                    withAnimation { viewModel.markSkipped(logID: log.id) }
                                } label: {
                                    Label("Skip", systemImage: "forward.end")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editingSchedule = log.schedule
                                    showAddMedication = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .listRowSeparator(.hidden)
        .scrollContentBackground(.hidden)
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
            viewModel.refresh()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            let total = max(1, viewModel.todayLogs.count)
            Text("\(viewModel.takenCount) of \(total) completed")
                .font(.headline)
            ProgressView(value: viewModel.adherencePercentage)
                .tint(.green)
            Text("Adherence \(Int(viewModel.adherencePercentage * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                metric(title: "Taken", value: viewModel.takenCount)
                metric(title: "Missed", value: viewModel.missedCount)
                metric(title: "Upcoming", value: viewModel.upcomingLogs.count)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 8)
    }

    private func nextMedicationCard(_ log: MedicationLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(log.schedule?.name ?? "Upcoming")
                .font(.headline)
            Text(log.schedule?.dose ?? "")
                .foregroundColor(.secondary)
            HStack {
                Label(log.scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                Spacer()
                statusBadge(log.status)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 8)
    }

    private func metric(title: String, value: Int) -> some View {
        VStack(alignment: .leading) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(_ status: MedicationLogStatus) -> some View {
        Text(status.displayName)
            .font(.caption).bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color(for: status).opacity(0.15))
            .foregroundColor(color(for: status))
            .clipShape(Capsule())
    }

    private func color(for status: MedicationLogStatus) -> Color {
        switch status {
        case .taken: return .green
        case .upcoming: return .orange
        case .missed: return .red
        case .skipped: return .gray
        }
    }
}
