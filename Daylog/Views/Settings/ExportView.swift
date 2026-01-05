//
//  ExportView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HourLog.date) private var logs: [HourLog]

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false

    var body: some View {
        Form {
            Section("Date Range") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }

            Section {
                Button {
                    exportToCSV()
                } label: {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Export to CSV")
                        Spacer()
                    }
                }
                .disabled(isExporting)
            } footer: {
                Text("Export all hour logs within the selected date range as a CSV file.")
            }

            Section("Preview") {
                let filteredLogs = logs.filter { log in
                    log.date >= startDate.startOfDay && log.date <= endDate.startOfDay
                }
                Text("\(filteredLogs.count) entries will be exported")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportToCSV() {
        isExporting = true

        Task {
            let filteredLogs = logs.filter { log in
                log.date >= startDate.startOfDay && log.date <= endDate.startOfDay
            }.sorted { ($0.date, $0.hour) < ($1.date, $1.hour) }

            let csvService = CSVExportService()
            if let url = csvService.exportLogs(filteredLogs) {
                await MainActor.run {
                    exportURL = url
                    showingShareSheet = true
                    isExporting = false
                }
            } else {
                await MainActor.run {
                    isExporting = false
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
