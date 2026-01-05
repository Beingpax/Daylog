//
//  CategoriesView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryGroup.sortOrder) private var groups: [CategoryGroup]

    @State private var showingAddSheet = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.categories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(Color(hex: group.colorHex))

                                Text(category.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        deleteCategories(group: group, at: offsets)
                    }
                } header: {
                    HStack {
                        Circle()
                            .fill(Color(hex: group.colorHex))
                            .frame(width: 10, height: 10)
                        Text(group.name)
                    }
                }
            }
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
        }
        .sheet(isPresented: $showingAddSheet) {
            CategoryEditSheet(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditSheet(category: category)
        }
    }

    private func deleteCategories(group: CategoryGroup, at offsets: IndexSet) {
        let sortedCategories = group.categories.sorted { $0.sortOrder < $1.sortOrder }
        for index in offsets {
            modelContext.delete(sortedCategories[index])
        }
        try? modelContext.save()
    }
}

struct CategoryEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CategoryGroup.sortOrder) private var groups: [CategoryGroup]

    let category: Category?

    @State private var name: String = ""
    @State private var icon: String = "circle.fill"
    @State private var selectedGroup: CategoryGroup?

    private let iconOptions = [
        "circle.fill", "brain.head.profile", "book.fill", "figure.run",
        "hammer.fill", "calendar", "folder.fill", "pencil.line",
        "iphone", "tv.fill", "clock.fill", "sparkles",
        "moon.fill", "fork.knife", "heart.fill", "cup.and.saucer.fill",
        "cart.fill", "heart.circle.fill", "person.2.fill", "house.fill",
        "network", "laptopcomputer", "gamecontroller.fill", "music.note",
        "phone.fill", "envelope.fill", "car.fill", "airplane"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Group") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("None").tag(nil as CategoryGroup?)
                        ForEach(groups) { group in
                            HStack {
                                Circle()
                                    .fill(Color(hex: group.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(group.name)
                            }
                            .tag(group as CategoryGroup?)
                        }
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            iconButton(for: iconName)
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedGroup == nil)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    icon = category.icon
                    selectedGroup = category.group
                } else if selectedGroup == nil {
                    selectedGroup = groups.first
                }
            }
        }
    }

    @ViewBuilder
    private func iconButton(for iconName: String) -> some View {
        let isSelected = icon == iconName
        Button {
            icon = iconName
        } label: {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
    }

    private func save() {
        if let category = category {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.icon = icon
            category.group = selectedGroup
        } else {
            let newCategory = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                sortOrder: 999,
                group: selectedGroup
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
    .modelContainer(for: [CategoryGroup.self, Category.self, HourLog.self], inMemory: true)
}
