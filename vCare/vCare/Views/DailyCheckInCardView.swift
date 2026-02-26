
import SwiftUI

struct DailyCheckInCardView: View {
    @Binding var isExpanded: Bool
    @Binding var entry: CareEntry
    var didSave: Bool
    var onSelectMood: (Int) -> Void
    var onSave: () -> Void

    @FocusState private var notesFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Daily Check-In")
                        .font(.title3).bold()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            collapsedMetrics

            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    MoodSelectorView(selectedMood: entry.mood) { onSelectMood($0) }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Energy")
                                .font(.headline)
                            Spacer()
                            Text("\(entry.energy)%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: Binding(get: {
                            Double(entry.energy)
                        }, set: { entry.energy = Int($0) }), in: 0...100, step: 1)
                            .accessibilityLabel("Energy level")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextEditor(text: Binding(get: {
                            entry.notes
                        }, set: { entry.notes = $0 }))
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .focused($notesFocused)
                    }

                    Toggle(isOn: Binding(get: {
                        entry.medicationTaken
                    }, set: { entry.medicationTaken = $0 })) {
                        Label("Medication taken", systemImage: "checkmark.circle")
                            .font(.headline)
                    }
                    .toggleStyle(.switch)
                    .tint(.green)

                    Button(action: {
                        notesFocused = false
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        onSave()
                    }) {
                        HStack {
                            Spacer()
                            Text(didSave ? "Saved" : "Save Entry")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .scaleEffect(didSave ? 0.95 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: didSave)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
    }

    private var collapsedMetrics: some View {
        HStack(spacing: 16) {
            summaryTile(title: "Mood", value: entry.mood == 0 ? "-" : emoji(for: entry.mood))
            summaryTile(title: "Energy", value: "\(entry.energy)%")
            summaryTile(title: "Meds", value: entry.medicationTaken ? "Taken" : "Pending")
        }
    }

    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "🙁"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }
}
