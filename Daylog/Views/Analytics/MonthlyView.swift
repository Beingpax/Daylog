//
//  MonthlyView.swift
//  Daylog
//

import SwiftUI
import SwiftData
import Charts

struct MonthlyView: View {
    @Query private var allLogs: [HourLog]
    @Query(sort: \CategoryGroup.sortOrder) private var categoryGroups: [CategoryGroup]

    @State private var selectedMonth = Date().startOfMonth

    private var logsForMonth: [HourLog] {
        let monthEnd = selectedMonth.adding(months: 1)
        return allLogs.filter { log in
            log.date >= selectedMonth && log.date < monthEnd
        }
    }

    private var totalLoggedHours: Int {
        logsForMonth.count
    }

    private var hoursPerGroup: [(group: CategoryGroup, hours: Int)] {
        var counts: [UUID: Int] = [:]

        for log in logsForMonth {
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

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)!
        return range.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: selectedMonth)
        }
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthNavigator

                    if !hoursPerGroup.isEmpty {
                        calendarHeatmap
                        pieChart
                        trendsView
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Monthly")
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                selectedMonth = selectedMonth.adding(months: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthString)
                    .font(.headline)

                Text("\(totalLoggedHours) hours logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedMonth = selectedMonth.adding(months: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.medium))
            }
            .disabled(selectedMonth >= Date().startOfMonth)
            .opacity(selectedMonth >= Date().startOfMonth ? 0.3 : 1)
        }
        .padding(.vertical, 8)
    }

    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heatmap")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                // Empty cells for offset
                let firstWeekday = Calendar.current.component(.weekday, from: selectedMonth) - 1
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    let logsCount = logsForDay(date).count
                    let intensity = min(Double(logsCount) / 16.0, 1.0) // Max 16 hours as full intensity

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForIntensity(intensity, date: date))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if date.isSameDay(as: Date()) {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForIntensity(intensity, date: Date()))
                        .frame(width: 16, height: 16)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func logsForDay(_ date: Date) -> [HourLog] {
        logsForMonth.filter { $0.date.isSameDay(as: date) }
    }

    private func colorForIntensity(_ intensity: Double, date: Date) -> Color {
        if intensity == 0 {
            return Color(.systemGray5)
        }

        // Find dominant group color for the day
        let logs = logsForDay(date)
        var groupCounts: [String: (count: Int, color: String)] = [:]

        for log in logs {
            if let group = log.category?.group {
                groupCounts[group.name, default: (0, group.colorHex)].count += 1
            }
        }

        let dominantColor = groupCounts.max { $0.value.count < $1.value.count }?.value.color ?? "#34C759"
        return Color(hex: dominantColor).opacity(0.3 + (intensity * 0.7))
    }

    private var pieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Distribution")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Chart(hoursPerGroup, id: \.group.id) { item in
                SectorMark(
                    angle: .value("Hours", item.hours),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color(hex: item.group.colorHex))
            }
            .frame(height: 200)

            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(hoursPerGroup, id: \.group.id) { item in
                    HStack {
                        Circle()
                            .fill(Color(hex: item.group.colorHex))
                            .frame(width: 12, height: 12)

                        Text(item.group.name)
                            .font(.caption)

                        Spacer()

                        Text("\(item.hours)h")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("(\(percentage(item.hours))%)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func percentage(_ hours: Int) -> Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(hours) / Double(totalLoggedHours)) * 100)
    }

    private var trendsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Trend")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            let dailyTotals = daysInMonth.map { date in
                (date: date, count: logsForDay(date).count)
            }

            Chart(dailyTotals, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Hours", item.count)
                )
                .foregroundStyle(Color.accentColor)

                AreaMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Hours", item.count)
                )
                .foregroundStyle(Color.accentColor.opacity(0.1))
            }
            .frame(height: 150)
            .chartYScale(domain: 0...24)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formattedShortDate)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No logs this month")
                .font(.headline)

            Text("Start logging your hours to see monthly insights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    MonthlyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
