//
//  Category.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int

    var group: CategoryGroup?

    init(name: String, icon: String = "circle.fill", sortOrder: Int = 0, group: CategoryGroup? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.group = group
    }
}
