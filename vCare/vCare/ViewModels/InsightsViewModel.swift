//
//  InsightsViewModel.swift
//  vCare
//

import CoreData
import Foundation

struct MoodPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct EnergyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var moodSeries: [MoodPoint] = []
    @Published var energySeries: [EnergyPoint] = []
    @Published var summaryText: String = ""

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchInsights()
    }

    func fetchInsights() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var moods: [MoodPoint] = []
        var energies: [EnergyPoint] = []

        for offset in (0..<7).reversed() {
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            if let entry = fetchEntry(for: day) {
                moods.append(MoodPoint(date: day, value: Double(entry.mood)))
                energies.append(EnergyPoint(date: day, value: Double(entry.energy)))
            } else {
                moods.append(MoodPoint(date: day, value: 0))
                energies.append(EnergyPoint(date: day, value: 0))
            }
        }

        moodSeries = moods
        energySeries = energies
        summaryText = buildSummary(from: moods, energies: energies)
    }

    func generateSummary() {
        summaryText = buildSummary(from: moodSeries, energies: energySeries)
    }

    private func fetchEntry(for day: Date) -> CareEntry? {
        let request = CareEntryEntity.fetchRequest()
        let calendar = Calendar.current
        let start = day
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? day
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.fetchLimit = 1

        do {
            if let entity = try context.fetch(request).first {
                return CareEntry(entity: entity)
            }
        } catch {
            print("Failed to fetch entry: \(error)")
        }
        return nil
    }

    private func buildSummary(from moods: [MoodPoint], energies: [EnergyPoint]) -> String {
        guard !moods.isEmpty else { return "No data logged this week." }
        let moodValues = moods.map { $0.value }.filter { $0 > 0 }
        let energyValues = energies.map { $0.value }.filter { $0 > 0 }

        let avgMood = moodValues.isEmpty ? 0 : moodValues.reduce(0, +) / Double(moodValues.count)
        let avgEnergy = energyValues.isEmpty ? 0 : energyValues.reduce(0, +) / Double(energyValues.count)
        let missedMedications = countMissedMedications()

        var moodDescriptor = "stable"
        if let first = moodValues.first, let last = moodValues.last, last - first > 1 {
            moodDescriptor = "improving"
        } else if let first = moodValues.first, let last = moodValues.last, first - last > 1 {
            moodDescriptor = "slightly declining"
        }

        let energyPercent = Int(avgEnergy.rounded())
        let formattedMood = String(format: "%.1f", avgMood)

        return "Over the past 7 days, mood remained \(moodDescriptor) averaging \(formattedMood). Energy averaged \(energyPercent)%. Missed medications: \(missedMedications)."
    }

    private func countMissedMedications() -> Int {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isTaken == NO AND time < %@", Date() as NSDate)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
}
