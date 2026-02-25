//
//  HomeView.swift
//  vCare
//

import CoreData
import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel: HomeViewModel
    @State private var isCheckInExpanded = false

    init(context: NSManagedObjectContext, selectedTab: Binding<AppTab>) {
        self._selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }

    var body: some View {
        ScrollView {
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
                    onSave: { viewModel.saveEntry() }
                )

                MedicationSnapshotView(status: viewModel.todayMedicationStatus) {
                    selectedTab = .medications
                }

                InsightCardView(insights: viewModel.microInsights)
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
}
