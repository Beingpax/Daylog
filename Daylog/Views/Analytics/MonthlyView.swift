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

    // MARK: - Computed Properties

    private var logsForMonth: [HourLog] {
        let monthEnd = selectedMonth.adding(months: 1)
        return allLogs.filter { $0.date >= selectedMonth && $0.date < monthEnd }
    }

    private var previousMonthLogs: [HourLog] {
        let prevStart = selectedMonth.adding(months: -1)
        return allLogs.filter { $0.date >= prevStart && $0.date < selectedMonth }
    }

    private var totalLoggedHours: Int { logsForMonth.count }

    private var productiveHours: Int {
        logsForMonth.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var previousProductiveHours: Int {
        previousMonthLogs.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else { return [] }
        return range.compactMap { day in calendar.date(bySetting: .day, value: day, of: selectedMonth) }
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var isCurrentMonth: Bool {
        selectedMonth >= Date().startOfMonth
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TimePeriodNavigator(
                        title: monthString,
                        subtitle: isCurrentMonth ? "This Month" : nil,
                        canGoForward: !isCurrentMonth,
                        onPrevious: { withAnimation { selectedMonth = selectedMonth.adding(months: -1) } },
                        onNext: { withAnimation { selectedMonth = selectedMonth.adding(months: 1) } }
                    )

                    if !logsForMonth.isEmpty {
                        insightsSection
                        dayOfWeekAnalysis
                        categoryDistribution
                    } else {
                        AnalyticsEmptyState(
                            icon: "calendar.badge.clock",
                            title: "No logs this month",
                            message: "Start logging your hours to see monthly insights"
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Monthly")
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        AnalyticsCard(title: "Insights") {
            VStack(spacing: 8) {
                ForEach(generateInsights(), id: \.text) { insight in
                    MonthlyInsightRow(insight: insight)
                }
            }
        }
    }

    private func generateInsights() -> [MonthlyInsight] {
        var insights: [MonthlyInsight] = []
        let hoursPerGroup = calculateHoursPerGroup()

        // Productive time change
        if previousProductiveHours > 0 {
            let change = productiveHours - previousProductiveHours
            let pctChange = Int((Double(change) / Double(previousProductiveHours)) * 100)
            if change >= 10 {
                insights.append(MonthlyInsight(icon: "arrow.up.circle.fill", color: .green,
                    text: "Productive time up \(change)h (+\(pctChange)%) from last month"))
            } else if change <= -10 {
                insights.append(MonthlyInsight(icon: "arrow.down.circle.fill", color: .orange,
                    text: "Productive time down \(abs(change))h from last month"))
            }
        }

        // Best day for productivity
        let productiveDayStats = calculateProductiveDayStats()
        if let bestDay = productiveDayStats.max(by: { $0.avgHours < $1.avgHours }), bestDay.avgHours > 0 {
            insights.append(MonthlyInsight(icon: "star.fill", color: .yellow,
                text: "\(bestDay.day)s are your most productive (avg \(String(format: "%.1f", bestDay.avgHours))h)"))
        }

        // Category shift
        for group in hoursPerGroup {
            let prevHours = previousMonthLogs.filter { $0.category?.group?.id == group.group.id }.count
            if prevHours > 0 {
                let change = group.hours - prevHours
                let pctChange = Int((Double(change) / Double(prevHours)) * 100)
                if change >= 15 {
                    insights.append(MonthlyInsight(icon: "arrow.up.circle.fill", color: Color(hex: group.group.colorHex),
                        text: "\(group.group.name) up \(change)h (+\(pctChange)%) from last month"))
                    break
                } else if change <= -15 {
                    insights.append(MonthlyInsight(icon: "arrow.down.circle.fill", color: Color(hex: group.group.colorHex),
                        text: "\(group.group.name) down \(abs(change))h from last month"))
                    break
                }
            }
        }

        // Time allocation
        if let topGroup = hoursPerGroup.first {
            let pct = percentage(topGroup.hours)
            insights.append(MonthlyInsight(icon: "chart.pie.fill", color: Color(hex: topGroup.group.colorHex),
                text: "\(pct)% of your month spent on \(topGroup.group.name)"))
        }

        return Array(insights.prefix(4))
    }

    // MARK: - Day of Week Analysis

    private var dayOfWeekAnalysis: some View {
        AnalyticsCard(title: "Best Days", subtitle: bestDayOfWeek.map { "Most productive: \($0)" }) {
            HStack(spacing: 8) {
                ForEach(calculateDayOfWeekStats(), id: \.day) { stat in
                    DayOfWeekBar(day: stat.day, percentage: stat.percentage, isHighest: stat.isHighest)
                }
            }
        }
    }

    private func calculateDayOfWeekStats() -> [(day: String, avgHours: Double, percentage: Double, isHighest: Bool)] {
        let calendar = Calendar.current
        var dayTotals: [Int: (hours: Int, days: Int)] = [:]
        for dayIndex in 1...7 { dayTotals[dayIndex] = (0, 0) }

        for date in daysInMonth {
            let dayOfWeek = calendar.component(.weekday, from: date)
            let logsCount = logsForDay(date).count
            let current = dayTotals[dayOfWeek]!
            dayTotals[dayOfWeek] = (current.hours + logsCount, current.days + 1)
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var stats = dayTotals.map { dayIndex, data in
            let avg = data.days > 0 ? Double(data.hours) / Double(data.days) : 0
            return (day: dayNames[dayIndex - 1], avgHours: avg, percentage: 0.0, isHighest: false)
        }.sorted { dayNames.firstIndex(of: $0.day)! < dayNames.firstIndex(of: $1.day)! }

        let maxAvg = stats.map { $0.avgHours }.max() ?? 1
        stats = stats.map { stat in
            var s = stat
            s.percentage = maxAvg > 0 ? stat.avgHours / maxAvg : 0
            s.isHighest = stat.avgHours == maxAvg && maxAvg > 0
            return s
        }
        return stats
    }

    private var bestDayOfWeek: String? {
        calculateDayOfWeekStats().max(by: { $0.avgHours < $1.avgHours })?.day
    }

    // MARK: - Category Distribution

    private var categoryDistribution: some View {
        AnalyticsCard(title: "Time Distribution") {
            let hoursPerGroup = calculateHoursPerGroup()
            if hoursPerGroup.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(hoursPerGroup, id: \.group.id) { item in
                        CategoryDistributionRow(
                            name: item.group.name,
                            colorHex: item.group.colorHex,
                            hours: item.hours,
                            percentage: percentage(item.hours),
                            totalHours: totalLoggedHours
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func logsForDay(_ date: Date) -> [HourLog] {
        logsForMonth.filter { $0.date.isSameDay(as: date) }
    }

    private func calculateHoursPerGroup() -> [(group: CategoryGroup, hours: Int)] {
        var counts: [UUID: Int] = [:]
        for log in logsForMonth {
            if let groupId = log.category?.group?.id { counts[groupId, default: 0] += 1 }
        }
        return categoryGroups.compactMap { group in
            if let hours = counts[group.id], hours > 0 { return (group: group, hours: hours) }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private func calculateProductiveDayStats() -> [(day: String, avgHours: Double)] {
        let calendar = Calendar.current
        var dayTotals: [Int: (hours: Int, days: Int)] = [:]
        for dayIndex in 1...7 { dayTotals[dayIndex] = (0, 0) }

        for date in daysInMonth {
            let dayOfWeek = calendar.component(.weekday, from: date)
            let productiveCount = logsForDay(date).filter { $0.category?.group?.name == "Productive" }.count
            let current = dayTotals[dayOfWeek]!
            dayTotals[dayOfWeek] = (current.hours + productiveCount, current.days + 1)
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayTotals.map { dayIndex, data in
            let avg = data.days > 0 ? Double(data.hours) / Double(data.days) : 0
            return (day: dayNames[dayIndex - 1], avgHours: avg)
        }
    }

    private func percentage(_ hours: Int) -> Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(hours) / Double(totalLoggedHours)) * 100)
    }
}

#Preview {
    MonthlyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
