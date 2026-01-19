//
//  Category.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#34C759"
    var sortOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Project.category)
    var projects: [Project]? = []

    init(name: String, colorHex: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
