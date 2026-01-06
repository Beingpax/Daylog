//
//  HourBlockView.swift
//  Daylog
//

import SwiftUI

struct HourBlockView: View {
    let hour: Int
    let log: HourLog?
    let isCurrentHour: Bool

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }

    private var categoryColor: Color {
        if let colorHex = log?.category?.group?.colorHex {
            return Color(hex: colorHex)
        }
        return Color(.systemGray4)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Time
            Text(timeLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrentHour ? Color.accentColor : Color.secondary)
                .frame(width: 36, alignment: .trailing)

            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3, height: 36)

            // Content
            if let log = log, let category = log.category {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundStyle(categoryColor)
                        .frame(width: 16)

                    Text(category.name)
                        .font(.subheadline)
                        .lineLimit(1)

                    if !log.notes.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(log.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    if let mood = log.mood {
                        Image(systemName: mood.icon)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: mood.color))
                    }
                }
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background {
            if isCurrentHour {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.08))
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 2) {
        HourBlockView(hour: 9, log: nil, isCurrentHour: false)
        HourBlockView(hour: 10, log: nil, isCurrentHour: true)
        HourBlockView(hour: 11, log: nil, isCurrentHour: false)
    }
    .padding()
}
