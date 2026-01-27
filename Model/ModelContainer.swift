import SwiftData

extension ModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      Account.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
