import SwiftUI
import SwiftData

struct SnippetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @Query(sort: \Snippet.name) private var snippets: [Snippet]
    @Query(sort: \SnippetCategory.sortOrder) private var categories: [SnippetCategory]
    @State private var searchText = ""
    @State private var selectedSnippet: Snippet?
    @State private var showAddSheet = false
    @State private var showAddCategory = false
    @State private var showRenameCategory = false
    @State private var renameCategoryName = ""
    @State private var renamingCategory: SnippetCategory?

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty { return snippets }
        return snippets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.command.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var uncategorized: [Snippet] {
        filteredSnippets.filter { $0.category == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc["snippets.title"])
                    .font(.system(size: AppTheme.scaled(24), weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer()

                HStack(spacing: 12) {
                    TextField(loc["snippets.search"], text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)

                    Button {
                        showAddCategory = true
                    } label: {
                        Label(loc["snippets.button.category"], systemImage: "folder.badge.plus")
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .buttonStyle(.bordered)
                    .handCursorOnHover()

                    Button {
                        showAddSheet = true
                    } label: {
                        Label(loc["snippets.button.snippet"], systemImage: "plus")
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.buttonPrimary)
                    .handCursorOnHover()
                }
            }
            .padding(.horizontal, AppTheme.paddingLarge)
            .padding(.vertical, AppTheme.paddingMedium)

            if snippets.isEmpty && categories.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                HSplitView {
                    snippetsList
                        .frame(minWidth: 300)
                    snippetDetail
                        .frame(minWidth: 400)
                }
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showAddSheet) {
            AddSnippetSheet(categories: categories)
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: AppTheme.scaled(48)))
                .foregroundStyle(AppTheme.textTertiary)
            Text(loc["snippets.empty.title"])
                .font(.system(size: AppTheme.scaled(18), weight: .semibold))
                .foregroundStyle(AppTheme.textMuted)
            Text(loc["snippets.empty.subtitle"])
                .font(.system(size: AppTheme.scaled(12)))
                .foregroundStyle(AppTheme.textTertiary)
            Button(loc["snippets.button.add"]) { showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.buttonPrimary)
                .handCursorOnHover()
        }
    }

    private var snippetsList: some View {
        List(selection: $selectedSnippet) {
            ForEach(categories) { category in
                let categorySnippets = filteredSnippets.filter { $0.category?.id == category.id }
                if !categorySnippets.isEmpty {
                    Section {
                        ForEach(categorySnippets) { snippet in
                            snippetRow(snippet)
                                .tag(snippet)
                        }
                    } header: {
                        HStack(spacing: 4) {
                            Image(systemName: category.iconName)
                                .font(.system(size: AppTheme.scaled(10)))
                            Text(category.name)
                        }
                        .contextMenu {
                            Button(loc["snippets.context.rename"]) {
                                renamingCategory = category
                                renameCategoryName = category.name
                                showRenameCategory = true
                            }
                            Divider()
                            Button(loc["snippets.category.delete"], role: .destructive) {
                                deleteCategory(category)
                            }
                        }
                    }
                }
            }

            if !uncategorized.isEmpty {
                Section(loc["snippets.uncategorized"]) {
                    ForEach(uncategorized) { snippet in
                        snippetRow(snippet)
                            .tag(snippet)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .alert(loc["snippets.category.rename"], isPresented: $showRenameCategory) {
            TextField(loc["snippets.name"], text: $renameCategoryName)
            Button(loc["snippets.cancel"], role: .cancel) { }
            Button(loc["snippets.category.rename_action"]) {
                renamingCategory?.name = renameCategoryName
                renamingCategory = nil
            }
        }
    }

    private func deleteCategory(_ category: SnippetCategory) {
        // Snippets in this category become uncategorized (deleteRule: .nullify)
        modelContext.delete(category)
    }

    private func snippetRow(_ snippet: Snippet) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snippet.name)
                .font(.system(size: AppTheme.scaled(13), weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
            Text(snippet.command)
                .font(.system(size: AppTheme.scaled(11), design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(1)
        }
        .contextMenu {
            Button(loc["snippets.context.delete"], role: .destructive) {
                if selectedSnippet?.id == snippet.id {
                    selectedSnippet = nil
                }
                modelContext.delete(snippet)
            }
        }
    }

    @ViewBuilder
    private var snippetDetail: some View {
        if let snippet = selectedSnippet {
            SnippetDetailView(snippet: snippet, categories: categories)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: AppTheme.scaled(36)))
                    .foregroundStyle(AppTheme.textTertiary)
                Text(loc["snippets.select"])
                    .foregroundStyle(AppTheme.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Snippet Detail

struct SnippetDetailView: View {
    @Bindable var snippet: Snippet
    let categories: [SnippetCategory]
    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(loc["snippets.name"], text: $snippet.name)
                .font(.system(size: AppTheme.scaled(18), weight: .semibold))
                .textFieldStyle(.plain)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(loc["snippets.command"])
                    .font(.system(size: AppTheme.scaled(12), weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)

                TextEditor(text: $snippet.command)
                    .font(.system(size: AppTheme.scaled(13), design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(AppTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    .frame(minHeight: 100, maxHeight: 200)
            }

            HStack(spacing: 16) {
                Picker(loc["snippets.category"], selection: $snippet.category) {
                    Text(loc["snippets.none"]).tag(nil as SnippetCategory?)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat as SnippetCategory?)
                    }
                }
                .frame(width: 200)

                Toggle(loc["snippets.confirm"], isOn: $snippet.requiresConfirmation)
            }

            Spacer()
        }
        .padding(AppTheme.paddingLarge)
        .onChange(of: snippet.name) { _, _ in snippet.updatedAt = Date() }
        .onChange(of: snippet.command) { _, _ in snippet.updatedAt = Date() }
    }
}

// MARK: - Add Snippet Sheet

struct AddSnippetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    let categories: [SnippetCategory]

    @State private var name = ""
    @State private var command = ""
    @State private var selectedCategory: SnippetCategory?
    @State private var requiresConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            Text(loc["snippets.add.title"])
                .font(.headline)
                .padding(.top)

            Form {
                TextField(loc["snippets.name"], text: $name)
                TextField(loc["snippets.command"], text: $command, axis: .vertical)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(3...6)

                Picker(loc["snippets.category"], selection: $selectedCategory) {
                    Text(loc["snippets.none"]).tag(nil as SnippetCategory?)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat as SnippetCategory?)
                    }
                }

                Toggle(loc["snippets.add.confirm"], isOn: $requiresConfirmation)
            }
            .formStyle(.grouped)

            HStack {
                Button(loc["snippets.cancel"]) { dismiss() }
                    .buttonStyle(.bordered)
                    .handCursorOnHover()
                Spacer()
                Button(loc["snippets.save"]) {
                    let snippet = Snippet(
                        name: name,
                        command: command,
                        requiresConfirmation: requiresConfirmation
                    )
                    snippet.category = selectedCategory
                    modelContext.insert(snippet)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.buttonPrimary)
                .disabled(name.isEmpty || command.isEmpty)
                .handCursorOnHover()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 450, height: 400)
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var name = ""
    @State private var selectedIcon = "terminal"

    private let iconOptions = [
        ("terminal", "category.icon.terminal"),
        ("server.rack", "category.icon.server"),
        ("network", "category.icon.network"),
        ("externaldrive", "category.icon.disk"),
        ("shield", "category.icon.security"),
        ("wrench", "category.icon.tools"),
        ("doc.text", "category.icon.logs"),
        ("arrow.triangle.2.circlepath", "category.icon.services"),
        ("cube", "category.icon.docker"),
        ("chart.bar", "category.icon.monitoring"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text(loc["snippets.category.add"])
                .font(.headline)
                .padding(.top)

            Form {
                TextField(loc["snippets.name"], text: $name)

                Picker(loc["snippets.category.icon"], selection: $selectedIcon) {
                    ForEach(iconOptions, id: \.0) { icon, labelKey in
                        Label(loc[labelKey], systemImage: icon).tag(icon)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button(loc["snippets.category.cancel"]) { dismiss() }
                    .buttonStyle(.bordered)
                    .handCursorOnHover()
                Spacer()
                Button(loc["snippets.category.create"]) {
                    let category = SnippetCategory(name: name, iconName: selectedIcon)
                    modelContext.insert(category)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.buttonPrimary)
                .disabled(name.isEmpty)
                .handCursorOnHover()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 350, height: 280)
    }
}
