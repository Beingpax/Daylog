//
//  TodayView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var showingLogInput = false
    @State private var selectedHourLog: HourLog?
    @State private var selectedHour: Int?

    @Query private var allLogs: [HourLog]

    private var logsForDate: [HourLog] {
        allLogs.filter { $0.date.isSameDay(as: selectedDate.startOfDay) }
    }

    private var loggedHoursCount: Int {
        logsForDate.count
    }

    private var productiveHours: Int {
        logsForDate.filter { $0.category?.group?.name == "Productive" }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact date header
                dateHeader
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                // Stats bar
                statsBar
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                Divider()

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLogInput = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedDate = Date()
                    } label: {
                        Text("Today")
                            .font(.subheadline)
                    }
                    .opacity(selectedDate.isSameDay(as: Date()) ? 0.3 : 1)
                    .disabled(selectedDate.isSameDay(as: Date()))
                }
            }
            .sheet(isPresented: $showingLogInput) {
                LogInputView(selectedDate: selectedDate)
            }
            .sheet(item: $selectedHour) { hour in
                HourEditSheet(
                    date: selectedDate,
                    hour: hour,
                    existingLog: selectedHourLog
                )
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = selectedDate.adding(days: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate.isSameDay(as: Date()) ? "Today" : selectedDate.dayOfWeek)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(selectedDate.formattedDate)
                    .font(.headline)
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = selectedDate.adding(days: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(selectedDate.isSameDay(as: Date()) ? .tertiary : .secondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedDate.isSameDay(as: Date()))
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            statItem(value: "\(loggedHoursCount)", label: "Logged", color: .accentColor)
            statItem(value: "\(productiveHours)", label: "Productive", color: .green)
            statItem(value: "\(24 - loggedHoursCount)", label: "Remaining", color: .secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
