
import CoreData
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var entryDraft: CareEntry = CareEntry(date: Date())
    @Published var didSave = false
    @Published private(set) var todayEntry: CareEntry?
    @Published private(set) var weeklyAverageEnergy: Double = 0
    @Published private(set) var medicationsRemainingToday: Int = 0
    @Published private(set) var streakCount: Int = 0
    @Published private(set) var todayMedicationStatus: [MedicationTime: MedicationStatus] = [:]
    @Published private(set) var microInsights: [String] = []
    @Published private(set) var medicationsMissedToday: Int = 0

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        refresh()
    }

    func refresh() {
        loadTodayEntry()
        weeklyAverageEnergy = calculateWeeklyEnergyAverage()
        updateMedicationSnapshot()
        updateStreak()
        buildInsights()
    }

    func selectMood(_ mood: Int) {
        entryDraft.mood = mood
    }

    func saveEntry() {
        do {
            let entity = try fetchEntity(for: Date()) ?? CareEntryEntity(context: context)
            entryDraft.apply(to: entity)
            try context.save()
            todayEntry = entryDraft
            didSave = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.didSave = false
            }
            refresh()
        } catch {
            print("Failed to save entry: \(error)")
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    func emoji(for mood: Int) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "🙁"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }

    private func loadTodayEntry() {
        if let entity = fetchEntity(for: Date()) {
            let entry = CareEntry(entity: entity)
            todayEntry = entry
            entryDraft = entry
        } else {
            todayEntry = nil
            entryDraft = CareEntry(date: Date())
        }
    }

    private func calculateWeeklyEnergyAverage() -> Double {
        let request = CareEntryEntity.fetchRequest()
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) else {
            return 0
        }
        request.predicate = NSPredicate(format: "date >= %@", start as NSDate)
        do {
            let entries = try context.fetch(request)
            let energies = entries.map { Double($0.energy) }
            guard !energies.isEmpty else { return 0 }
            return energies.reduce(0, +) / Double(energies.count)
        } catch {
            return 0
        }
    }

    private func updateMedicationSnapshot() {
        let logs = fetchTodayMedicationLogs()
        var status: [MedicationTime: MedicationStatus] = [:]
        let upcoming = logs.filter { $0.status == .upcoming }
        let missed = logs.filter { $0.status == .missed }

        for time in MedicationTime.allCases {
            let hourMatches = logs.filter { log in
                let hour = Calendar.current.component(.hour, from: log.scheduledTime)
                return time.contains(hour: hour)
            }

            if hourMatches.isEmpty {
                status[time] = .upcoming
            } else if hourMatches.allSatisfy({ $0.status == .taken }) {
                status[time] = .taken
            } else if hourMatches.contains(where: { $0.status == .missed }) {
                status[time] = .missed
            } else {
                status[time] = .upcoming
            }
        }

        todayMedicationStatus = status
        medicationsRemainingToday = upcoming.count
        medicationsMissedToday = missed.count
    }

    private func buildInsights() {
        var insights: [String] = []
        if let todayEnergy = todayEntry?.energy, todayEnergy < Int(weeklyAverageEnergy.rounded()) {
            insights.append("Energy slightly below weekly average.")
        }

        if let today = todayEntry, let yesterdayEntity = fetchEntity(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            let yesterday = CareEntry(entity: yesterdayEntity)
            if today.mood > yesterday.mood {
                insights.append("Mood improved compared to yesterday.")
            }
        }

        if medicationsMissedToday > 0 {
            let text = medicationsMissedToday == 1 ? "1 medication missed today." : "\(medicationsMissedToday) medications missed today."
            insights.append(text)
        }

        if insights.isEmpty {
            insights.append("You are on track today.")
        }

        microInsights = insights
    }

    private func fetchTodayMedicationLogs() -> [MedicationLog] {
        let request = MedicationLogEntity.fetchRequest()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        do {
            let entities = try context.fetch(request)
            return entities.map { MedicationLog(entity: $0) }
        } catch {
            return []
        }
    }

    private func fetchEntity(for date: Date) -> CareEntryEntity? {
        let request = CareEntryEntity.fetchRequest()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func updateStreak() {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())
        var count = 0

        while fetchEntity(for: day) != nil {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        streakCount = count
    }
}
