//
//  HourLog.swift
//  Daylog
//

import Foundation
import SwiftData

@Model
final class HourLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var hour: Int = 0
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var project: Project?

    init(date: Date, hour: Int, project: Project? = nil, notes: String = "") {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.hour = hour
        self.project = project
        self.notes = notes
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
}
