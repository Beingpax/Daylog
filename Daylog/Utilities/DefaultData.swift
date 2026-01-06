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
            ("VoiceInk", "chevron.left.forwardslash.chevron.right"),
            ("Reading", "book.fill"),
            ("Exercise", "figure.run"),
            ("Planning", "calendar"),
            ("Writing", "pencil.line"),
            ("Research", "magnifyingglass"),
            ("Content Creation", "video.fill"),
            ("Communications", "envelope.fill"),
            ("Marketing", "megaphone.fill"),
            ("Learning", "graduationcap.fill")
        ]

        for (index, (name, icon)) in productiveCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: productive)
            context.insert(category)
        }

        // Time Waste - Red
        let timeWaste = CategoryGroup(name: "Time Waste", colorHex: "#FF3B30", sortOrder: 1)
        context.insert(timeWaste)

        let timeWasteCategories = [
            ("Social Media", "iphone"),
            ("Entertainment", "tv.fill"),
            ("Procrastination", "clock.fill")
        ]

        for (index, (name, icon)) in timeWasteCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: timeWaste)
            context.insert(category)
        }

        // Rest - Purple
        let rest = CategoryGroup(name: "Rest", colorHex: "#AF52DE", sortOrder: 2)
        context.insert(rest)

        let restCategories = [
            ("Sleep", "moon.fill"),
            ("Meals", "fork.knife"),
            ("Meditation", "figure.mind.and.body"),
            ("Walk", "figure.walk")
        ]

        for (index, (name, icon)) in restCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: rest)
            context.insert(category)
        }

        // Neutral - Gray
        let neutral = CategoryGroup(name: "Neutral", colorHex: "#8E8E93", sortOrder: 3)
        context.insert(neutral)

        let neutralCategories = [
            ("Hygiene", "drop.fill"),
            ("Chores", "sparkles"),
            ("Errands", "cart.fill"),
            ("Travel", "car.fill")
        ]

        for (index, (name, icon)) in neutralCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: neutral)
            context.insert(category)
        }

        // Social - Blue
        let social = CategoryGroup(name: "Social", colorHex: "#007AFF", sortOrder: 4)
        context.insert(social)

        let socialCategories = [
            ("Relationship", "heart.circle.fill"),
            ("Family", "house.fill"),
            ("Friends", "person.2.fill")
        ]

        for (index, (name, icon)) in socialCategories.enumerated() {
            let category = Category(name: name, icon: icon, sortOrder: index, group: social)
            context.insert(category)
        }

        try? context.save()
    }
}
