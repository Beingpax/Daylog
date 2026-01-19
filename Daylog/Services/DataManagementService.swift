//
//  DataManagementService.swift
//  Daylog
//

import Foundation
import SwiftData

struct DataManagementService {

    /// Deletes all data from the app (HourLogs, Projects, Categories)
    static func deleteAllData(context: ModelContext) throws {
        // Delete all hour logs first (due to relationships)
        let hourLogDescriptor = FetchDescriptor<HourLog>()
        let hourLogs = try context.fetch(hourLogDescriptor)
        for log in hourLogs {
            context.delete(log)
        }

        // Delete all projects
        let projectDescriptor = FetchDescriptor<Project>()
        let projects = try context.fetch(projectDescriptor)
        for project in projects {
            context.delete(project)
        }

        // Delete all categories
        let categoryDescriptor = FetchDescriptor<Category>()
        let categories = try context.fetch(categoryDescriptor)
        for category in categories {
            context.delete(category)
        }

        try context.save()
    }

    /// Resets app to default state - deletes all data and re-seeds with defaults
    static func resetToDefaults(context: ModelContext) throws {
        try deleteAllData(context: context)
        DefaultData.seedIfNeeded(context: context)
    }
}
