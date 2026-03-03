import SwiftData
import Foundation

@Model
final class Snippet {
    var id: UUID
    var name: String
    var command: String
    var category: SnippetCategory?
    var isBuiltIn: Bool
    var requiresConfirmation: Bool
    var createdAt: Date
    var updatedAt: Date

    init(name: String, command: String, isBuiltIn: Bool = false, requiresConfirmation: Bool = false) {
        self.id = UUID()
        self.name = name
        self.command = command
        self.isBuiltIn = isBuiltIn
        self.requiresConfirmation = requiresConfirmation
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class SnippetCategory {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \Snippet.category)
    var snippets: [Snippet]

    init(name: String, iconName: String = "terminal") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = 0
        self.snippets = []
    }
}
