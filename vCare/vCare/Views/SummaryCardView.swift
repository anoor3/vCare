import SwiftUI

struct SummaryCardView: View {
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Summary")
                    .font(.headline)
                Spacer()
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
            }
            ForEach(bullets, id: \.self) { bullet in
                Text(bullet)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
    }
}
