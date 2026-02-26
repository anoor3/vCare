import SwiftUI

struct HeroStatusView: View {
    var greeting: String
    var entry: CareEntry?
    var moodEmoji: String?
    var energy: Int?
    var medicationsRemaining: Int
    var streak: Int

    private var statusText: String {
        if medicationsRemaining == 0 {
            return "All medications taken"
        } else if medicationsRemaining == 1 {
            return "1 medication remaining"
        } else {
            return "\(medicationsRemaining) medications remaining"
        }
    }

    private var energyText: String {
        guard let energy else { return "—" }
        return "Energy \(energy)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title3).bold()
                    Text(Date.now, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let emoji = moodEmoji {
                    Text(emoji)
                        .font(.largeTitle)
                }
            }

            Text(statusText)
                .font(.headline)
            Text(energyText)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(streak) days")
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry?.notes ?? "")
                        .lineLimit(1)
                        .font(.subheadline)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
    }
}
