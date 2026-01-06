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
        let targetDate = selectedDate.startOfDay
        let filtered = allLogs.filter { log in
            log.date.isSameDay(as: targetDate)
        }
        var dict: [Int: HourLog] = [:]
        for log in filtered {
            dict[log.hour] = log
        }
        return dict
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(0..<24, id: \.self) { hour in
                        HourBlockView(
                            hour: hour,
                            log: logsForDate[hour],
                            isCurrentHour: selectedDate.isSameDay(as: Date()) && hour == currentHour,
                            onTap: { onHourTap(hour, logsForDate[hour]) }
                        )
                        .id(hour)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                scrollToRelevantHour(proxy: proxy)
            }
            .onChange(of: selectedDate) { _, _ in
                scrollToRelevantHour(proxy: proxy)
            }
        }
    }

    private func scrollToRelevantHour(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if selectedDate.isSameDay(as: Date()) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(max(0, currentHour - 2), anchor: .top)
                }
            } else {
                let firstLoggedHour = logsForDate.keys.min() ?? 6
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(max(0, firstLoggedHour - 1), anchor: .top)
                }
            }
        }
    }
}

#Preview {
    DailyTimelineView(selectedDate: Date()) { _, _ in }
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
