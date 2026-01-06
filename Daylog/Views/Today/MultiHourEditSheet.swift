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
    @State private var productivityLevel: Int = 5
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
                productivitySection
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

    private var productivitySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Text("Productivity")
                    Spacer()
                    Text("\(productivityLevel) — \(productivityLabel)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "#34C759"))
                }

                ProductivitySlider(value: $productivityLevel)
            }
        }
    }

    private var productivityLabel: String {
        switch productivityLevel {
        case 1: return "Idle"
        case 2: return "Stalled"
        case 3: return "Slow"
        case 4: return "Sluggish"
        case 5: return "Steady"
        case 6: return "Active"
        case 7: return "Focused"
        case 8: return "Driven"
        case 9: return "Flowing"
        case 10: return "Peak"
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
                existing.productivityLevel = productivityLevel
                existing.notes = notes
                existing.updatedAt = Date()
            } else {
                // Create new log
                let newLog = HourLog(
                    date: date,
                    hour: hour,
                    category: category,
                    notes: notes,
                    productivityLevel: productivityLevel
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
