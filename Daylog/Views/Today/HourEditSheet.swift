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
        var startComponents = DateComponents()
        startComponents.hour = hour
        var endComponents = DateComponents()
        endComponents.hour = (hour + 1) % 24

        if let startDate = Calendar.current.date(from: startComponents),
           let endDate = Calendar.current.date(from: endComponents) {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
        return "\(hour):00 - \((hour + 1) % 24):00"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(hourLabel)
                        Spacer()
                        Text(date.formattedShortDate)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Category") {
                    ForEach(categoryGroups) { group in
                        categoryGroupSection(group: group)
                    }
                }

                Section("Mood") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(Mood.allCases) { mood in
                            moodButton(mood: mood)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("What did you do?", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Extra Details") {
                    TextField("Additional context...", text: $extraDetails, axis: .vertical)
                        .lineLimit(2...4)
                }

                if existingLog != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteLog()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Entry")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Hour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
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
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func categoryGroupSection(group: CategoryGroup) -> some View {
        let groupColor = Color(hex: group.colorHex)
        let sortedCategories = group.categories.sorted { $0.sortOrder < $1.sortOrder }

        DisclosureGroup {
            ForEach(sortedCategories) { category in
                categoryRow(category: category, groupColor: groupColor)
            }
        } label: {
            HStack {
                Circle()
                    .fill(groupColor)
                    .frame(width: 12, height: 12)
                Text(group.name)
                    .fontWeight(.medium)
            }
        }
    }

    @ViewBuilder
    private func categoryRow(category: Category, groupColor: Color) -> some View {
        let isSelected = selectedCategory?.id == category.id

        Button {
            selectedCategory = category
        } label: {
            HStack {
                Image(systemName: category.icon)
                    .frame(width: 24)
                    .foregroundStyle(groupColor)

                Text(category.name)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                       
                }
            }
        }
    }

    @ViewBuilder
    private func moodButton(mood: Mood) -> some View {
        let isSelected = selectedMood == mood
        let moodColor = Color(hex: mood.color)

        Button {
            selectedMood = mood
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? moodColor.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? moodColor : Color.clear, lineWidth: 2)
            )
        }
        .foregroundStyle(isSelected ? moodColor : Color.secondary)
    }

    private func saveLog() {
        if let existingLog = existingLog {
            existingLog.category = selectedCategory
            existingLog.notes = notes
            existingLog.mood = selectedMood
            existingLog.extraDetails = extraDetails
            existingLog.updatedAt = Date()
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
