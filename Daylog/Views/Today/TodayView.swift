//
//  TodayView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var selectedHourLog: HourLog?
    @State private var selectedHour: Int?

    @Query private var allLogs: [HourLog]

    private var logsForDate: [HourLog] {
        allLogs.filter { $0.date.isSameDay(as: selectedDate.startOfDay) }
    }

    private var loggedCount: Int { logsForDate.count }

    private var productiveCount: Int {
        logsForDate.filter { $0.category?.group?.name == "Productive" }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date nav + stats
                VStack(spacing: 12) {
                    dateNavigator
                    statsRow
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))

                // Timeline
                DailyTimelineView(
                    selectedDate: selectedDate,
                    onHourTap: { hour, log in
                        selectedHour = hour
                        selectedHourLog = log
                    }
                )
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DayLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") { selectedDate = Date() }
                        .font(.subheadline)
                        .opacity(selectedDate.isSameDay(as: Date()) ? 0.3 : 1)
                        .disabled(selectedDate.isSameDay(as: Date()))
                }
            }
            .sheet(item: $selectedHour) { hour in
                HourEditSheet(date: selectedDate, hour: hour, existingLog: selectedHourLog)
            }
        }
    }

    private var dateNavigator: some View {
        HStack {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedDate = selectedDate.adding(days: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            VStack(spacing: 1) {
                Text(selectedDate.isSameDay(as: Date()) ? "Today" : selectedDate.shortDayOfWeek)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(selectedDate.formattedShortDate)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedDate = selectedDate.adding(days: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(selectedDate.isSameDay(as: Date()) ? .tertiary : .secondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedDate.isSameDay(as: Date()))
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: loggedCount, label: "Logged", color: Color.accentColor)
            Divider().frame(height: 24)
            statItem(value: productiveCount, label: "Productive", color: Color.green)
            Divider().frame(height: 24)
            statItem(value: max(0, 24 - loggedCount), label: "Remaining", color: Color.secondary)
        }
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#Preview {
    TodayView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
