//
//  SettingsView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingResetConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

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

                #if DEBUG
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Deletes all data and restores default categories and projects.")
                }
                #endif

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
            .alert("Reset All Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all your data and restore the default categories and projects. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func resetAllData() {
        do {
            try DataManagementService.resetToDefaults(context: modelContext)
        } catch {
            errorMessage = "Failed to reset data: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}
