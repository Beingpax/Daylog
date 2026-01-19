//
//  ProjectsView.swift
//  Daylog
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingAddSheet = false
    @State private var editingProject: Project?

    var body: some View {
        List {
            ForEach(categories) { category in
                Section {
                    ForEach(category.projects.sorted { $0.sortOrder < $1.sortOrder }) { project in
                        Button {
                            editingProject = project
                        } label: {
                            HStack {
                                Image(systemName: project.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(Color(hex: category.colorHex))

                                Text(project.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        deleteProjects(category: category, at: offsets)
                    }
                } header: {
                    HStack {
                        Circle()
                            .fill(Color(hex: category.colorHex))
                            .frame(width: 10, height: 10)
                        Text(category.name)
                    }
                }
            }
        }
        .navigationTitle("Projects")
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
            ProjectEditSheet(project: nil)
        }
        .sheet(item: $editingProject) { project in
            ProjectEditSheet(project: project)
        }
    }

    private func deleteProjects(category: Category, at offsets: IndexSet) {
        let sortedProjects = category.projects.sorted { $0.sortOrder < $1.sortOrder }
        for index in offsets {
            modelContext.delete(sortedProjects[index])
        }
        try? modelContext.save()
    }
}

struct ProjectEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let project: Project?

    @State private var name: String = ""
    @State private var icon: String = "circle.fill"
    @State private var selectedCategory: Category?

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
                    TextField("Project Name", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: 12, height: 12)
                                Text(category.name)
                            }
                            .tag(category as Category?)
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
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory == nil)
                }
            }
            .onAppear {
                if let project = project {
                    name = project.name
                    icon = project.icon
                    selectedCategory = project.category
                } else if selectedCategory == nil {
                    selectedCategory = categories.first
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
        if let project = project {
            project.name = name.trimmingCharacters(in: .whitespaces)
            project.icon = icon
            project.category = selectedCategory
        } else {
            let newProject = Project(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                sortOrder: 999,
                category: selectedCategory
            )
            modelContext.insert(newProject)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
    }
    .modelContainer(for: [Category.self, Project.self, HourLog.self], inMemory: true)
}
