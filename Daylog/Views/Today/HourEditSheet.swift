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
    @State private var productivityLevel: Int = 5
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
                categorySection
                productivitySection
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
                        .disabled(selectedCategory == nil)
                }
            }
            .onAppear {
                if let log = existingLog {
                    selectedCategory = log.category
                    productivityLevel = log.productivityLevel
                    notes = log.notes
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
        guard let category = selectedCategory else { return }

        if let log = existingLog {
            log.category = category
            log.productivityLevel = productivityLevel
            log.notes = notes
            log.updatedAt = Date()
        } else {
            let newLog = HourLog(
                date: date,
                hour: hour,
                category: category,
                notes: notes,
                productivityLevel: productivityLevel
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

struct ProductivitySlider: View {
    @Binding var value: Int

    private let gradient = LinearGradient(
        colors: [
            Color(hex: "#A8E6CF"),  // Light green
            Color(hex: "#34C759")   // Dark green
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 6)

                // Gradient fill
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, thumbPosition(in: geo.size.width) + 12), height: 6)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .offset(x: thumbPosition(in: geo.size.width) - 12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = Int(round(gesture.location.x / geo.size.width * 9)) + 1
                                value = min(max(newValue, 1), 10)
                            }
                    )
            }
        }
        .frame(height: 28)
    }

    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let progress = CGFloat(value - 1) / 9.0
        return progress * width
    }
}

#Preview {
    HourEditSheet(date: Date(), hour: 9, existingLog: nil)
        .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
