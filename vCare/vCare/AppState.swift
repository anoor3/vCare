import Foundation
import SwiftUI

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: AppTab = .home
    @Published var highlightedLogID: UUID?
    @Published var role: AppRole = .owner
    @Published var portalSnapshot: CareShareProfileDTO?
    @Published var portalLastUpdated: Date?
    @Published var portalPatientName: String = ""

    private init() {
        if AppFeatures.familyPortalEnabled,
           let snapshot = PortalPersistence.shared.loadSnapshot() {
            portalSnapshot = snapshot
            portalLastUpdated = snapshot.createdAt
            portalPatientName = snapshot.patientDisplayName
            role = .caregiverPortal
        }
    }

    func enterPortal(with snapshot: CareShareProfileDTO) {
        guard AppFeatures.familyPortalEnabled else { return }
        portalSnapshot = snapshot
        portalLastUpdated = snapshot.createdAt
        portalPatientName = snapshot.patientDisplayName
        role = .caregiverPortal
        PortalPersistence.shared.saveSnapshot(snapshot)
    }

    func leavePortal() {
        guard AppFeatures.familyPortalEnabled else { return }
        portalSnapshot = nil
        portalLastUpdated = nil
        portalPatientName = ""
        role = .owner
        PortalPersistence.shared.clearSnapshot()
    }
}
