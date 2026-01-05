//
//  HourLog.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class HourLog {
    var id: UUID
    var date: Date
    var hour: Int
    var notes: String
    var moodRaw: String
    var extraDetails: String
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    var mood: Mood? {
        get { Mood(rawValue: moodRaw) }
        set { moodRaw = newValue?.rawValue ?? "" }
    }

    init(date: Date, hour: Int, category: Category? = nil, notes: String = "", mood: Mood? = nil, extraDetails: String = "") {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.hour = hour
        self.category = category
        self.notes = notes
        self.moodRaw = mood?.rawValue ?? ""
        self.extraDetails = extraDetails
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var formattedHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    var hourRange: String {
        let startHour = hour
        let endHour = (hour + 1) % 24

        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var startComponents = DateComponents()
        startComponents.hour = startHour
        var endComponents = DateComponents()
        endComponents.hour = endHour

        if let startDate = Calendar.current.date(from: startComponents),
           let endDate = Calendar.current.date(from: endComponents) {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
        return "\(startHour):00 - \(endHour):00"
    }
}
