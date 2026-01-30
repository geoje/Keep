import Foundation
import SwiftData

extension ModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      Account.self,
      Note.self,
    ])
    let bundleID = Bundle.main.bundleIdentifier ?? "kr.ygh.keep"
    let appSupportURL = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    let dbFolderURL = appSupportURL.appendingPathComponent(bundleID)
    try? FileManager.default.createDirectory(at: dbFolderURL, withIntermediateDirectories: true)
    let url = dbFolderURL.appendingPathComponent("default.sqlite")
    let modelConfiguration = ModelConfiguration(schema: schema, url: url)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
