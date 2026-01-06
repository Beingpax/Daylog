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

    @Query(sort: \CategoryGroup.sortOrder) private var categoryGroups: [CategoryGroup]

    @State private var selectedCategory: Category?
    @State private var notes: String = ""
    @State private var selectedMood: Mood?
    @State private var extraDetails: String = ""

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
                // Time display
                Section {
                    HStack {
                        Text(hourLabel)
                            .font(.title2.weight(.medium))
                        Spacer()
                        Text(date.formattedShortDate)
                            .foregroundStyle(.secondary)
                    }
                }

                // Category selection
                Section("Category") {
                    ForEach(categoryGroups) { group in
                        categoryGroupRow(group: group)
                    }
                }

                // Mood selection
                Section("Mood") {
                    moodGrid
                }

                // Notes
                Section("Notes") {
                    TextField("What did you do?", text: $notes)
                }

                // Delete button
                if existingLog != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteLog()
                        } label: {
                            Text("Delete")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLog() }
                        .fontWeight(.medium)
                        .disabled(selectedCategory == nil)
                }
            }
            .onAppear {
                if let log = existingLog {
                    selectedCategory = log.category
                    notes = log.notes
                    selectedMood = log.mood
                    extraDetails = log.extraDetails
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func categoryGroupRow(group: CategoryGroup) -> some View {
        let color = Color(hex: group.colorHex)

        DisclosureGroup {
            ForEach(group.categories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                Button {
                    selectedCategory = category
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: category.icon)
                            .font(.subheadline)
                            .foregroundStyle(color)
                            .frame(width: 20)

                        Text(category.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedCategory?.id == category.id {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(group.name)
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    private var moodGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
            ForEach(Mood.allCases) { mood in
                let isSelected = selectedMood == mood
                let moodColor = Color(hex: mood.color)

                Button {
                    selectedMood = mood
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mood.icon)
                            .font(.title3)
                        Text(mood.displayName)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? moodColor.opacity(0.15) : Color(.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? moodColor : Color.clear, lineWidth: 1.5)
                    )
                }
                .foregroundStyle(isSelected ? moodColor : Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func saveLog() {
        if let log = existingLog {
            log.category = selectedCategory
            log.notes = notes
            log.mood = selectedMood
            log.extraDetails = extraDetails
            log.updatedAt = Date()
        } else {
            let newLog = HourLog(
                date: date,
                hour: hour,
                category: selectedCategory,
                notes: notes,
                mood: selectedMood,
                extraDetails: extraDetails
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
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
