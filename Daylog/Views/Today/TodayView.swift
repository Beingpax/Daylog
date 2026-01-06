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

    // Multi-select mode
    @State private var isSelectMode = false
    @State private var selectedHours: Set<Int> = []
    @State private var showMultiEditSheet = false

    @Query private var allLogs: [HourLog]

    private var logsForDate: [HourLog] {
        allLogs.filter { $0.date.isSameDay(as: selectedDate.startOfDay) }
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
                DailyTimelineView(
                    selectedDate: selectedDate,
                    isSelectMode: isSelectMode,
                    selectedHours: $selectedHours
                ) { hour, log in
                    editingHour = hour
                    editingLog = log
                }

                // Bottom toolbar for multi-select
                if isSelectMode && !selectedHours.isEmpty {
                    multiSelectToolbar
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DayLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelectMode {
                        Button("Cancel") {
                            withAnimation {
                                isSelectMode = false
                                selectedHours.removeAll()
                            }
                        }
                    } else {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelectMode ? "Done" : "Select") {
                        withAnimation {
                            if isSelectMode {
                                selectedHours.removeAll()
                            }
                            isSelectMode.toggle()
                        }
                    }
                }
            }
            .sheet(item: $editingHour) { hour in
                HourEditSheet(date: selectedDate, hour: hour, existingLog: editingLog)
            }
            .sheet(isPresented: $showMultiEditSheet) {
                MultiHourEditSheet(
                    date: selectedDate,
                    hours: Array(selectedHours).sorted(),
                    existingLogs: logsForDate.filter { selectedHours.contains($0.hour) }
                ) {
                    // On save completion
                    withAnimation {
                        isSelectMode = false
                        selectedHours.removeAll()
                    }
                }
            }
        }
    }

    private var multiSelectToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("\(selectedHours.count) hour\(selectedHours.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    showMultiEditSheet = true
                } label: {
                    Text("Add Log")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    private var headerSection: some View {
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
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

#Preview {
    TodayView()
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
