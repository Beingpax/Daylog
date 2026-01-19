//
//  WeeklyView.swift
//  Daylog
//

import SwiftUI
import SwiftData
import Charts

struct WeeklyView: View {
    @Query private var allLogs: [HourLog]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

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

    private var workHours: Int {
        logsForWeek.filter { $0.project?.category?.name == "Work" }.count
    }

    private var previousWorkHours: Int {
        previousWeekLogs.filter { $0.project?.category?.name == "Work" }.count
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
        let hoursPerCategory = calculateHoursPerCategory()
        let prevHoursPerCategory = calculatePreviousWeekHoursPerCategory()

        // Work time change
        if previousWorkHours > 0 {
            let change = workHours - previousWorkHours
            let pctChange = Int((Double(change) / Double(previousWorkHours)) * 100)
            if change >= 3 {
                insights.append(Insight(icon: "arrow.up.right.circle.fill", color: .green,
                    text: "Work time up \(change)h (+\(pctChange)%) from last week"))
            } else if change <= -3 {
                insights.append(Insight(icon: "arrow.down.right.circle.fill", color: .orange,
                    text: "Work time down \(abs(change))h from last week"))
            }
        }

        // Category shift
        for category in hoursPerCategory {
            let prevHours = prevHoursPerCategory[category.category.id] ?? 0
            let change = category.hours - prevHours
            if prevHours > 0 && abs(change) >= 5 {
                let icon = change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                let text = change > 0
                    ? "\(category.category.name) up \(change)h (+\(Int((Double(change) / Double(prevHours)) * 100))%) vs last week"
                    : "\(category.category.name) down \(abs(change))h from last week"
                insights.append(Insight(icon: icon, color: Color(hex: category.category.colorHex), text: text))
                break
            }
        }

        // Best day for work
        let workDayStats = calculateWorkDayStats()
        if let bestDay = workDayStats.max(by: { $0.hours < $1.hours }), bestDay.hours > 0 {
            insights.append(Insight(icon: "star.fill", color: .yellow,
                text: "\(bestDay.day) had most work time (\(bestDay.hours)h)"))
        }

        // Time allocation
        if let topCategory = hoursPerCategory.first {
            let pct = percentage(topCategory.hours)
            insights.append(Insight(icon: "chart.pie.fill", color: Color(hex: topCategory.category.colorHex),
                text: "\(pct)% of your week spent on \(topCategory.category.name)"))
        }

        return Array(insights.prefix(4))
    }

    // MARK: - Time Distribution

    private var timeDistribution: some View {
        AnalyticsCard(title: "Time Distribution") {
            let hoursPerCategory = calculateHoursPerCategory()
            if hoursPerCategory.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(hoursPerCategory.prefix(5), id: \.category.id) { item in
                        VStack(spacing: 4) {
                            HStack(spacing: 12) {
                                Circle().fill(Color(hex: item.category.colorHex)).frame(width: 10, height: 10)
                                Text(item.category.name).font(.subheadline)
                                Spacer()
                                Text("\(item.hours)h").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                                Text("(\(percentage(item.hours))%)").font(.caption.monospacedDigit()).foregroundStyle(.tertiary).frame(width: 40, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: item.category.colorHex))
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

    private func calculateHoursPerCategory() -> [(category: Category, hours: Int)] {
        var counts: [UUID: Int] = [:]
        for log in logsForWeek {
            if let categoryId = log.project?.category?.id { counts[categoryId, default: 0] += 1 }
        }
        return categories.compactMap { category in
            if let hours = counts[category.id], hours > 0 { return (category: category, hours: hours) }
            return nil
        }.sorted { $0.hours > $1.hours }
    }

    private func calculatePreviousWeekHoursPerCategory() -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for log in previousWeekLogs {
            if let categoryId = log.project?.category?.id { counts[categoryId, default: 0] += 1 }
        }
        return counts
    }

    private func calculateWorkDayStats() -> [(day: String, hours: Int)] {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var dayHours: [Int: Int] = [:]
        for log in logsForWeek where log.project?.category?.name == "Work" {
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
        .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
