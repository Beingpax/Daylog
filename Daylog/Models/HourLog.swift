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
    var productivityLevel: Int  // 1-10: 1 = idle, 10 = peak
    var createdAt: Date
    var updatedAt: Date

    var category: Category?

    init(date: Date, hour: Int, category: Category? = nil, notes: String = "", productivityLevel: Int = 5) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.hour = hour
        self.category = category
        self.notes = notes
        self.productivityLevel = productivityLevel
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

    var productivityLabel: String {
        switch productivityLevel {
        case 1: return "Idle"
        case 2: return "Stalled"
        case 3: return "Slow"
        case 4: return "Sluggish"
        case 5: return "Steady"
        case 6: return "Active"
        case 7: return "Focused"
        case 8: return "Driven"
        case 9: return "Flowing"
        case 10: return "Peak"
        default: return ""
        }
    }

    var productivityColor: String {
        switch productivityLevel {
        case 1...3: return "#FF3B30"   // Red
        case 4...6: return "#FF9500"   // Orange
        case 7...9: return "#34C759"   // Green
        case 10: return "#007AFF"      // Blue
        default: return "#8E8E93"
        }
    }
}
