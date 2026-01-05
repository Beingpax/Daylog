//
//  LogInputView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct LogInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let selectedDate: Date

    @Query(sort: \CategoryGroup.sortOrder) private var categoryGroups: [CategoryGroup]
    @Query private var allLogs: [HourLog]

    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var parsedEntries: [ParsedEntry] = []
    @State private var showingResults = false

    private var logsForDate: [HourLog] {
        allLogs.filter { $0.date.isSameDay(as: selectedDate.startOfDay) }
    }

    private var lastLoggedHour: Int? {
        logsForDate.map(\.hour).max()
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var startHour: Int {
        if let lastHour = lastLoggedHour {
            return (lastHour + 1) % 24
        }
        return 6
    }

    private var recentLogs: [OpenAIService.RecentLog] {
        let sortedLogs = logsForDate.sorted { $0.hour > $1.hour }
        return sortedLogs.prefix(5).map { log in
            OpenAIService.RecentLog(
                hour: log.hour,
                category: log.category?.name ?? "Unknown",
                notes: log.notes
            )
        }
    }

    struct ParsedEntry: Identifiable {
        let id = UUID()
        let hour: Int
        let categoryName: String
        let notes: String
        let mood: Mood?
        let extraDetails: String
        var category: Category?
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingResults {
                    resultsView
                } else {
                    inputView
                }
            }
            .navigationTitle("Log Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if showingResults {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save All") {
                            saveEntries()
                        }
                        .disabled(parsedEntries.isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private var inputView: some View {
        VStack(spacing: 0) {
            // Time range header
            timeRangeHeader
                .padding()
                .background(Color(.secondarySystemBackground))

            ScrollView {
                VStack(spacing: 20) {
                    // Recent activity context
                    if !recentLogs.isEmpty {
                        recentActivitySection
                    }

                    // Input section
                    inputSection
                }
                .padding()
            }

            // Process button
            processButton
                .padding()
                .background(Color(.secondarySystemBackground))
        }
    }

    private var timeRangeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Logging hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(formatHour(startHour)) → \(formatHour(currentHour))")
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Current time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatHour(currentHour))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.accentColor)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ForEach(recentLogs.reversed(), id: \.hour) { log in
                    HStack {
                        Text(formatHour(log.hour))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)

                        Text(log.category)
                            .font(.caption.weight(.medium))

                        if !log.notes.isEmpty {
                            Text("• \(log.notes)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Describe your activities", systemImage: "text.bubble")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)

                if inputText.isEmpty {
                    Text("e.g., \"Deep work on the new feature from 9 to 12, then had lunch and calls with clients until 3...\"")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Tap the microphone on your keyboard for voice input")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var processButton: some View {
        Button {
            processInput()
        } label: {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                }
                Image(systemName: isProcessing ? "brain" : "sparkles")
                Text(isProcessing ? "Processing..." : "Process with AI")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(inputText.isEmpty ? Color(.systemGray4) : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(inputText.isEmpty || isProcessing)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    showingResults = false
                    parsedEntries = []
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Edit")
                    }
                    .font(.subheadline)
                }

                Spacer()

                Text("\(parsedEntries.count) entries parsed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            List {
                ForEach(parsedEntries) { entry in
                    resultRow(entry: entry)
                }
            }
            .listStyle(.plain)
        }
    }

    private func resultRow(entry: ParsedEntry) -> some View {
        HStack(spacing: 12) {
            Text(formatHour(entry.hour))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .trailing)

            if let category = entry.category {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: category.group?.colorHex ?? "#8E8E93"))
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let category = entry.category {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(Color(hex: category.group?.colorHex ?? "#8E8E93"))
                    }
                    Text(entry.categoryName)
                        .font(.subheadline.weight(.medium))

                    if entry.category == nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let mood = entry.mood {
                    HStack(spacing: 4) {
                        Image(systemName: mood.icon)
                        Text(mood.displayName)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color(hex: mood.color))
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func processInput() {
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let categories = categoryGroups.flatMap { group in
                    group.categories.map { (name: $0.name, group: group.name) }
                }

                let service = OpenAIService()
                let results = try await service.parseLogInput(
                    input: inputText,
                    categories: categories,
                    currentDate: selectedDate,
                    lastLoggedHour: lastLoggedHour,
                    currentHour: currentHour,
                    recentLogs: recentLogs
                )

                await MainActor.run {
                    parsedEntries = results.map { result in
                        let category = findCategory(named: result.category)
                        return ParsedEntry(
                            hour: result.hour,
                            categoryName: result.category,
                            notes: result.notes,
                            mood: Mood(rawValue: result.mood),
                            extraDetails: result.extraDetails,
                            category: category
                        )
                    }.sorted { $0.hour < $1.hour }

                    showingResults = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }

    private func findCategory(named name: String) -> Category? {
        for group in categoryGroups {
            if let category = group.categories.first(where: { $0.name.lowercased() == name.lowercased() }) {
                return category
            }
        }
        return nil
    }

    private func saveEntries() {
        for entry in parsedEntries {
            if let existingLog = logsForDate.first(where: { $0.hour == entry.hour }) {
                existingLog.category = entry.category
                existingLog.notes = entry.notes
                existingLog.mood = entry.mood
                existingLog.extraDetails = entry.extraDetails
                existingLog.updatedAt = Date()
            } else {
                let newLog = HourLog(
                    date: selectedDate,
                    hour: entry.hour,
                    category: entry.category,
                    notes: entry.notes,
                    mood: entry.mood,
                    extraDetails: entry.extraDetails
                )
                modelContext.insert(newLog)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    LogInputView(selectedDate: Date())
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
