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
    var energyLevel: Int  // 1-10: 1 = lethargic, 10 = focused & driven
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    init(date: Date, hour: Int, category: Category? = nil, notes: String = "", energyLevel: Int = 5) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.hour = hour
        self.category = category
        self.notes = notes
        self.energyLevel = energyLevel
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

    var energyLabel: String {
        switch energyLevel {
        case 1...3: return "Low"
        case 4...6: return "Medium"
        case 7...9: return "High"
        case 10: return "Peak"
        default: return ""
        }
    }

    var energyColor: String {
        switch energyLevel {
        case 1...3: return "#FF3B30"   // Red
        case 4...6: return "#FF9500"   // Orange
        case 7...9: return "#34C759"   // Green
        case 10: return "#007AFF"      // Blue
        default: return "#8E8E93"
        }
    }
}
