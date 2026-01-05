//
//  DaylogApp.swift
//  Daylog
//

import SwiftUI
import SwiftData

@main
struct DaylogApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CategoryGroup.self,
            Category.self,
            HourLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    DefaultData.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
