import CoreData
import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel: InsightsViewModel
    @ObservedObject private var appState = AppState.shared

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if AppFeatures.familyPortalEnabled {
                    PortalStatusBannerView()
                }
                if AppFeatures.familyPortalEnabled,
                   appState.role == .caregiverPortal,
                   let snapshot = appState.portalSnapshot {
                    portalInsightsContent(snapshot: snapshot)
                } else {
                    Text("Insights")
                        .font(.largeTitle).bold()

                    RangePickerView(selectedRange: $viewModel.selectedRange)

                    if viewModel.isEmptyState {
                        emptyState
                    } else {
                        CareStatusCardView(level: viewModel.careStatus)

                        AlertsCardView(flags: viewModel.flags)

                        AdherenceCardView(metric: viewModel.adherence, trendDelta: viewModel.adherenceTrendDelta)

                        MoodTrendCardView(series: viewModel.moodSeries,
                                           average: viewModel.moodAverage,
                                           delta: viewModel.moodDelta,
                                           trend: viewModel.moodTrend)

                        EnergyTrendCardView(series: viewModel.energySeries,
                                            average: viewModel.energyAverage,
                                            lowest: viewModel.lowestEnergyMetric,
                                            trend: viewModel.energyTrend,
                                            variance: viewModel.energyVariance)

                        SummaryCardView(bullets: viewModel.summaryBullets)
                    }
                }
            }
            .padding(24)
        }
        .animation(.easeInOut, value: viewModel.selectedRange)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Not enough data yet")
                .font(.headline)
            Text("Log care check-ins and medication doses to unlock insights.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }

    private func portalInsightsContent(snapshot: CareShareProfileDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.largeTitle).bold()
            if let summary = snapshot.insightsSummary {
                Text(String(format: "Mood %.1f  • Energy %.0f%%  • Adherence %.0f%%",
                            summary.moodAverage,
                            summary.energyAverage,
                            summary.adherencePercent * 100))
                    .foregroundColor(.secondary)
            }
            SummaryCardView(bullets: snapshot.insightsSummary?.summaryLines ?? ["Ask for an updated share code to refresh analytics."])
        }
    }
}
