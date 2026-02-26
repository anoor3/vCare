
import SwiftUI

struct MoodSelectorView: View {
    let selectedMood: Int
    var onSelect: (Int) -> Void

    private let moods = [1, 2, 3, 4, 5]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood")
                .font(.headline)
            HStack(spacing: 16) {
                ForEach(moods, id: \.self) { mood in
                    Button {
                        onSelect(mood)
                    } label: {
                        Text(emoji(for: mood))
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background(background(for: mood))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(mood == selectedMood ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .accessibilityLabel(label(for: mood))
                    .buttonStyle(.plain)
                }
            }
        }
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

    private func background(for mood: Int) -> Color {
        mood == selectedMood ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground)
    }

    private func label(for mood: Int) -> String {
        switch mood {
        case 1: return "Very low mood"
        case 2: return "Low mood"
        case 3: return "Neutral mood"
        case 4: return "Positive mood"
        default: return "Very positive mood"
        }
    }
}
