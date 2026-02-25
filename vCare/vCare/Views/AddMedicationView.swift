//
//  AddMedicationView.swift
//  vCare
//

import SwiftUI

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss

    var schedule: MedicationSchedule?
    var onSave: (MedicationSchedule) -> Void

    @State private var name: String = ""
    @State private var dose: String = ""
    @State private var frequency: MedicationFrequencyType = .daily
    @State private var times: [Date] = [Date()]
    @State private var reminderEnabled = true
    @State private var startDate: Date = Date()
    @State private var includeEndDate = false
    @State private var endDate: Date = Date()
    @State private var notes: String = ""
    @State private var colorTag: String = "blue"

    private let colors: [String: Color] = [
        "blue": .blue,
        "green": .green,
        "orange": .orange,
        "purple": .purple
    ]
    private let colorOrder = ["blue", "green", "orange", "purple"]

    init(schedule: MedicationSchedule? = nil, onSave: @escaping (MedicationSchedule) -> Void) {
        self.schedule = schedule
        self.onSave = onSave
        _name = State(initialValue: schedule?.name ?? "")
        _dose = State(initialValue: schedule?.dose ?? "")
        _frequency = State(initialValue: schedule?.frequencyType ?? .daily)
        _times = State(initialValue: schedule?.times ?? [Date()])
        _reminderEnabled = State(initialValue: schedule?.reminderEnabled ?? true)
        _startDate = State(initialValue: schedule?.startDate ?? Date())
        _includeEndDate = State(initialValue: schedule?.endDate != nil)
        _endDate = State(initialValue: schedule?.endDate ?? Date())
        _notes = State(initialValue: schedule?.notes ?? "")
        _colorTag = State(initialValue: schedule?.colorTag ?? "blue")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Step 1 · Details")) {
                    TextField("Medication name", text: $name)
                    TextField("Dose (e.g. 5mg)", text: $dose)
                }

                Section(header: Text("Step 2 · Frequency")) {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequencyType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Step 3 · Times"), footer: Text("Add the times you need reminders.")) {
                    ForEach(times.indices, id: \.self) { index in
                        HStack {
                            DatePicker("Dose \(index + 1)", selection: Binding(get: {
                                times[index]
                            }, set: { times[index] = $0 }), displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)

                            if times.count > 1 {
                                Button(role: .destructive) {
                                    withAnimation {
                                        times.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }

                    Button {
                        times.append(Date())
                    } label: {
                        Label("Add time", systemImage: "plus.circle")
                    }
                }

                Section(header: Text("Step 4 · Reminders")) {
                    Toggle("Enable reminders", isOn: $reminderEnabled)
                }

                Section(header: Text("Step 5 · Schedule")) {
                    DatePicker("Start date", selection: $startDate, displayedComponents: .date)

                    Toggle("Set end date", isOn: $includeEndDate)
                    if includeEndDate {
                        DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section(header: Text("Final Touches")) {
                    Picker("Color tag", selection: $colorTag) {
                        ForEach(colorOrder, id: \.self) { key in
                            HStack {
                                Circle()
                                    .fill(colors[key] ?? .blue)
                                    .frame(width: 12, height: 12)
                                Text(key.capitalized)
                            }
                            .tag(key)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(schedule == nil ? "Add Medication" : "Edit Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(schedule == nil ? "Save" : "Update", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !dose.trimmingCharacters(in: .whitespaces).isEmpty && !times.isEmpty
    }

    private func save() {
        let sanitizedTimes = times.sorted()
        let schedule = MedicationSchedule(
            id: self.schedule?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            dose: dose.trimmingCharacters(in: .whitespaces),
            frequencyType: frequency,
            times: sanitizedTimes,
            startDate: startDate,
            endDate: includeEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes,
            colorTag: colorTag,
            reminderEnabled: reminderEnabled
        )
        onSave(schedule)
        dismiss()
    }
}
