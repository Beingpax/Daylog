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

    @Query(sort: \CategoryGroup.sortOrder) private var categoryGroups: [CategoryGroup]

    @State private var selectedCategory: Category?
    @State private var energyLevel: Int = 5
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
                categorySection
                energySection
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
                        .disabled(selectedCategory == nil)
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

    private var categorySection: some View {
        Section("Activity") {
            Picker("Category", selection: $selectedCategory) {
                Text("None").tag(nil as Category?)
                ForEach(categoryGroups) { group in
                    ForEach(group.categories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
        }
    }

    private var energySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Energy Level")
                    Spacer()
                    Text("\(energyLevel) — \(energyLabel)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#34C759"))
                }

                EnergySlider(value: $energyLevel)
            }
        }
    }

    private var energyLabel: String {
        switch energyLevel {
        case 1: return "Exhausted"
        case 2: return "Very Low"
        case 3: return "Low"
        case 4: return "Below Average"
        case 5: return "Average"
        case 6: return "Above Average"
        case 7: return "Good"
        case 8: return "High"
        case 9: return "Very High"
        case 10: return "Peak Focus"
        default: return ""
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("What did you do?", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private func saveAll() {
        guard let category = selectedCategory else { return }

        // Create a lookup for existing logs by hour
        var existingByHour: [Int: HourLog] = [:]
        for log in existingLogs {
            existingByHour[log.hour] = log
        }

        for hour in hours {
            if let existing = existingByHour[hour] {
                // Update existing log
                existing.category = category
                existing.energyLevel = energyLevel
                existing.notes = notes
                existing.updatedAt = Date()
            } else {
                // Create new log
                let newLog = HourLog(
                    date: date,
                    hour: hour,
                    category: category,
                    notes: notes,
                    energyLevel: energyLevel
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
    .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
