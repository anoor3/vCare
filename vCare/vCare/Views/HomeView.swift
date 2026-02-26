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
        ScrollView {
            VStack(spacing: 16) {
                if AppFeatures.familyPortalEnabled {
                    PortalStatusBannerView()
                }
                if AppFeatures.familyPortalEnabled,
                   appState.role == .caregiverPortal,
                   let snapshot = appState.portalSnapshot {
                    portalHomeContent(snapshot: snapshot)
                } else {
                    ownerHomeContent
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut, value: viewModel.todayEntry?.id)
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.refresh()
        }
    }

    private var ownerHomeContent: some View {
        VStack(spacing: 16) {
            HeroStatusView(
                greeting: viewModel.greeting,
                entry: viewModel.todayEntry,
                moodEmoji: viewModel.todayEntry.map { viewModel.emoji(for: $0.mood) },
                energy: viewModel.todayEntry?.energy,
                medicationsRemaining: viewModel.medicationsRemainingToday,
                streak: viewModel.streakCount
            )

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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func handleCheckInSave() {
        viewModel.saveEntry()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation(.easeInOut) {
            isCheckInExpanded = false
        }
    }
}
