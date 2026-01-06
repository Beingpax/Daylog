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

    private var previousWeekLogs: [HourLog] {
        let prevStart = selectedWeekStart.adding(weeks: -1)
        let prevEnd = selectedWeekStart
        return allLogs.filter { log in
            log.date >= prevStart && log.date < prevEnd
        }
    }

    private var totalLoggedHours: Int { logsForWeek.count }
    private var previousWeekHours: Int { previousWeekLogs.count }

    private var avgEnergyLevel: Double {
        guard !logsForWeek.isEmpty else { return 0 }
        return Double(logsForWeek.reduce(0) { $0 + $1.energyLevel }) / Double(logsForWeek.count)
    }

    private var previousAvgEnergy: Double {
        guard !previousWeekLogs.isEmpty else { return 0 }
        return Double(previousWeekLogs.reduce(0) { $0 + $1.energyLevel }) / Double(previousWeekLogs.count)
    }

    private var productiveHours: Int {
        logsForWeek.filter { $0.category?.group?.name == "Productive" }.count
    }

    private var previousProductiveHours: Int {
        previousWeekLogs.filter { $0.category?.group?.name == "Productive" }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weekNavigator

                    if !logsForWeek.isEmpty {
                        weeklyInsights
                        summaryCards
                        dailyDistribution
                        energyByTimeOfDay
                        topActivities
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly")
        }
    }

    // MARK: - Weekly Insights
    private var weeklyInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(generateInsights(), id: \.text) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func generateInsights() -> [Insight] {
        var insights: [Insight] = []
        let hoursPerGroup = calculateHoursPerGroup()
        let prevHoursPerGroup = calculatePreviousWeekHoursPerGroup()

        // 1. Peak energy hour - when to do deep work
        if let peakHour = peakEnergyHour {
            let hourlyEnergy = calculateHourlyEnergy()
            if let peakData = hourlyEnergy.first(where: { $0.hour == peakHour }), peakData.avgEnergy >= 7 {
                insights.append(Insight(
                    icon: "bolt.fill",
                    color: .orange,
                    text: "Peak energy at \(formattedHour(peakHour)) — ideal for deep work"
                ))
            }
        }

        // 2. Low energy detection - when to rest
        let hourlyEnergy = calculateHourlyEnergy().filter { $0.avgEnergy > 0 }
        if let lowHour = hourlyEnergy.min(by: { $0.avgEnergy < $1.avgEnergy }), lowHour.avgEnergy < 5 && lowHour.avgEnergy > 0 {
            insights.append(Insight(
                icon: "moon.fill",
                color: .indigo,
                text: "Energy lowest at \(formattedHour(lowHour.hour)) — schedule lighter tasks"
            ))
        }

        // 3. Productive time change vs last week
        if previousProductiveHours > 0 {
            let productivityChange = productiveHours - previousProductiveHours
            let pctChange = Int((Double(productivityChange) / Double(previousProductiveHours)) * 100)
            if productivityChange >= 3 {
                insights.append(Insight(
                    icon: "arrow.up.right.circle.fill",
                    color: .green,
                    text: "Productive time up \(productivityChange)h (+\(pctChange)%) from last week"
                ))
            } else if productivityChange <= -3 {
                insights.append(Insight(
                    icon: "arrow.down.right.circle.fill",
                    color: .orange,
                    text: "Productive time down \(abs(productivityChange))h from last week"
                ))
            }
        }

        // 4. Category shift - what changed most
        for group in hoursPerGroup {
            let prevHours = prevHoursPerGroup[group.group.id] ?? 0
            let change = group.hours - prevHours
            if prevHours > 0 && change >= 5 {
                let pctChange = Int((Double(change) / Double(prevHours)) * 100)
                insights.append(Insight(
                    icon: "arrow.up.circle.fill",
                    color: Color(hex: group.group.colorHex),
                    text: "\(group.group.name) up \(change)h (+\(pctChange)%) vs last week"
                ))
                break
            } else if prevHours > 0 && change <= -5 {
                insights.append(Insight(
                    icon: "arrow.down.circle.fill",
                    color: Color(hex: group.group.colorHex),
                    text: "\(group.group.name) down \(abs(change))h from last week"
                ))
                break
            }
        }

        // 5. Best day for productivity
        let productiveDayStats = calculateProductiveDayStats()
        if let bestDay = productiveDayStats.max(by: { $0.hours < $1.hours }), bestDay.hours > 0 {
            insights.append(Insight(
                icon: "star.fill",
                color: .yellow,
                text: "\(bestDay.day) was most productive (\(bestDay.hours)h of focused work)"
            ))
        }

        // 6. Morning vs afternoon productivity
        let morningProductive = logsForWeek.filter {
            $0.hour >= 6 && $0.hour < 12 && $0.category?.group?.name == "Productive"
        }.count
        let afternoonProductive = logsForWeek.filter {
            $0.hour >= 12 && $0.hour < 18 && $0.category?.group?.name == "Productive"
        }.count
        if morningProductive > 0 && afternoonProductive > 0 {
            if morningProductive > afternoonProductive + 5 {
                insights.append(Insight(
                    icon: "sunrise.fill",
                    color: .orange,
                    text: "You're a morning person — \(morningProductive)h vs \(afternoonProductive)h afternoon"
                ))
            } else if afternoonProductive > morningProductive + 5 {
                insights.append(Insight(
                    icon: "sun.max.fill",
                    color: .orange,
                    text: "Afternoons are your prime time — \(afternoonProductive)h vs \(morningProductive)h morning"
                ))
            }
        }

        // 7. Energy trend vs last week
        let energyDiff = avgEnergyLevel - previousAvgEnergy
        if previousAvgEnergy > 0 && abs(energyDiff) >= 0.5 {
            if energyDiff > 0 {
                insights.append(Insight(
                    icon: "heart.fill",
                    color: .green,
                    text: "Energy up \(String(format: "%.1f", energyDiff)) points from last week"
                ))
            } else {
                insights.append(Insight(
                    icon: "heart.slash.fill",
                    color: .red,
                    text: "Energy down \(String(format: "%.1f", abs(energyDiff))) — prioritize rest"
                ))
            }
        }

        // 8. Time allocation insight
        if let topGroup = hoursPerGroup.first {
            let pct = percentage(topGroup.hours)
            insights.append(Insight(
                icon: "chart.pie.fill",
                color: Color(hex: topGroup.group.colorHex),
                text: "\(pct)% of your week spent on \(topGroup.group.name)"
            ))
        }

        return Array(insights.prefix(4))
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

    private func calculatePreviousWeekHoursPerGroup() -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for log in previousWeekLogs {
            if let groupId = log.category?.group?.id {
                counts[groupId, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: - Week Navigator
    private var weekNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedWeekStart = selectedWeekStart.adding(weeks: -1)
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
                Text(weekRangeString)
                    .font(.headline)
                if isCurrentWeek {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedWeekStart = selectedWeekStart.adding(weeks: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isCurrentWeek ? .tertiary : .primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .disabled(isCurrentWeek)
        }
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

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Productive",
                value: "\(productiveHours)h",
                subtitle: productiveTrendText,
                trendUp: productiveHours >= previousProductiveHours,
                color: .green
            )

            SummaryCard(
                title: "Avg Energy",
                value: String(format: "%.1f", avgEnergyLevel),
                subtitle: energyTrendText,
                trendUp: avgEnergyLevel >= previousAvgEnergy,
                color: .orange
            )

            SummaryCard(
                title: "Productive %",
                value: "\(productivePercentage)%",
                subtitle: productivePercentageTrendText,
                trendUp: productivePercentage >= previousProductivePercentage,
                color: .blue
            )
        }
    }

    private var productivePercentage: Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(productiveHours) / Double(totalLoggedHours)) * 100)
    }

    private var previousProductivePercentage: Int {
        guard previousWeekHours > 0 else { return 0 }
        return Int((Double(previousProductiveHours) / Double(previousWeekHours)) * 100)
    }

    private var productiveTrendText: String {
        let diff = productiveHours - previousProductiveHours
        if previousProductiveHours == 0 { return "No prior data" }
        if diff == 0 { return "Same as last week" }
        return diff > 0 ? "+\(diff)h vs last week" : "\(diff)h vs last week"
    }

    private var energyTrendText: String {
        let diff = avgEnergyLevel - previousAvgEnergy
        if previousAvgEnergy == 0 { return "No prior data" }
        if abs(diff) < 0.1 { return "Same as last week" }
        return diff > 0 ? String(format: "+%.1f vs last week", diff) : String(format: "%.1f vs last week", diff)
    }

    private var productivePercentageTrendText: String {
        let diff = productivePercentage - previousProductivePercentage
        if previousProductivePercentage == 0 { return "No prior data" }
        if diff == 0 { return "Same as last week" }
        return diff > 0 ? "+\(diff)% vs last week" : "\(diff)% vs last week"
    }

    // MARK: - Daily Distribution
    private var dailyDistribution: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    DailyBarRow(
                        date: date,
                        logs: logsForDay(date),
                        categoryGroups: categoryGroups,
                        isToday: date.isSameDay(as: Date())
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func logsForDay(_ date: Date) -> [HourLog] {
        logsForWeek.filter { $0.date.isSameDay(as: date) }
    }

    // MARK: - Energy by Time of Day
    private var energyByTimeOfDay: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Energy Pattern")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let peakHour = peakEnergyHour {
                    Text("Peak: \(formattedHour(peakHour))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            let hourlyEnergy = calculateHourlyEnergy()

            Chart(hourlyEnergy, id: \.hour) { item in
                AreaMark(
                    x: .value("Hour", item.hour),
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
                    x: .value("Hour", item.hour),
                    y: .value("Energy", item.avgEnergy)
                )
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
                        if let hour = value.as(Int.self) {
                            Text(formattedHour(hour))
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

    private func calculateHourlyEnergy() -> [(hour: Int, avgEnergy: Double)] {
        var hourlySum: [Int: (total: Int, count: Int)] = [:]

        for log in logsForWeek {
            let existing = hourlySum[log.hour, default: (0, 0)]
            hourlySum[log.hour] = (existing.total + log.energyLevel, existing.count + 1)
        }

        return (6...23).map { hour in
            if let data = hourlySum[hour], data.count > 0 {
                return (hour: hour, avgEnergy: Double(data.total) / Double(data.count))
            }
            return (hour: hour, avgEnergy: 0)
        }
    }

    private var peakEnergyHour: Int? {
        let hourlyEnergy = calculateHourlyEnergy().filter { $0.avgEnergy > 0 }
        return hourlyEnergy.max(by: { $0.avgEnergy < $1.avgEnergy })?.hour
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

    // MARK: - Top Activities
    private var topActivities: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Distribution")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            let hoursPerGroup = calculateHoursPerGroup()

            if hoursPerGroup.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(hoursPerGroup.prefix(5), id: \.group.id) { item in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: item.group.colorHex))
                                .frame(width: 10, height: 10)

                            Text(item.group.name)
                                .font(.subheadline)

                            Spacer()

                            Text("\(item.hours)h")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)

                            Text("(\(percentage(item.hours))%)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .frame(width: 40, alignment: .trailing)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: item.group.colorHex))
                                    .frame(width: geo.size.width * CGFloat(item.hours) / CGFloat(max(totalLoggedHours, 1)), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func calculateHoursPerGroup() -> [(group: CategoryGroup, hours: Int)] {
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

    private func percentage(_ hours: Int) -> Int {
        guard totalLoggedHours > 0 else { return 0 }
        return Int((Double(hours) / Double(totalLoggedHours)) * 100)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No logs this week")
                    .font(.headline)
                Text("Start logging your hours to see insights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Supporting Views

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
            .opacity(subtitle.contains("Same") ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

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

#Preview {
    WeeklyView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
