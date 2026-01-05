//
//  DailyTimelineView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct DailyTimelineView: View {
    let selectedDate: Date
    let onHourTap: (Int, HourLog?) -> Void

    @Query private var allLogs: [HourLog]

    private var logsForDate: [Int: HourLog] {
        let dayStart = selectedDate.startOfDay
        let filtered = allLogs.filter { $0.date.isSameDay(as: dayStart) }
        return Dictionary(uniqueKeysWithValues: filtered.map { ($0.hour, $0) })
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(0..<24, id: \.self) { hour in
                        HourBlockView(
                            hour: hour,
                            log: logsForDate[hour],
                            isCurrentHour: selectedDate.isSameDay(as: Date()) && hour == currentHour
                        )
                        .id(hour)
                        .onTapGesture {
                            onHourTap(hour, logsForDate[hour])
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onAppear {
                if selectedDate.isSameDay(as: Date()) {
                    withAnimation {
                        proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                    }
                }
            }
            .onChange(of: selectedDate) { _, newDate in
                if newDate.isSameDay(as: Date()) {
                    withAnimation {
                        proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                    }
                } else {
                    withAnimation {
                        proxy.scrollTo(6, anchor: .top)
                    }
                }
            }
        }
    }
}

#Preview {
    DailyTimelineView(selectedDate: Date()) { _, _ in }
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
