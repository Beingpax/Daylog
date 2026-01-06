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

    private var previousMonthLogs: [HourLog] {
        let prevStart = selectedMonth.adding(months: -1)
        return allLogs.filter { log in
            log.date >= prevStart && log.date < selectedMonth
        }
    }

    private var totalLoggedHours: Int { logsForMonth.count }

    private var avgEnergyLevel: Double {
        guard !logsForMonth.isEmpty else { return 0 }
        return Double(logsForMonth.reduce(0) { $0 + $1.energyLevel }) / Double(logsForMonth.count)
    }

    private var daysLogged: Int {
        Set(logsForMonth.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(bySetting: .day, value: day, of: selectedMonth)
        }
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var isCurrentMonth: Bool {
        selectedMonth >= Date().startOfMonth
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthNavigator

                    if !logsForMonth.isEmpty {
                        monthlyInsights
                        summaryCards
                        calendarHeatmap
                        dayOfWeekAnalysis
                        energyTrend
                        categoryDistribution
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Monthly")
        }
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMonth = selectedMonth.adding(months: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthString)
                    .font(.headline)
                if isCurrentMonth {
                    Text("This Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMonth = selectedMonth.adding(months: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isCurrentMonth ? .tertiary : .primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .disabled(isCurrentMonth)
        }
    }

    // MARK: - Monthly Insights
    private var monthlyInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(generateMonthlyInsights(), id: \.text) { insight in
                    MonthlyInsightRow(insight: insight)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var productiveHours: Int {
        logsForMonth.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var previousProductiveHours: Int {
        previousMonthLogs.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var productivePercentage: Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(productiveHours) / Double(totalLoggedHours)) * 100)
    }

    private var previousProductivePercentage: Int {
        let prevTotal = previousMonthLogs.count
        guard prevTotal > 0 else { return 0 }
        return Int((Double(previousProductiveHours) / Double(prevTotal)) * 100)
    }

    private func generateMonthlyInsights() -> [MonthlyInsight] {
        var insights: [MonthlyInsight] = []
        let hoursPerGroup = calculateHoursPerGroup()

        // 1. Productive time change vs last month
        if previousProductiveHours > 0 {
            let change = productiveHours - previousProductiveHours
            let pctChange = Int((Double(change) / Double(previousProductiveHours)) * 100)
            if change >= 10 {
                insights.append(MonthlyInsight(
                    icon: "arrow.up.circle.fill",
                    color: .green,
                    text: "Productive time up \(change)h (+\(pctChange)%) from last month"
                ))
            } else if change <= -10 {
                insights.append(MonthlyInsight(
                    icon: "arrow.down.circle.fill",
                    color: .orange,
                    text: "Productive time down \(abs(change))h from last month"
                ))
            }
        }

        // 2. Productivity percentage insight
        let pctChange = productivePercentage - previousProductivePercentage
        if previousProductivePercentage > 0 && abs(pctChange) >= 5 {
            if pctChange > 0 {
                insights.append(MonthlyInsight(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    text: "Productivity ratio improved by \(pctChange) percentage points"
                ))
            } else {
                insights.append(MonthlyInsight(
                    icon: "chart.line.downtrend.xyaxis",
                    color: .orange,
                    text: "Productivity ratio dropped \(abs(pctChange)) percentage points"
                ))
            }
        }

        // 3. Best day for productivity
        let productiveDayStats = calculateProductiveDayStats()
        if let bestDay = productiveDayStats.max(by: { $0.avgHours < $1.avgHours }), bestDay.avgHours > 0 {
            insights.append(MonthlyInsight(
                icon: "star.fill",
                color: .yellow,
                text: "\(bestDay.day)s are your most productive (avg \(String(format: "%.1f", bestDay.avgHours))h)"
            ))
        }

        // 4. Energy trend through the month
        let trend = energyTrendDirection
        if abs(trend) >= 0.5 {
            if trend > 0 {
                insights.append(MonthlyInsight(
                    icon: "arrow.up.heart.fill",
                    color: .green,
                    text: "Energy improved through the month"
                ))
            } else {
                insights.append(MonthlyInsight(
                    icon: "arrow.down.heart.fill",
                    color: .red,
                    text: "Energy declined through the month — review your schedule"
                ))
            }
        }

        // 5. Category shift - biggest change
        for group in hoursPerGroup {
            let prevHours = previousMonthLogs.filter { $0.category?.group?.id == group.group.id }.count
            if prevHours > 0 {
                let change = group.hours - prevHours
                let pctChange = Int((Double(change) / Double(prevHours)) * 100)
                if change >= 15 {
                    insights.append(MonthlyInsight(
                        icon: "arrow.up.circle.fill",
                        color: Color(hex: group.group.colorHex),
                        text: "\(group.group.name) up \(change)h (+\(pctChange)%) from last month"
                    ))
                    break
                } else if change <= -15 {
                    insights.append(MonthlyInsight(
                        icon: "arrow.down.circle.fill",
                        color: Color(hex: group.group.colorHex),
                        text: "\(group.group.name) down \(abs(change))h from last month"
                    ))
                    break
                }
            }
        }

        // 6. Time allocation - dominant category
        if let topGroup = hoursPerGroup.first {
            let pct = percentage(topGroup.hours)
            insights.append(MonthlyInsight(
                icon: "chart.pie.fill",
                color: Color(hex: topGroup.group.colorHex),
                text: "\(pct)% of your month spent on \(topGroup.group.name)"
            ))
        }

        // 7. Weekend productivity vs weekdays
        let weekendProductive = logsForMonth.filter {
            let weekday = Calendar.current.component(.weekday, from: $0.date)
            return (weekday == 1 || weekday == 7) && $0.category?.group?.name == "Productive"
        }.count
        let weekdayProductive = productiveHours - weekendProductive

        let weekendDays = daysInMonth.filter {
            let weekday = Calendar.current.component(.weekday, from: $0)
            return weekday == 1 || weekday == 7
        }.count
        let weekdayDays = daysInMonth.count - weekendDays

        if weekendDays > 0 && weekdayDays > 0 {
            let weekendAvg = Double(weekendProductive) / Double(weekendDays)
            let weekdayAvg = Double(weekdayProductive) / Double(weekdayDays)
            if weekdayAvg > weekendAvg + 2 {
                insights.append(MonthlyInsight(
                    icon: "briefcase.fill",
                    color: .indigo,
                    text: "Weekday productivity \(String(format: "%.1f", weekdayAvg))h/day vs \(String(format: "%.1f", weekendAvg))h on weekends"
                ))
            } else if weekendAvg > weekdayAvg + 1 {
                insights.append(MonthlyInsight(
                    icon: "figure.walk",
                    color: .teal,
                    text: "More productive on weekends (\(String(format: "%.1f", weekendAvg))h/day)"
                ))
            }
        }

        // 8. Average energy comparison
        let prevAvgEnergy = previousMonthLogs.isEmpty ? 0 : Double(previousMonthLogs.reduce(0) { $0 + $1.energyLevel }) / Double(previousMonthLogs.count)
        if prevAvgEnergy > 0 {
            let energyDiff = avgEnergyLevel - prevAvgEnergy
            if abs(energyDiff) >= 0.5 {
                if energyDiff > 0 {
                    insights.append(MonthlyInsight(
                        icon: "heart.fill",
                        color: .green,
                        text: "Avg energy up \(String(format: "%.1f", energyDiff)) from last month"
                    ))
                } else {
                    insights.append(MonthlyInsight(
                        icon: "heart.slash.fill",
                        color: .red,
                        text: "Avg energy down \(String(format: "%.1f", abs(energyDiff))) — prioritize rest"
                    ))
                }
            }
        }

        return Array(insights.prefix(4))
    }

    private func calculateProductiveDayStats() -> [(day: String, avgHours: Double)] {
        let calendar = Calendar.current
        var dayTotals: [Int: (hours: Int, days: Int)] = [:]

        for dayIndex in 1...7 {
            dayTotals[dayIndex] = (0, 0)
        }

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

    // MARK: - Summary Cards
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MonthlySummaryCard(
                title: "Productive",
                value: "\(productiveHours)h",
                icon: "briefcase.fill",
                color: .green
            )

            MonthlySummaryCard(
                title: "Productive %",
                value: "\(productivePercentage)%",
                icon: "chart.pie.fill",
                color: .blue
            )

            MonthlySummaryCard(
                title: "Avg Energy",
                value: String(format: "%.1f", avgEnergyLevel),
                icon: "bolt.fill",
                color: .orange
            )

            MonthlySummaryCard(
                title: "Daily Productive",
                value: String(format: "%.1fh", Double(productiveHours) / Double(max(daysLogged, 1))),
                icon: "chart.bar.fill",
                color: .purple
            )
        }
    }

    // MARK: - Calendar Heatmap
    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
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
                    CalendarDayCell(
                        date: date,
                        logs: logsForDay(date),
                        isToday: date.isSameDay(as: Date())
                    )
                }
            }

            // Legend
            HStack(spacing: 16) {
                Spacer()
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(intensity == 0 ? 0.1 : 0.2 + intensity * 0.6))
                            .frame(width: 14, height: 14)
                    }

                    Text("More")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func logsForDay(_ date: Date) -> [HourLog] {
        logsForMonth.filter { $0.date.isSameDay(as: date) }
    }

    // MARK: - Day of Week Analysis
    private var dayOfWeekAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Best Days")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let bestDay = bestDayOfWeek {
                    Text("Most productive: \(bestDay)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            let dayStats = calculateDayOfWeekStats()

            HStack(spacing: 8) {
                ForEach(dayStats, id: \.day) { stat in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 32, height: 80)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(stat.isHighest ? Color.green : Color.blue)
                                .frame(width: 32, height: max(4, 80 * stat.percentage))
                        }

                        Text(stat.day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func calculateDayOfWeekStats() -> [(day: String, avgHours: Double, percentage: Double, isHighest: Bool)] {
        let calendar = Calendar.current
        var dayTotals: [Int: (hours: Int, days: Int)] = [:]

        for dayIndex in 1...7 {
            dayTotals[dayIndex] = (0, 0)
        }

        // Count logs per day of week
        for date in daysInMonth {
            let dayOfWeek = calendar.component(.weekday, from: date)
            let logsCount = logsForDay(date).count
            let current = dayTotals[dayOfWeek]!
            dayTotals[dayOfWeek] = (current.hours + logsCount, current.days + 1)
        }

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var stats = dayTotals.map { dayIndex, data -> (day: String, avgHours: Double, percentage: Double, isHighest: Bool) in
            let avg = data.days > 0 ? Double(data.hours) / Double(data.days) : 0
            return (day: dayNames[dayIndex - 1], avgHours: avg, percentage: 0, isHighest: false)
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
        let stats = calculateDayOfWeekStats()
        return stats.max(by: { $0.avgHours < $1.avgHours })?.day
    }

    // MARK: - Energy Trend
    private var energyTrend: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Energy Trend")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                let trend = energyTrendDirection
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(trend >= 0 ? "Improving" : "Declining")
                }
                .font(.caption)
                .foregroundStyle(trend >= 0 ? .green : .orange)
            }

            let dailyEnergy = calculateDailyEnergy()

            Chart(dailyEnergy, id: \.date) { item in
                if item.avgEnergy > 0 {
                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Energy", item.avgEnergy)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Energy", item.avgEnergy)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Energy", item.avgEnergy)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(item.date.isSameDay(as: Date()) ? 60 : 20)
                }
            }
            .frame(height: 140)
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 5, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color(.systemGray4))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func calculateDailyEnergy() -> [(date: Date, avgEnergy: Double)] {
        daysInMonth.map { date in
            let logs = logsForDay(date)
            if logs.isEmpty {
                return (date: date, avgEnergy: 0)
            }
            let avg = Double(logs.reduce(0) { $0 + $1.energyLevel }) / Double(logs.count)
            return (date: date, avgEnergy: avg)
        }
    }

    private var energyTrendDirection: Double {
        let dailyEnergy = calculateDailyEnergy().filter { $0.avgEnergy > 0 }
        guard dailyEnergy.count >= 7 else { return 0 }

        let firstHalf = dailyEnergy.prefix(dailyEnergy.count / 2)
        let secondHalf = dailyEnergy.suffix(dailyEnergy.count / 2)

        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.avgEnergy } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.avgEnergy } / Double(secondHalf.count)

        return secondAvg - firstAvg
    }

    // MARK: - Category Distribution
    private var categoryDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Distribution")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let hoursPerGroup = calculateHoursPerGroup()

            if hoursPerGroup.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(hoursPerGroup, id: \.group.id) { item in
                        VStack(spacing: 6) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: item.group.colorHex))
                                    .frame(width: 10, height: 10)

                                Text(item.group.name)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(item.hours)h")
                                    .font(.subheadline.weight(.medium).monospacedDigit())

                                Text("(\(percentage(item.hours))%)")
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
                                        .fill(Color(hex: item.group.colorHex))
                                        .frame(width: geo.size.width * CGFloat(item.hours) / CGFloat(max(totalLoggedHours, 1)), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func calculateHoursPerGroup() -> [(group: CategoryGroup, hours: Int)] {
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

    private func percentage(_ hours: Int) -> Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(hours) / Double(totalLoggedHours)) * 100)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No logs this month")
                    .font(.headline)
                Text("Start logging your hours to see monthly insights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Supporting Views

struct MonthlySummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CalendarDayCell: View {
    let date: Date
    let logs: [HourLog]
    let isToday: Bool

    private var intensity: Double {
        min(Double(logs.count) / 16.0, 1.0)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(logs.isEmpty ? Color(.systemGray6) : Color.blue.opacity(0.2 + intensity * 0.6))

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.blue, lineWidth: 2)
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.caption2.weight(isToday ? .bold : .medium).monospacedDigit())
                    .foregroundStyle(isToday ? .blue : (logs.isEmpty ? .secondary : .primary))

                if !logs.isEmpty {
                    Text("\(logs.count)")
                        .font(.system(size: 8).weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

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

#Preview {
    MonthlyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
