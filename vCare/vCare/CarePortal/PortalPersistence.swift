import Foundation

final class PortalPersistence {
    static let shared = PortalPersistence()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    private var snapshotURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("portal_snapshot.json")
    }

    func saveSnapshot(_ snapshot: CareShareProfileDTO) {
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: snapshotURL)
        KeychainStore.shared.saveRole(isCaregiver: true)
        KeychainStore.shared.saveShareInfo(id: snapshot.shareID, patientName: snapshot.patientDisplayName)
    }

    func loadSnapshot() -> CareShareProfileDTO? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? decoder.decode(CareShareProfileDTO.self, from: data)
    }

    func clearSnapshot() {
        try? FileManager.default.removeItem(at: snapshotURL)
        KeychainStore.shared.clear()
    }
}
