
import SwiftUI

struct InsightCardView: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Insights")
                .font(.title3).bold()

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.accentColor)
                        .padding(.top, 2)
                    Text(insight)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
    }
}
