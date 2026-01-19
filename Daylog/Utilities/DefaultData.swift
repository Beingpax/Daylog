//
//  DefaultData.swift
//  Daylog
//

import Foundation
import SwiftData

struct DefaultData {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetch(descriptor)) ?? []

        guard existingCategories.isEmpty else { return }

        createDefaultCategories(context: context)
    }

    private static func createDefaultCategories(context: ModelContext) {
        // Work - Green
        let work = Category(name: "Work", colorHex: "#34C759", sortOrder: 0)
        context.insert(work)

        let workProjects = [
            ("VoiceInk", "chevron.left.forwardslash.chevron.right"),
            ("Planning", "calendar"),
            ("Writing", "pencil.line"),
            ("Research", "magnifyingglass"),
            ("Content Creation", "video.fill"),
            ("Communications", "envelope.fill"),
            ("Marketing", "megaphone.fill")
        ]

        for (index, (name, icon)) in workProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: work)
            context.insert(project)
        }

        // Health - Orange
        let health = Category(name: "Health", colorHex: "#FF9500", sortOrder: 1)
        context.insert(health)

        let healthProjects = [
            ("Exercise", "figure.run"),
            ("Sleep", "moon.fill"),
            ("Meals", "fork.knife"),
            ("Walk", "figure.walk"),
            ("Meditation", "figure.mind.and.body"),
            ("Hygiene", "drop.fill")
        ]

        for (index, (name, icon)) in healthProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: health)
            context.insert(project)
        }

        // Growth - Purple
        let growth = Category(name: "Growth", colorHex: "#AF52DE", sortOrder: 2)
        context.insert(growth)

        let growthProjects = [
            ("Reading", "book.fill"),
            ("Learning", "graduationcap.fill"),
            ("Courses", "desktopcomputer"),
            ("Skill Practice", "hammer.fill")
        ]

        for (index, (name, icon)) in growthProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: growth)
            context.insert(project)
        }

        // Relationship - Pink
        let relationship = Category(name: "Relationship", colorHex: "#FF2D55", sortOrder: 3)
        context.insert(relationship)

        let relationshipProjects = [
            ("Partner Time", "heart.fill"),
            ("Date Night", "heart.circle.fill")
        ]

        for (index, (name, icon)) in relationshipProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: relationship)
            context.insert(project)
        }

        // Family - Blue
        let family = Category(name: "Family", colorHex: "#007AFF", sortOrder: 4)
        context.insert(family)

        let familyProjects = [
            ("Family Time", "house.fill"),
            ("Kids", "figure.and.child.holdinghands"),
            ("Parents", "person.2.fill")
        ]

        for (index, (name, icon)) in familyProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: family)
            context.insert(project)
        }

        // Social - Teal
        let social = Category(name: "Social", colorHex: "#5AC8FA", sortOrder: 5)
        context.insert(social)

        let socialProjects = [
            ("Friends", "person.2.fill"),
            ("Networking", "network"),
            ("Community", "person.3.fill")
        ]

        for (index, (name, icon)) in socialProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: social)
            context.insert(project)
        }

        // Leisure - Yellow
        let leisure = Category(name: "Leisure", colorHex: "#FFCC00", sortOrder: 6)
        context.insert(leisure)

        let leisureProjects = [
            ("Entertainment", "tv.fill"),
            ("Social Media", "iphone"),
            ("Gaming", "gamecontroller.fill"),
            ("Hobbies", "paintpalette.fill")
        ]

        for (index, (name, icon)) in leisureProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: leisure)
            context.insert(project)
        }

        // Personal - Gray
        let personal = Category(name: "Personal", colorHex: "#8E8E93", sortOrder: 7)
        context.insert(personal)

        let personalProjects = [
            ("Chores", "sparkles"),
            ("Errands", "cart.fill"),
            ("Travel", "car.fill"),
            ("Finances", "dollarsign.circle.fill")
        ]

        for (index, (name, icon)) in personalProjects.enumerated() {
            let project = Project(name: name, icon: icon, sortOrder: index, category: personal)
            context.insert(project)
        }

        try? context.save()
    }
}
