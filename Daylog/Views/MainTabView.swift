//
//  MainTabView.swift
//  Daylog
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "clock.fill")
                }
                .tag(0)

            WeeklyView()
                .tabItem {
                    Label("Week", systemImage: "calendar.badge.clock")
                }
                .tag(1)

            MonthlyView()
                .tabItem {
                    Label("Month", systemImage: "calendar")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}
