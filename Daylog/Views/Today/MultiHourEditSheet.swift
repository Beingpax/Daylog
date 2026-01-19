//
//  MultiHourEditSheet.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct MultiHourEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let hours: [Int]
    let existingLogs: [HourLog]
    let onSave: () -> Void

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedProject: Project?
    @State private var notes: String = ""

    private var hoursLabel: String {
        guard let first = hours.first, let last = hours.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var startComponents = DateComponents()
        startComponents.hour = first
        var endComponents = DateComponents()
        endComponents.hour = last

        if let startDate = Calendar.current.date(from: startComponents),
           let endDate = Calendar.current.date(from: endComponents) {
            return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
        }
        return "\(hours.count) hours"
    }

    var body: some View {
        NavigationStack {
            List {
                hoursSection
                projectSection
                notesSection
            }
            .navigationTitle("\(hours.count) Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveAll() }
                        .fontWeight(.semibold)
                        .disabled(selectedProject == nil)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var hoursSection: some View {
        Section {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(hoursLabel)
                    .font(.subheadline)
                Spacer()
                Text("\(hours.count) blocks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var projectSection: some View {
        Section("Activity") {
            Picker("Project", selection: $selectedProject) {
                Text("None").tag(nil as Project?)
                ForEach(categories) { category in
                    ForEach(category.projects.sorted { $0.sortOrder < $1.sortOrder }) { project in
                        Text(project.name).tag(project as Project?)
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("What did you do?", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private func saveAll() {
        guard let project = selectedProject else { return }

        // Create a lookup for existing logs by hour
        var existingByHour: [Int: HourLog] = [:]
        for log in existingLogs {
            existingByHour[log.hour] = log
        }

        for hour in hours {
            if let existing = existingByHour[hour] {
                // Update existing log
                existing.project = project
                existing.notes = notes
                existing.updatedAt = Date()
            } else {
                // Create new log
                let newLog = HourLog(
                    date: date,
                    hour: hour,
                    project: project,
                    notes: notes
                )
                modelContext.insert(newLog)
            }
        }

        try? modelContext.save()
        dismiss()
        onSave()
    }
}

#Preview {
    MultiHourEditSheet(
        date: Date(),
        hours: [9, 10, 11, 12],
        existingLogs: [],
        onSave: {}
    )
    .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
