//
//  HourBlockView.swift
//  Daylog
//

import SwiftUI

struct HourBlockView: View {
    let hour: Int
    let log: HourLog?
    let isCurrentHour: Bool
    var isSelectMode: Bool = false
    var isSelected: Bool = false
    let onTap: () -> Void

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private var blockColor: Color {
        if let hex = log?.category?.group?.colorHex {
            return Color(hex: hex)
        }
        return Color(.systemGray5)
    }

    private var isLogged: Bool {
        log?.category != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Selection circle (in select mode)
                if isSelectMode {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color(.tertiaryLabel), lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 22, height: 22)

                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 8)
                }

                // Time label - outside the block
                Text(timeLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
                    .padding(.trailing, 8)

                // Visual block
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(blockColor.opacity(isLogged ? 1 : 0.4))
                        .frame(height: 44)

                    // Content
                    if let log = log, let category = log.category {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.subheadline)

                            Text(category.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            if !log.notes.isEmpty {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                    .opacity(0.7)
                            }

                            Text("\(log.productivityLevel)")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.25), in: Capsule())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                    }

                    // Current hour indicator
                    if isCurrentHour {
                        HStack {
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: 3, height: 28)
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 4) {
        HourBlockView(hour: 9, log: nil, isCurrentHour: false, onTap: {})
        HourBlockView(hour: 10, log: nil, isCurrentHour: true, onTap: {})
        HourBlockView(hour: 11, log: nil, isCurrentHour: false, onTap: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
