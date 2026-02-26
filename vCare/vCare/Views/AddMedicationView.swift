//
//  AddMedicationView.swift
//  vCare
//

import SwiftUI
import UIKit

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
    @State private var iconSymbol: String? = nil
    @State private var photoData: Data? = nil
    @State private var showPhotoSourceDialog = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    private let colors: [String: Color] = [
        "blue": .blue,
        "green": .green,
        "orange": .orange,
        "purple": .purple
    ]
    private let colorOrder = ["blue", "green", "orange", "purple"]
    private let iconOptions = [
        "pills",
        "cross.case.fill",
        "bandage.fill",
        "syringe",
        "face.smiling",
        "drop.circle.fill",
        "capsule.portrait.fill",
        "cross.circle.fill"
    ]
    private let visualColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

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
        _iconSymbol = State(initialValue: schedule?.iconSymbol)
        _photoData = State(initialValue: schedule?.photoData)
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

                TimesSectionView(times: $times)

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

                Section(header: Text("Visual ID"), footer: Text("Add an icon or photo so you can instantly recognize the medication.")) {
                    LazyVGrid(columns: visualColumns, spacing: 12) {
                        visualIDCard(title: "None", isSelected: iconSymbol == nil && photoData == nil) {
                            Image(systemName: "slash.circle")
                                .font(.title2)
                        } action: {
                            iconSymbol = nil
                            photoData = nil
                        }

                        visualIDCard(title: "Photo", isSelected: photoData != nil) {
                            if let image = selectedImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                            }
                        } action: {
                            showPhotoSourceDialog = true
                        }

                        ForEach(iconOptions, id: \.self) { icon in
                            visualIDCard(title: iconDisplayName(icon), isSelected: iconSymbol == icon && photoData == nil) {
                                Image(systemName: icon)
                                    .font(.title2)
                            } action: {
                                iconSymbol = icon
                                photoData = nil
                            }
                        }
                    }
                }
            }
            .navigationTitle(schedule == nil ? "Add Medication" : "Edit Medication")
            .toolbar(content: toolbarContent)
        }
        .confirmationDialog("Medication Photo", isPresented: $showPhotoSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    imagePickerSource = .camera
                    showImagePicker = true
                }
            }
            Button("Choose from Library") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            if photoData != nil {
                Button("Remove Photo", role: .destructive) {
                    photoData = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: imagePickerSource) { image in
                if let image {
                    photoData = image.jpegData(compressionQuality: 0.85)
                    iconSymbol = nil
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !dose.trimmingCharacters(in: .whitespaces).isEmpty && !times.isEmpty
    }

    private func save() {
        let sanitizedTimes = times.sorted()
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = includeEndDate ? calendar.startOfDay(for: endDate) : nil
        let schedule = MedicationSchedule(
            id: self.schedule?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            dose: dose.trimmingCharacters(in: .whitespaces),
            frequencyType: frequency,
            times: sanitizedTimes,
            startDate: normalizedStart,
            endDate: normalizedEnd,
            notes: notes.isEmpty ? nil : notes,
            colorTag: colorTag,
            reminderEnabled: reminderEnabled,
            iconSymbol: iconSymbol,
            photoData: photoData
        )
        onSave(schedule)
        dismiss()
    }

    private var selectedImage: Image? {
        guard let data = photoData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    @ViewBuilder
    private func visualIDCard<Content: View>(title: String, isSelected: Bool, @ViewBuilder content: () -> Content, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                content()
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .frame(height: 110)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func iconDisplayName(_ symbol: String) -> String {
        symbol
            .replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(schedule == nil ? "Save" : "Update", action: save)
                .disabled(!canSave)
        }
    }
}

private struct TimesSectionView: View {
    @Binding var times: [Date]

    var body: some View {
        Section(header: Text("Step 3 · Times"), footer: Text("Add the times you need reminders.")) {
            ForEach(times.indices, id: \.self) { index in
                TimePickerRow(
                    index: index,
                    date: $times[index],
                    canDelete: times.count > 1,
                    onDelete: { removeTime(at: index) }
                )
            }

            Button {
                times.append(Date())
            } label: {
                Label("Add time", systemImage: "plus.circle")
            }
        }
    }

    private func removeTime(at index: Int) {
        guard times.indices.contains(index) else { return }
        withAnimation {
            times.remove(at: index)
            if times.isEmpty {
                times.append(Date())
            }
        }
    }
}

private struct TimePickerRow: View {
    let index: Int
    var date: Binding<Date>
    var canDelete: Bool
    var onDelete: () -> Void

    var body: some View {
        HStack {
            DatePicker("Dose \(index + 1)", selection: date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)

            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

private struct ImagePickerView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onDismiss: (UIImage?) -> Void

        init(onDismiss: @escaping (UIImage?) -> Void) {
            self.onDismiss = onDismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.onDismiss(nil)
            }
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true) {
                self.onDismiss(image)
            }
        }
    }
}
