//
//  vCareApp.swift
//  vCare
//
//  Created by Abdullah Noor on 2/24/26.
//

import SwiftUI

@main
struct vCareApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
