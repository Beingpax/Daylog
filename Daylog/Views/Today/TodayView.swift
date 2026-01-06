//
//  TodayView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @State private var selectedDate = Date()
    @State private var editingHour: Int?
    @State private var editingLog: HourLog?

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
                // Header
                headerSection
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Timeline
                DailyTimelineView(selectedDate: selectedDate) { hour, log in
                    editingHour = hour
                    editingLog = log
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DayLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { selectedDate = Date() }
                    } label: {
                        Text("Today")
                            .font(.subheadline)
                    }
                    .opacity(selectedDate.isSameDay(as: Date()) ? 0.3 : 1)
                    .disabled(selectedDate.isSameDay(as: Date()))
                }
            }
            .sheet(item: $editingHour) { hour in
                HourEditSheet(date: selectedDate, hour: hour, existingLog: editingLog)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Date navigation
            HStack {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedDate = selectedDate.adding(days: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(selectedDate.isSameDay(as: Date()) ? "Today" : selectedDate.shortDayOfWeek)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(selectedDate.formattedShortDate)
                        .font(.title3.weight(.semibold))
                }

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedDate = selectedDate.adding(days: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.medium))
                        .foregroundStyle(selectedDate.isSameDay(as: Date()) ? .tertiary : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.tertiarySystemFill), in: Circle())
                }
                .disabled(selectedDate.isSameDay(as: Date()))
            }

            // Stats
            HStack(spacing: 12) {
                StatCard(value: loggedCount, total: 24, label: "Logged", color: .accentColor)
                StatCard(value: productiveCount, total: loggedCount, label: "Productive", color: .green)
            }
        }
    }
}

struct StatCard: View {
    let value: Int
    let total: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
                Text("/\(total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#Preview {
    TodayView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
