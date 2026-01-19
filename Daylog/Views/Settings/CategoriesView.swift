//
//  CategoriesView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingAddSheet = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: category.colorHex))
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .foregroundStyle(.primary)

                            Text("\(category.projects.count) projects")
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
            .onDelete(perform: deleteCategories)
            .onMove(perform: moveCategories)
        }
        .navigationTitle("Categories")
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
            CategoryEditSheet(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(category: category)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        try? modelContext.save()
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reorderedCategories = categories
        reorderedCategories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reorderedCategories.enumerated() {
            category.sortOrder = index
        }
        try? modelContext.save()
    }
}

struct CategoryEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: Category?

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
                    TextField("Category Name", text: $name)
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
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
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
                if let category = category {
                    name = category.name
                    selectedColor = category.colorHex
                }
            }
        }
    }

    private func save() {
        if let category = category {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.colorHex = selectedColor
        } else {
            let newCategory = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                colorHex: selectedColor,
                sortOrder: 999
            )
            modelContext.insert(newCategory)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
    .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
