//
//  SettingsView.swift
//  Daylog
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Organization") {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Categories", systemImage: "folder.fill")
                    }

                    NavigationLink {
                        ProjectsView()
                    } label: {
                        Label("Projects", systemImage: "tag.fill")
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
