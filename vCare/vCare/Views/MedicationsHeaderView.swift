import SwiftUI

struct MedicationsHeaderView: View {
    var adherence: Double
    var taken: Int
    var missed: Int
    var upcoming: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greeting)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Today’s medications")
                .font(.title2).bold()
            HStack(spacing: 12) {
                statColumn(title: "Taken", value: "\(taken)")
                statColumn(title: "Missed", value: "\(missed)")
                statColumn(title: "Upcoming", value: "\(upcoming)")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", adherence * 100))
                        .font(.title2).bold()
                    Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(22)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(LinearGradient(colors: [Color(red: 0.91, green: 0.95, blue: 1.0),
                                                Color(red: 0.85, green: 0.92, blue: 1.0)],
                                      startPoint: .topLeading,
                                      endPoint: .bottomTrailing), lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, y: 8)
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}
