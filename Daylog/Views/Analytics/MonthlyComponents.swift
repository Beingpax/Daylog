//
//  MonthlyComponents.swift
//  Daylog
//
//  Reusable components for MonthlyView
//

import SwiftUI

// MARK: - Monthly Insight

struct MonthlyInsight {
    let icon: String
    let color: Color
    let text: String
}

struct MonthlyInsightRow: View {
    let insight: MonthlyInsight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.subheadline)
                .foregroundStyle(insight.color)
                .frame(width: 28, height: 28)
                .background(insight.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            Text(insight.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Day of Week Bar

struct DayOfWeekBar: View {
    let day: String
    let percentage: Double
    let isHighest: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 80)

                RoundedRectangle(cornerRadius: 4)
                    .fill(isHighest ? Color.green : Color.blue)
                    .frame(width: 32, height: max(4, 80 * percentage))
            }

            Text(day)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Distribution Row

struct CategoryDistributionRow: View {
    let name: String
    let colorHex: String
    let hours: Int
    let percentage: Int
    let totalHours: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 10, height: 10)

                Text(name)
                    .font(.subheadline)

                Spacer()

                Text("\(hours)h")
                    .font(.subheadline.weight(.medium).monospacedDigit())

                Text("(\(percentage)%)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(width: 44, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: colorHex))
                        .frame(width: geo.size.width * CGFloat(hours) / CGFloat(max(totalHours, 1)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
