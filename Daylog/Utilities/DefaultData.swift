//
//  DefaultData.swift
//  Daylog
//

import Foundation
import SwiftData

struct DefaultData {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CategoryGroup>()
        let existingGroups = (try? context.fetch(descriptor)) ?? []

        guard existingGroups.isEmpty else { return }

        createDefaultCategoryGroups(context: context)
    }

    private static func createDefaultCategoryGroups(context: ModelContext) {
        // Productive - Green
        let productive = CategoryGroup(name: "Productive", colorHex: "#34C759", sortOrder: 0)
        context.insert(productive)

        let productiveCategories = [
            ("Deep Work", "brain.head.profile"),
            ("Learning", "book.fill"),
            ("Exercise", "figure.run"),
            ("Building", "hammer.fill"),
            ("Planning", "calendar"),
            ("Admin", "folder.fill"),
            ("Writing", "pencil.line")
        ]

        for (index, (name, icon)) in productiveCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: productive)
            context.insert(category)
        }

        // Non-Productive - Red
        let nonProductive = CategoryGroup(name: "Non-Productive", colorHex: "#FF3B30", sortOrder: 1)
        context.insert(nonProductive)

        let nonProductiveCategories = [
            ("Social Media", "iphone"),
            ("Entertainment", "tv.fill"),
            ("Procrastination", "clock.fill"),
            ("Distraction", "sparkles")
        ]

        for (index, (name, icon)) in nonProductiveCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: nonProductive)
            context.insert(category)
        }

        // Neutral - Gray
        let neutral = CategoryGroup(name: "Neutral", colorHex: "#8E8E93", sortOrder: 2)
        context.insert(neutral)

        let neutralCategories = [
            ("Sleep", "moon.fill"),
            ("Meals", "fork.knife"),
            ("Personal Care", "heart.fill"),
            ("Rest", "cup.and.saucer.fill"),
            ("Errands", "cart.fill")
        ]

        for (index, (name, icon)) in neutralCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: neutral)
            context.insert(category)
        }

        // Social - Blue
        let social = CategoryGroup(name: "Social", colorHex: "#007AFF", sortOrder: 3)
        context.insert(social)

        let socialCategories = [
            ("Girlfriend", "heart.circle.fill"),
            ("Friends", "person.2.fill"),
            ("Family", "house.fill"),
            ("Networking", "network")
        ]

        for (index, (name, icon)) in socialCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: social)
            context.insert(category)
        }

        try? context.save()
    }
}
