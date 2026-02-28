import SwiftUI

struct ManageSchedulesView: View {
    @ObservedObject var viewModel: MedicationViewModel
    var onEdit: (MedicationSchedule) -> Void
    var onClose: () -> Void

    @State private var scheduleToDelete: MedicationSchedule?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    if viewModel.schedules.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.schedules) { schedule in
                                scheduleCard(for: schedule)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(
                LinearGradient(colors: [Color(red: 0.95, green: 0.97, blue: 1.0),
                                        Color(red: 0.9, green: 0.96, blue: 0.94)],
                               startPoint: .top,
                               endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Manage Medications")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
            .alert("Delete medication?", isPresented: Binding(get: {
                scheduleToDelete != nil
            }, set: { value in
                if !value { scheduleToDelete = nil }
            })) {
                Button("Delete", role: .destructive) {
                    if let schedule = scheduleToDelete {
                        viewModel.deleteSchedule(schedule)
                        scheduleToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    scheduleToDelete = nil
                }
            } message: {
                Text("This will remove the schedule and any upcoming reminders.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organize your routines")
                .font(.title3).bold()
            Text("Edit times or remove medications you no longer track. Changes sync instantly across the Home dashboard.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "pills")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            Text("No medications yet")
                .font(.headline)
            Text("Tap the plus button on the Medications screen to add your first schedule.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, y: 6)
    }

    private func scheduleCard(for schedule: MedicationSchedule) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(color(for: schedule.colorTag))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "pills.fill").foregroundColor(.white))

                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.name)
                        .font(.headline)
                    Text(schedule.dose)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                TagView(text: schedule.frequencyType.displayName)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "clock", text: timeSummary(for: schedule))
                infoRow(icon: "bell", text: schedule.reminderEnabled ? "Reminders on" : "Reminders off")
                infoRow(icon: "calendar", text: "Starts \(formatted(date: schedule.startDate))")
            }

            HStack(spacing: 12) {
                Button {
                    requestEdit(schedule)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    scheduleToDelete = schedule
                } label: {
                    Label("Remove", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 20, y: 10)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func formatted(date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func timeSummary(for schedule: MedicationSchedule) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let times = schedule.times.sorted().map { formatter.string(from: $0) }
        return times.joined(separator: " • ")
    }

    private func color(for tag: String?) -> LinearGradient {
        let base: Color
        switch tag {
        case "green": base = .green
        case "orange": base = .orange
        case "purple": base = .purple
        case "blue": base = .blue
        default: base = .teal
        }
        return LinearGradient(colors: [base.opacity(0.9), base.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func requestEdit(_ schedule: MedicationSchedule) {
        onClose()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onEdit(schedule)
        }
    }
}

private struct TagView: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.caption).bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}
