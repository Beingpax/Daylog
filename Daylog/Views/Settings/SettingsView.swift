//
//  SettingsView.swift
//  Daylog
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    NavigationLink {
                        CategoryGroupsView()
                    } label: {
                        Label("Category Groups", systemImage: "folder.fill")
                    }

                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Categories", systemImage: "tag.fill")
                    }
                }

                Section("Data") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
