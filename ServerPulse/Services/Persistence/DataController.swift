import SwiftData
import Foundation

final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    init() {
        let schema = Schema([
            Server.self,
            ServerGroup.self,
            Snippet.self,
            SnippetCategory.self,
        ])
        let config = ModelConfiguration(
            "ServerPulse",
            schema: schema
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
