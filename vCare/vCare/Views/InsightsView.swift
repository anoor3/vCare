//
//  InsightsView.swift
//  vCare
//

import Charts
import CoreData
import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel: InsightsViewModel

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Weekly Insights")
                    .font(.largeTitle).bold()

                Chart(viewModel.moodSeries) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Mood", point.value)
                    )
                    .foregroundStyle(Color.blue)
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 10)

                Chart(viewModel.energySeries) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Energy", point.value)
                    )
                    .foregroundStyle(Color.green.gradient)
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 10)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Summary")
                        .font(.title3).bold()
                    Text(viewModel.summaryText)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Button("Generate Weekly Summary") {
                        viewModel.generateSummary()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 10)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
