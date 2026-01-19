//
//  Project.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int

    var category: Category?

    init(name: String, icon: String = "circle.fill", sortOrder: Int = 0, category: Category? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.category = category
    }
}
