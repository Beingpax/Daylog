//
//  WeeklyView.swift
//  Daylog
//

import SwiftUI
import SwiftData
import Charts

struct WeeklyView: View {
    @Query private var allLogs: [HourLog]
    @Query(sort: \CategoryGroup.sortOrder) private var categoryGroups: [CategoryGroup]

    @State private var selectedWeekStart = Date().startOfWeek

    private var weekDates: [Date] {
        (0..<7).map { selectedWeekStart.adding(days: $0) }
    }

    private var logsForWeek: [HourLog] {
        let weekEnd = selectedWeekStart.adding(days: 7)
        return allLogs.filter { log in
            log.date >= selectedWeekStart && log.date < weekEnd
        }
    }

    private var hoursPerGroup: [(group: CategoryGroup, hours: Int)] {
        var counts: [UUID: Int] = [:]

        for log in logsForWeek {
            if let groupId = log.category?.group?.id {
                counts[groupId, default: 0] += 1
            }
        }

        return categoryGroups.compactMap { group in
            if let hours = counts[group.id], hours > 0 {
                return (group: group, hours: hours)
            }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private var hoursPerCategory: [(category: Category, hours: Int)] {
        var counts: [UUID: Int] = [:]

        for log in logsForWeek {
            if let categoryId = log.category?.id {
                counts[categoryId, default: 0] += 1
            }
        }

        let allCategories = categoryGroups.flatMap { $0.categories }
        return allCategories.compactMap { category in
            if let hours = counts[category.id], hours > 0 {
                return (category: category, hours: hours)
            }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private var totalLoggedHours: Int {
        logsForWeek.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weekNavigator

                    miniTimeline

                    if !hoursPerGroup.isEmpty {
                        groupBreakdownChart
                        categoryBreakdownList
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly")
        }
    }

    private var weekNavigator: some View {
        HStack {
            Button {
                selectedWeekStart = selectedWeekStart.adding(weeks: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeString)
                    .font(.headline)

                Text("\(totalLoggedHours) hours logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedWeekStart = selectedWeekStart.adding(weeks: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.medium))
            }
            .disabled(selectedWeekStart >= Date().startOfWeek)
            .opacity(selectedWeekStart >= Date().startOfWeek ? 0.3 : 1)
        }
        .padding(.vertical, 8)
    }

    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: selectedWeekStart)
        let end = formatter.string(from: selectedWeekStart.adding(days: 6))
        return "\(start) - \(end)"
    }

    private var miniTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Overview")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    DayColumnView(date: date, logs: logsForDay(date))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func logsForDay(_ date: Date) -> [HourLog] {
        logsForWeek.filter { $0.date.isSameDay(as: date) }
    }

    private var groupBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category Group")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Chart(hoursPerGroup, id: \.group.id) { item in
                BarMark(
                    x: .value("Hours", item.hours),
                    y: .value("Group", item.group.name)
                )
                .foregroundStyle(Color(hex: item.group.colorHex))
                .cornerRadius(4)
            }
            .frame(height: CGFloat(hoursPerGroup.count * 44))
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ForEach(hoursPerCategory.prefix(10), id: \.category.id) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .frame(width: 24)
                        .foregroundStyle(Color(hex: item.category.group?.colorHex ?? "#8E8E93"))

                    Text(item.category.name)

                    Spacer()

                    Text("\(item.hours)h")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    ProgressView(value: Double(item.hours), total: Double(totalLoggedHours))
                        .frame(width: 60)
                        .tint(Color(hex: item.category.group?.colorHex ?? "#8E8E93"))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No logs this week")
                .font(.headline)

            Text("Start logging your hours to see insights here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct DayColumnView: View {
    let date: Date
    let logs: [HourLog]

    private var logsByHour: [Int: HourLog] {
        Dictionary(uniqueKeysWithValues: logs.map { ($0.hour, $0) })
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(date.shortDayOfWeek)
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(spacing: 1) {
                ForEach(6..<24, id: \.self) { hour in
                    Rectangle()
                        .fill(colorForHour(hour))
                        .frame(height: 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .frame(maxWidth: .infinity)
    }

    private func colorForHour(_ hour: Int) -> Color {
        if let log = logsByHour[hour], let colorHex = log.category?.group?.colorHex {
            return Color(hex: colorHex)
        }
        return Color(.systemGray4)
    }
}

#Preview {
    WeeklyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
