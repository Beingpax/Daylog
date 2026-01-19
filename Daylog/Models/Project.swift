//
//  Project.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "circle.fill"
    var sortOrder: Int = 0

    var category: Category?

    @Relationship(deleteRule: .nullify, inverse: \HourLog.project)
    var hourLogs: [HourLog]? = []

    init(name: String, icon: String = "circle.fill", sortOrder: Int = 0, category: Category? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.category = category
    }
}
