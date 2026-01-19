//
//  MonthlyView.swift
//  Daylog
//

import SwiftUI
import SwiftData
import Charts

struct MonthlyView: View {
    @Query private var allLogs: [HourLog]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

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

    private var workHours: Int {
        logsForMonth.filter { $0.project?.category?.name == "Work" }.count
    }

    private var previousWorkHours: Int {
        previousMonthLogs.filter { $0.project?.category?.name == "Work" }.count
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
        let hoursPerCategory = calculateHoursPerCategory()

        // Work time change
        if previousWorkHours > 0 {
            let change = workHours - previousWorkHours
            let pctChange = Int((Double(change) / Double(previousWorkHours)) * 100)
            if change >= 10 {
                insights.append(MonthlyInsight(icon: "arrow.up.circle.fill", color: .green,
                    text: "Work time up \(change)h (+\(pctChange)%) from last month"))
            } else if change <= -10 {
                insights.append(MonthlyInsight(icon: "arrow.down.circle.fill", color: .orange,
                    text: "Work time down \(abs(change))h from last month"))
            }
        }

        // Best day for work
        let workDayStats = calculateWorkDayStats()
        if let bestDay = workDayStats.max(by: { $0.avgHours < $1.avgHours }), bestDay.avgHours > 0 {
            insights.append(MonthlyInsight(icon: "star.fill", color: .yellow,
                text: "\(bestDay.day)s have most work time (avg \(String(format: "%.1f", bestDay.avgHours))h)"))
        }

        // Category shift
        for category in hoursPerCategory {
            let prevHours = previousMonthLogs.filter { $0.project?.category?.id == category.category.id }.count
            if prevHours > 0 {
                let change = category.hours - prevHours
                let pctChange = Int((Double(change) / Double(prevHours)) * 100)
                if change >= 15 {
                    insights.append(MonthlyInsight(icon: "arrow.up.circle.fill", color: Color(hex: category.category.colorHex),
                        text: "\(category.category.name) up \(change)h (+\(pctChange)%) from last month"))
                    break
                } else if change <= -15 {
                    insights.append(MonthlyInsight(icon: "arrow.down.circle.fill", color: Color(hex: category.category.colorHex),
                        text: "\(category.category.name) down \(abs(change))h from last month"))
                    break
                }
            }
        }

        // Time allocation
        if let topCategory = hoursPerCategory.first {
            let pct = percentage(topCategory.hours)
            insights.append(MonthlyInsight(icon: "chart.pie.fill", color: Color(hex: topCategory.category.colorHex),
                text: "\(pct)% of your month spent on \(topCategory.category.name)"))
        }

        return Array(insights.prefix(4))
    }

    // MARK: - Day of Week Analysis

    private var dayOfWeekAnalysis: some View {
        AnalyticsCard(title: "Best Days", subtitle: bestDayOfWeek.map { "Most active: \($0)" }) {
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
            let hoursPerCategory = calculateHoursPerCategory()
            if hoursPerCategory.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(hoursPerCategory, id: \.category.id) { item in
                        CategoryDistributionRow(
                            name: item.category.name,
                            colorHex: item.category.colorHex,
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

    private func calculateHoursPerCategory() -> [(category: Category, hours: Int)] {
        var counts: [UUID: Int] = [:]
        for log in logsForMonth {
            if let categoryId = log.project?.category?.id { counts[categoryId, default: 0] += 1 }
        }
        return categories.compactMap { category in
            if let hours = counts[category.id], hours > 0 { return (category: category, hours: hours) }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private func calculateWorkDayStats() -> [(day: String, avgHours: Double)] {
        let calendar = Calendar.current
        var dayTotals: [Int: (hours: Int, days: Int)] = [:]
        for dayIndex in 1...7 { dayTotals[dayIndex] = (0, 0) }

        for date in daysInMonth {
            let dayOfWeek = calendar.component(.weekday, from: date)
            let workCount = logsForDay(date).filter { $0.project?.category?.name == "Work" }.count
            let current = dayTotals[dayOfWeek]!
            dayTotals[dayOfWeek] = (current.hours + workCount, current.days + 1)
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
        .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
