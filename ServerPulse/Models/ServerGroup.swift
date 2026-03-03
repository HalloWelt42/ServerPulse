import SwiftData
import Foundation

@Model
final class ServerGroup {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \Server.group)
    var servers: [Server]

    init(name: String, colorHex: String = "#e04040") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = 0
        self.servers = []
    }
}
