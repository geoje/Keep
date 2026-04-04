import Foundation
import SwiftData

extension ModelContainer {
  static let dataDirectory: URL = {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      fatalError("Bundle identifier not found")
    }

    let baseBundleIdentifier =
      bundleIdentifier
      .components(separatedBy: ".")
      .prefix(3)
      .joined(separator: ".")

    let fileManager = FileManager.default
    guard
      let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first
    else {
      fatalError("Application Support directory not found")
    }
    let dataDirectory = appSupportURL.appendingPathComponent(baseBundleIdentifier)
    try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    return dataDirectory
  }()

  static let shared: ModelContainer = {
    let schema = Schema([
      Account.self,
      Note.self,
    ])

    let url = ModelContainer.dataDirectory.appendingPathComponent("default.sqlite")
    let modelConfiguration = ModelConfiguration(schema: schema, url: url)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
