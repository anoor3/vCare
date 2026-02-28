
import SwiftUI

struct QuickActionsView: View {
    var onLogCheckIn: () -> Void
    var onAddMedication: () -> Void
    var onViewInsights: () -> Void
    var onStartCalm: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                actionButton(title: "Log Check-In", icon: "square.and.pencil", color: .blue, action: onLogCheckIn)
                actionButton(title: "Add Medication", icon: "pills", color: .green, action: onAddMedication)
                actionButton(title: "View Insights", icon: "chart.bar", color: .purple, action: onViewInsights)
                actionButton(title: "Calm Moment", icon: "wind", color: .orange, action: onStartCalm)
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
            }
            .padding(18)
            .frame(width: 160, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}
