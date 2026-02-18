import Foundation
import SwiftData

extension ModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      PlayAccount.self,
      Note.self,
    ])

    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      fatalError("Bundle identifier not found")
    }

    let fileManager = FileManager.default
    guard
      let appSupport = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first
    else {
      fatalError("Application Support directory not found")
    }

    let dataDirectory = appSupport.appendingPathComponent(bundleIdentifier)
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
