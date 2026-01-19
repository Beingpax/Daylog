//
//  HourEditSheet.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct HourEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let hour: Int
    let existingLog: HourLog?

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedProject: Project?
    @State private var notes: String = ""

    private var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let d = Calendar.current.date(from: components) {
            return formatter.string(from: d)
        }
        return "\(hour):00"
    }

    var body: some View {
        NavigationStack {
            List {
                projectSection
                notesSection
                if existingLog != nil {
                    deleteSection
                }
            }
            .navigationTitle(hourLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLog() }
                        .fontWeight(.semibold)
                        .disabled(selectedProject == nil)
                }
            }
            .onAppear {
                if let log = existingLog {
                    selectedProject = log.project
                    notes = log.notes
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var projectSection: some View {
        Section("Activity") {
            Picker("Project", selection: $selectedProject) {
                Text("None").tag(nil as Project?)
                ForEach(categories) { category in
                    ForEach((category.projects ?? []).sorted { $0.sortOrder < $1.sortOrder }) { project in
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

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                deleteLog()
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Log")
                    Spacer()
                }
            }
        }
    }

    private func saveLog() {
        guard let project = selectedProject else { return }

        if let log = existingLog {
            log.project = project
            log.notes = notes
            log.updatedAt = Date()
        } else {
            let newLog = HourLog(
                date: date,
                hour: hour,
                project: project,
                notes: notes
            )
            modelContext.insert(newLog)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteLog() {
        if let log = existingLog {
            modelContext.delete(log)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    HourEditSheet(date: Date(), hour: 9, existingLog: nil)
        .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
