//
//  CategoryGroupsView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct CategoryGroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryGroup.sortOrder) private var groups: [CategoryGroup]

    @State private var showingAddSheet = false
    @State private var editingGroup: CategoryGroup?

    var body: some View {
        List {
            ForEach(groups) { group in
                Button {
                    editingGroup = group
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: group.colorHex))
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .foregroundStyle(.primary)

                            Text("\(group.categories.count) categories")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete(perform: deleteGroups)
            .onMove(perform: moveGroups)
        }
        .navigationTitle("Category Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryGroupEditSheet(group: nil)
        }
        .sheet(item: $editingGroup) { group in
            CategoryGroupEditSheet(group: group)
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(groups[index])
        }
        try? modelContext.save()
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var reorderedGroups = groups
        reorderedGroups.move(fromOffsets: source, toOffset: destination)
        for (index, group) in reorderedGroups.enumerated() {
            group.sortOrder = index
        }
        try? modelContext.save()
    }
}

struct CategoryGroupEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let group: CategoryGroup?

    @State private var name: String = ""
    @State private var selectedColor: String = "#34C759"

    private let colorOptions = [
        "#34C759", // Green
        "#FF3B30", // Red
        "#007AFF", // Blue
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#5856D6", // Indigo
        "#00C7BE", // Teal
        "#FF2D55", // Pink
        "#8E8E93", // Gray
        "#FFCC00"  // Yellow
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Group Name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 3)
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.caption.weight(.bold))
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(group == nil ? "New Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let group = group {
                    name = group.name
                    selectedColor = group.colorHex
                }
            }
        }
    }

    private func save() {
        if let group = group {
            group.name = name.trimmingCharacters(in: .whitespaces)
            group.colorHex = selectedColor
        } else {
            let newGroup = CategoryGroup(
                name: name.trimmingCharacters(in: .whitespaces),
                colorHex: selectedColor,
                sortOrder: 999
            )
            modelContext.insert(newGroup)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoryGroupsView()
    }
    .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
