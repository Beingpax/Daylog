//
//  WeeklyComponents.swift
//  Daylog
//
//  Reusable components for WeeklyView
//

import SwiftUI

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trendUp: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(color)

            HStack(spacing: 2) {
                Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(subtitle)
                    .font(.caption2)
            }
            .foregroundStyle(trendUp ? .green : .red)
            .opacity(subtitle.contains("Same") || subtitle.contains("No prior") ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Daily Bar Row

struct DailyBarRow: View {
    let date: Date
    let logs: [HourLog]
    let categoryGroups: [CategoryGroup]
    let isToday: Bool

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var groupDistribution: [(group: CategoryGroup, count: Int)] {
        var counts: [UUID: Int] = [:]
        for log in logs {
            if let groupId = log.category?.group?.id {
                counts[groupId, default: 0] += 1
            }
        }
        return categoryGroups.compactMap { group in
            if let count = counts[group.id], count > 0 {
                return (group: group, count: count)
            }
            return nil
        }.sorted { $0.count > $1.count }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(dayLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(dateLabel)
                    .font(.subheadline.weight(isToday ? .bold : .medium).monospacedDigit())
                    .foregroundStyle(isToday ? .blue : .primary)
            }
            .frame(width: 32)

            if logs.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 24)
            } else {
                GeometryReader { geo in
                    HStack(spacing: 1) {
                        ForEach(groupDistribution, id: \.group.id) { item in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: item.group.colorHex))
                                .frame(width: max(4, geo.size.width * CGFloat(item.count) / 24))
                        }
                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 24)
            }

            Text("\(logs.count)h")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Insight

struct Insight {
    let icon: String
    let color: Color
    let text: String
}

struct InsightRow: View {
    let insight: Insight

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

// MARK: - Analytics Card Container

struct AnalyticsCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            content
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Empty State

struct AnalyticsEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Time Period Navigator

struct TimePeriodNavigator: View {
    let title: String
    let subtitle: String?
    let canGoForward: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canGoForward ? .primary : .tertiary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .disabled(!canGoForward)
        }
    }
}
