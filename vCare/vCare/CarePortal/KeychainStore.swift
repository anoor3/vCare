import Foundation

final class KeychainStore {
    static let shared = KeychainStore()
    private let defaults = UserDefaults.standard
    private let roleKey = "vcare.portal.role"
    private let shareIDKey = "vcare.portal.shareid"
    private let patientNameKey = "vcare.portal.patientname"

    func saveRole(isCaregiver: Bool) {
        defaults.set(isCaregiver, forKey: roleKey)
    }

    func isCaregiver() -> Bool {
        defaults.bool(forKey: roleKey)
    }

    func saveShareInfo(id: String, patientName: String) {
        defaults.set(id, forKey: shareIDKey)
        defaults.set(patientName, forKey: patientNameKey)
    }

    func loadShareInfo() -> (String, String)? {
        guard let id = defaults.string(forKey: shareIDKey),
              let name = defaults.string(forKey: patientNameKey) else { return nil }
        return (id, name)
    }

    func clear() {
        defaults.removeObject(forKey: roleKey)
        defaults.removeObject(forKey: shareIDKey)
        defaults.removeObject(forKey: patientNameKey)
    }
}
