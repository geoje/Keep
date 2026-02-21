import Foundation
import SwiftData

extension ModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      Account.self,
      Note.self,
    ])

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
      let containerURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: "group.\(baseBundleIdentifier)")
    else {
      fatalError("App Group container not found")
    }

    let dataDirectory = containerURL
    try? fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

    let url = dataDirectory.appendingPathComponent("default.sqlite")
    let modelConfiguration = ModelConfiguration(schema: schema, url: url)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
