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

    // MARK: - Computed Properties

    private var weekDates: [Date] {
        (0..<7).map { selectedWeekStart.adding(days: $0) }
    }

    private var logsForWeek: [HourLog] {
        let weekEnd = selectedWeekStart.adding(days: 7)
        return allLogs.filter { $0.date >= selectedWeekStart && $0.date < weekEnd }
    }

    private var previousWeekLogs: [HourLog] {
        let prevStart = selectedWeekStart.adding(weeks: -1)
        return allLogs.filter { $0.date >= prevStart && $0.date < selectedWeekStart }
    }

    private var totalLoggedHours: Int { logsForWeek.count }
    private var previousWeekHours: Int { previousWeekLogs.count }

    private var productiveHours: Int {
        logsForWeek.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var previousProductiveHours: Int {
        previousWeekLogs.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var avgProductivityLevel: Double {
        guard !logsForWeek.isEmpty else { return 0 }
        return Double(logsForWeek.reduce(0) { $0 + $1.productivityLevel }) / Double(logsForWeek.count)
    }

    private var previousAvgProductivity: Double {
        guard !previousWeekLogs.isEmpty else { return 0 }
        return Double(previousWeekLogs.reduce(0) { $0 + $1.productivityLevel }) / Double(previousWeekLogs.count)
    }

    private var isCurrentWeek: Bool {
        selectedWeekStart >= Date().startOfWeek
    }

    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: selectedWeekStart)
        let end = formatter.string(from: selectedWeekStart.adding(days: 6))
        return "\(start) – \(end)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TimePeriodNavigator(
                        title: weekRangeString,
                        subtitle: isCurrentWeek ? "This Week" : nil,
                        canGoForward: !isCurrentWeek,
                        onPrevious: { withAnimation { selectedWeekStart = selectedWeekStart.adding(weeks: -1) } },
                        onNext: { withAnimation { selectedWeekStart = selectedWeekStart.adding(weeks: 1) } }
                    )

                    if !logsForWeek.isEmpty {
                        insightsSection
                        productivityByTimeOfDay
                        timeDistribution
                    } else {
                        AnalyticsEmptyState(
                            icon: "chart.bar.doc.horizontal",
                            title: "No logs this week",
                            message: "Start logging your hours to see insights"
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly")
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        AnalyticsCard(title: "Insights") {
            VStack(spacing: 8) {
                ForEach(generateInsights(), id: \.text) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
    }

    private func generateInsights() -> [Insight] {
        var insights: [Insight] = []
        let hoursPerGroup = calculateHoursPerGroup()
        let prevHoursPerGroup = calculatePreviousWeekHoursPerGroup()

        // Peak productivity hour
        if let peakHour = peakProductivityHour {
            let hourlyProductivity = calculateHourlyProductivity()
            if let peakData = hourlyProductivity.first(where: { $0.hour == peakHour }), peakData.avgProductivity >= 7 {
                insights.append(Insight(icon: "bolt.fill", color: .orange,
                    text: "Peak productivity at \(formattedHour(peakHour)) — ideal for deep work"))
            }
        }

        // Low productivity detection
        let hourlyProductivity = calculateHourlyProductivity().filter { $0.avgProductivity > 0 }
        if let lowHour = hourlyProductivity.min(by: { $0.avgProductivity < $1.avgProductivity }), lowHour.avgProductivity < 5 && lowHour.avgProductivity > 0 {
            insights.append(Insight(icon: "moon.fill", color: .indigo,
                text: "Productivity lowest at \(formattedHour(lowHour.hour)) — schedule lighter tasks"))
        }

        // Productive time change
        if previousProductiveHours > 0 {
            let change = productiveHours - previousProductiveHours
            let pctChange = Int((Double(change) / Double(previousProductiveHours)) * 100)
            if change >= 3 {
                insights.append(Insight(icon: "arrow.up.right.circle.fill", color: .green,
                    text: "Productive time up \(change)h (+\(pctChange)%) from last week"))
            } else if change <= -3 {
                insights.append(Insight(icon: "arrow.down.right.circle.fill", color: .orange,
                    text: "Productive time down \(abs(change))h from last week"))
            }
        }

        // Category shift
        for group in hoursPerGroup {
            let prevHours = prevHoursPerGroup[group.group.id] ?? 0
            let change = group.hours - prevHours
            if prevHours > 0 && abs(change) >= 5 {
                let icon = change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                let text = change > 0
                    ? "\(group.group.name) up \(change)h (+\(Int((Double(change) / Double(prevHours)) * 100))%) vs last week"
                    : "\(group.group.name) down \(abs(change))h from last week"
                insights.append(Insight(icon: icon, color: Color(hex: group.group.colorHex), text: text))
                break
            }
        }

        // Best day for productivity
        let productiveDayStats = calculateProductiveDayStats()
        if let bestDay = productiveDayStats.max(by: { $0.hours < $1.hours }), bestDay.hours > 0 {
            insights.append(Insight(icon: "star.fill", color: .yellow,
                text: "\(bestDay.day) was most productive (\(bestDay.hours)h of focused work)"))
        }

        // Time allocation
        if let topGroup = hoursPerGroup.first {
            let pct = percentage(topGroup.hours)
            insights.append(Insight(icon: "chart.pie.fill", color: Color(hex: topGroup.group.colorHex),
                text: "\(pct)% of your week spent on \(topGroup.group.name)"))
        }

        return Array(insights.prefix(4))
    }

    // MARK: - Productivity Chart

    private var productivityByTimeOfDay: some View {
        AnalyticsCard(title: "Productivity Pattern", subtitle: peakProductivityHour.map { "Peak: \(formattedHour($0))" }) {
            Chart(calculateHourlyProductivity(), id: \.hour) { item in
                AreaMark(x: .value("Hour", item.hour), y: .value("Productivity", item.avgProductivity))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Hour", item.hour), y: .value("Productivity", item.avgProductivity))
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
            }
            .frame(height: 140)
            .chartXScale(domain: 6...23)
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: [6, 9, 12, 15, 18, 21]) { value in
                    AxisValueLabel {
                        if let hour = value.as(Int.self) { Text(formattedHour(hour)).font(.caption2) }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 5, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4])).foregroundStyle(Color(.systemGray4))
                    AxisValueLabel { if let v = value.as(Int.self) { Text("\(v)").font(.caption2).foregroundStyle(.secondary) } }
                }
            }
        }
    }

    // MARK: - Time Distribution

    private var timeDistribution: some View {
        AnalyticsCard(title: "Time Distribution") {
            let hoursPerGroup = calculateHoursPerGroup()
            if hoursPerGroup.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(hoursPerGroup.prefix(5), id: \.group.id) { item in
                        VStack(spacing: 4) {
                            HStack(spacing: 12) {
                                Circle().fill(Color(hex: item.group.colorHex)).frame(width: 10, height: 10)
                                Text(item.group.name).font(.subheadline)
                                Spacer()
                                Text("\(item.hours)h").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                                Text("(\(percentage(item.hours))%)").font(.caption.monospacedDigit()).foregroundStyle(.tertiary).frame(width: 40, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: item.group.colorHex))
                                        .frame(width: geo.size.width * CGFloat(item.hours) / CGFloat(max(totalLoggedHours, 1)), height: 6)
                                }
                            }.frame(height: 6)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateHourlyProductivity() -> [(hour: Int, avgProductivity: Double)] {
        var hourlySum: [Int: (total: Int, count: Int)] = [:]
        for log in logsForWeek {
            let existing = hourlySum[log.hour, default: (0, 0)]
            hourlySum[log.hour] = (existing.total + log.productivityLevel, existing.count + 1)
        }
        return (6...23).map { hour in
            if let data = hourlySum[hour], data.count > 0 {
                return (hour: hour, avgProductivity: Double(data.total) / Double(data.count))
            }
            return (hour: hour, avgProductivity: 0)
        }
    }

    private var peakProductivityHour: Int? {
        calculateHourlyProductivity().filter { $0.avgProductivity > 0 }.max(by: { $0.avgProductivity < $1.avgProductivity })?.hour
    }

    private func formattedHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)"
    }

    private func calculateHoursPerGroup() -> [(group: CategoryGroup, hours: Int)] {
        var counts: [UUID: Int] = [:]
        for log in logsForWeek {
            if let groupId = log.category?.group?.id { counts[groupId, default: 0] += 1 }
        }
        return categoryGroups.compactMap { group in
            if let hours = counts[group.id], hours > 0 { return (group: group, hours: hours) }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private func calculatePreviousWeekHoursPerGroup() -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for log in previousWeekLogs {
            if let groupId = log.category?.group?.id { counts[groupId, default: 0] += 1 }
        }
        return counts
    }

    private func calculateProductiveDayStats() -> [(day: String, hours: Int)] {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var dayHours: [Int: Int] = [:]
        for log in logsForWeek where log.category?.group?.name == "Productive" {
            let dayOfWeek = Calendar.current.component(.weekday, from: log.date)
            dayHours[dayOfWeek, default: 0] += 1
        }
        return dayHours.map { (day: dayNames[$0.key - 1], hours: $0.value) }
    }

    private func percentage(_ hours: Int) -> Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(hours) / Double(totalLoggedHours)) * 100)
    }
}

#Preview {
    WeeklyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
