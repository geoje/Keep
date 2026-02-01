import Foundation
import SwiftData

extension ModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      Account.self,
      Note.self,
    ])
    let appGroupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.kr.ygh.keep")!
    try? FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true)
    let url = appGroupURL.appendingPathComponent("default.sqlite")
    let modelConfiguration = ModelConfiguration(schema: schema, url: url)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
