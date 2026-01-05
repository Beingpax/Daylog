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
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour):00"
    }

    private var categoryColor: Color {
        if let colorHex = log?.category?.group?.colorHex {
            return Color(hex: colorHex)
        }
        return Color(.systemGray5)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(timeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
                .monospacedDigit()

            RoundedRectangle(cornerRadius: 4)
                .fill(categoryColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                if let log = log, let category = log.category {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(categoryColor)

                        Text(category.name)
                            .font(.subheadline.weight(.medium))
                    }

                    if !log.notes.isEmpty {
                        Text(log.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let mood = log.mood {
                        HStack(spacing: 4) {
                            Image(systemName: mood.icon)
                                .font(.caption2)
                            Text(mood.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(Color(hex: mood.color))
                    }
                } else {
                    Text("Not logged")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentHour ? Color.accentColor.opacity(0.08) : Color(.systemBackground))
        }
        .overlay {
            if isCurrentHour {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

#Preview {
    VStack {
        HourBlockView(hour: 9, log: nil, isCurrentHour: false)
        HourBlockView(hour: 10, log: nil, isCurrentHour: true)
    }
    .padding()
}
