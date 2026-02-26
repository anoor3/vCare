import Foundation

enum InsightsRange: Int, CaseIterable, Identifiable {
    case seven = 7
    case fourteen = 14
    case thirty = 30

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .seven: return "7D"
        case .fourteen: return "14D"
        case .thirty: return "30D"
        }
    }

    var days: Int { rawValue }
}
