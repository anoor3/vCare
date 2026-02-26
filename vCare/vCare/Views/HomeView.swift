//
//  HomeView.swift
//  vCare
//

import CoreData
import SwiftUI
import UIKit

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel: HomeViewModel
    @ObservedObject private var appState = AppState.shared
    @State private var isCheckInExpanded = false

    init(context: NSManagedObjectContext, selectedTab: Binding<AppTab>) {
        self._selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.8, green: 0.95, blue: 0.9).opacity(0.25),
                                    Color(red: 0.78, green: 0.88, blue: 0.98).opacity(0.2)],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    if AppFeatures.familyPortalEnabled {
                        PortalStatusBannerView()
                    }
                    if AppFeatures.familyPortalEnabled,
                       appState.role == .caregiverPortal,
                       let snapshot = appState.portalSnapshot {
                        portalHomeContent(snapshot: snapshot)
                    } else {
                        premiumOwnerContent
                    }

                    // legacy actions remain accessible
                    QuickActionsView(
                        onLogCheckIn: {
                            withAnimation(.easeInOut) {
                                isCheckInExpanded = true
                            }
                        },
                        onAddMedication: { selectedTab = .medications },
                        onViewInsights: { selectedTab = .insights },
                        onStartCalm: { selectedTab = .reset }
                    )

                    DailyCheckInCardView(
                        isExpanded: $isCheckInExpanded,
                        entry: Binding(get: { viewModel.entryDraft }, set: { viewModel.entryDraft = $0 }),
                        didSave: viewModel.didSave,
                        onSelectMood: { viewModel.selectMood($0) },
                        onSave: handleCheckInSave
                    )

                    MedicationSnapshotView(status: viewModel.todayMedicationStatus) {
                        selectedTab = .medications
                    }

                    InsightCardView(insights: viewModel.microInsights)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: heroStatus.headline)
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.refresh() }
    }

    private var premiumOwnerContent: some View {
        VStack(spacing: 24) {
            HeroStatusCardView(data: heroStatus) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                selectedTab = .medications
            }

            MetricsRowView(moodText: moodMetricText,
                           energyText: energyMetricText,
                           streakText: "\(viewModel.streakCount) days")

            OverviewCardView(text: overviewText)
        }
    }

    private func portalHomeContent(snapshot: CareShareProfileDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected to \(snapshot.patientDisplayName)")
                .font(.headline)
            if let summary = snapshot.insightsSummary {
                Text(String(format: "Mood avg %.1f | Energy avg %.0f%% | Adherence %.0f%%",
                            summary.moodAverage,
                            summary.energyAverage,
                            summary.adherencePercent * 100))
                    .foregroundColor(.secondary)
            }
            Text("Ask for an updated share code to refresh this dashboard.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 12)
    }

    private func handleCheckInSave() {
        viewModel.saveEntry()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation(.easeInOut) {
            isCheckInExpanded = false
        }
    }

    private var heroStatus: HeroStatusData {
        let medsRemaining = viewModel.medicationsRemainingToday
        let missed = viewModel.medicationsMissedToday
        let nextSlot = nextMedicationSlot
        let nextDate = nextSlot.flatMap { scheduledDate(for: $0) }
        let countdown = countdownText(for: nextDate)
        let formattedTime = nextDate.map { DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short) } ?? "All caught up"
        let nextName = nextSlot?.title ?? "No doses remaining"

        let headline: String
        let status: HeroStatusData.Status
        let buttonTitle: String
        if missed > 0 {
            headline = missed == 1 ? "1 missed dose — review" : "\(missed) missed doses"
            status = .critical
            buttonTitle = "Take Next Dose"
        } else if medsRemaining > 0 {
            headline = medsRemaining == 1 ? "1 medication remaining" : "\(medsRemaining) medications remaining"
            status = .attention
            buttonTitle = "Take Next Dose"
        } else {
            headline = "All medications taken"
            status = .success
            buttonTitle = "All doses complete"
        }

        return HeroStatusData(
            greeting: viewModel.greeting,
            dateText: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
            headline: headline,
            nextMedicationName: nextName,
            nextMedicationTime: formattedTime,
            countdownText: countdown,
            status: status,
            buttonEnabled: medsRemaining > 0,
            buttonTitle: buttonTitle
        )
    }

    private var moodMetricText: String {
        if let mood = viewModel.todayEntry?.mood {
            return "\(viewModel.emoji(for: mood)) \(moodDescription(for: mood))"
        }
        return "—"
    }

    private var energyMetricText: String {
        if let energy = viewModel.todayEntry?.energy {
            return "\(energy)%"
        }
        return "—"
    }

    private var overviewText: String {
        viewModel.microInsights.first ?? "You're on track. Keep consistency."
    }

    private func moodDescription(for mood: Int) -> String {
        switch mood {
        case 1: return "Low"
        case 2: return "OK"
        case 3: return "Neutral"
        case 4: return "Positive"
        default: return "Great"
        }
    }

    private var nextMedicationSlot: MedicationTime? {
        MedicationTime.allCases.first { viewModel.todayMedicationStatus[$0] != .taken }
    }

    private func scheduledDate(for slot: MedicationTime) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: slot.hourComponent, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private func countdownText(for date: Date?) -> String {
        guard let date else { return "" }
        let minutes = Int(date.timeIntervalSinceNow / 60)
        if minutes > 0 {
            return "In \(minutes) min"
        } else if minutes == 0 {
            return "Due now"
        } else {
            return "Overdue \(abs(minutes)) min"
        }
    }
}

private struct HeroStatusData {
    enum Status {
        case success
        case attention
        case critical

        var color: Color {
            switch self {
            case .success: return Color.green.opacity(0.25)
            case .attention: return Color.orange.opacity(0.25)
            case .critical: return Color.red.opacity(0.25)
            }
        }
    }

    var greeting: String
    var dateText: String
    var headline: String
    var nextMedicationName: String
    var nextMedicationTime: String
    var countdownText: String
    var status: Status
    var buttonEnabled: Bool
    var buttonTitle: String
}

private struct HeroStatusCardView: View {
    let data: HeroStatusData
    var onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.greeting)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(data.dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(data.headline)
                .font(.title2).bold()
                .foregroundColor(.primary)
                .transition(.opacity.combined(with: .slide))

            VStack(alignment: .leading, spacing: 4) {
                Text(data.nextMedicationName)
                    .font(.headline)
                Text(data.nextMedicationTime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(data.countdownText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if data.buttonEnabled {
                actionButton
            } else {
                completionBadge
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(data.status.color, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, y: 12)
    }

    private var actionButton: some View {
        Button(action: onAction) {
            Text(data.buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [Color.green.opacity(0.9), Color.blue.opacity(0.9)],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundColor(.white)
        }
    }

    private var completionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.headline)
            Text(data.buttonTitle)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(colors: [Color.green.opacity(0.9), Color.blue.opacity(0.8)],
                           startPoint: .leading,
                           endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(0.85)
    }
}

private struct MetricsRowView: View {
    var moodText: String
    var energyText: String
    var streakText: String

    var body: some View {
        HStack(spacing: 12) {
            MetricCapsule(title: "Mood", value: moodText, icon: "face.smiling")
            MetricCapsule(title: "Energy", value: energyText, icon: "bolt.fill")
            MetricCapsule(title: "Streak", value: streakText, icon: "flame.fill")
        }
    }
}

private struct MetricCapsule: View {
    var title: String
    var value: String
    var icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline).bold()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(.systemBackground).opacity(0.7))
        .clipShape(Capsule())
    }
}

private struct OverviewCardView: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Overview")
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, y: 8)
    }
}
