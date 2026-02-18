import Combine
import Foundation

@MainActor
class ChromeProfileService: ObservableObject {
  private var chromeProcess: Process?
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []

  func startAdd() async throws {
    guard
      let chromePath = Bundle.main.path(
        forResource: "Google Chrome for Testing",
        ofType: nil,
        inDirectory: "Google Chrome for Testing.app/Contents/MacOS"
      )
    else {
      throw ChromeProfileError.chromeNotFound
    }

    guard let chromeDataDir = getChromeDataDirectory() else {
      throw ChromeProfileError.dataDirectoryNotFound
    }

    // Create Chrome data directory if it doesn't exist
    try? FileManager.default.createDirectory(
      at: chromeDataDir,
      withIntermediateDirectories: true
    )

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [
      "-a", chromePath,
      "--args",
      "--user-data-dir=\(chromeDataDir.path)",
      "--profile-directory=Guest Profile",
    ]

    try process.run()
    chromeProcess = process

    startMonitoring()
  }

  func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  private func startMonitoring() {
    monitorTask?.cancel()

    // Capture initial profile state
    initialProfiles = getCurrentProfiles()

    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        let currentProfiles = self.getCurrentProfiles()

        // Check if a new profile was added
        if currentProfiles.count > self.initialProfiles.count {
          let newProfiles = currentProfiles.subtracting(self.initialProfiles)
          if !newProfiles.isEmpty {
            // New profile detected, terminate chrome process
            self.chromeProcess?.terminate()
            self.chromeProcess = nil
            self.stopMonitoring()
            return
          }
        }
      }
    }
  }

  private func getCurrentProfiles() -> Set<String> {
    guard let chromeDataDir = getChromeDataDirectory() else {
      return []
    }

    let fileManager = FileManager.default
    guard
      let contents = try? fileManager.contentsOfDirectory(
        at: chromeDataDir,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    var profiles: Set<String> = []
    for url in contents {
      let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
      if resourceValues?.isDirectory == true {
        let name = url.lastPathComponent
        // Match Default, Profile 1, Profile 2, etc.
        if name == "Default" || name.starts(with: "Profile ") {
          profiles.insert(name)
        }
      }
    }

    return profiles
  }

  private func getChromeDataDirectory() -> URL? {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      return nil
    }

    let fileManager = FileManager.default
    guard
      let appSupport = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first
    else {
      return nil
    }

    return
      appSupport
      .appendingPathComponent(bundleIdentifier)
      .appendingPathComponent("Chrome")
  }
}

enum ChromeProfileError: LocalizedError {
  case chromeNotFound
  case dataDirectoryNotFound

  var errorDescription: String? {
    switch self {
    case .chromeNotFound:
      return "Chrome for Testing not found"
    case .dataDirectoryNotFound:
      return "Could not create Chrome data directory"
    }
  }
}
