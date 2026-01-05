//
//  Mood.swift
//  Daylog
//

import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case focused = "focused"
    case energetic = "energetic"
    case calm = "calm"
    case tired = "tired"
    case stressed = "stressed"
    case happy = "happy"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .focused: return "eye"
        case .energetic: return "bolt.fill"
        case .calm: return "leaf.fill"
        case .tired: return "moon.zzz.fill"
        case .stressed: return "exclamationmark.triangle.fill"
        case .happy: return "face.smiling.fill"
        }
    }

    var color: String {
        switch self {
        case .focused: return "#5856D6"
        case .energetic: return "#FF9500"
        case .calm: return "#34C759"
        case .tired: return "#8E8E93"
        case .stressed: return "#FF3B30"
        case .happy: return "#FFCC00"
        }
    }
}
