import Combine
import Foundation

struct ProfileAccountInfo {
  let email: String
  let pictureUrl: String
}

@MainActor
class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []
  var onAddSuccess: (() -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

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

    startMonitoring()
  }

  func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  private func startMonitoring() {
    monitorTask?.cancel()

    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      // Capture initial profile state after Chrome has started
      self.initialProfiles = self.getCurrentProfiles()

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        let currentProfiles = self.getCurrentProfiles()

        // Check if a new profile was added (profiles that exist now but didn't exist initially)
        let newProfiles = currentProfiles.subtracting(self.initialProfiles)
        if !newProfiles.isEmpty {
          // Check all current profiles for NewTabPage
          for profileName in currentProfiles {
            if self.hasNewTabPage(profileName: profileName) {
              // Profile with NewTabPage detected, cleanup
              self.stopMonitoring()
              await self.chromeDriverService.cleanup()
              self.onAddSuccess?()
              return
            }
          }
        }
      }
    }
  }

  func getCurrentProfiles() -> Set<String> {
    guard let chromeDataDir = getChromeDataDirectory() else {
      return []
    }

    let fileManager = FileManager.default
    guard
      let contents = try? fileManager.contentsOfDirectory(
        at: chromeDataDir,
        includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey],
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
        // Match Default, Profile 1, Profile 2, etc. (exclude Guest Profile)
        if name == "Default" || name.starts(with: "Profile ") {
          // Check if profile has Preferences file (indicates it's fully created)
          let preferencesPath = url.appendingPathComponent("Preferences")
          if fileManager.fileExists(atPath: preferencesPath.path) {
            profiles.insert(name)
          }
        }
      }
    }

    return profiles
  }

  func parseProfileAccountInfo(profileName: String) -> ProfileAccountInfo? {
    guard let chromeDataDir = getChromeDataDirectory() else {
      return nil
    }

    let preferencesPath =
      chromeDataDir
      .appendingPathComponent(profileName)
      .appendingPathComponent("Preferences")

    guard let data = try? Data(contentsOf: preferencesPath),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accountInfoArray = json["account_info"] as? [[String: Any]],
      let firstAccount = accountInfoArray.first,
      let email = firstAccount["email"] as? String,
      let pictureUrl = firstAccount["picture_url"] as? String,
      !email.isEmpty,
      !pictureUrl.isEmpty
    else {
      return nil
    }

    return ProfileAccountInfo(email: email, pictureUrl: pictureUrl)
  }

  private func hasNewTabPage(profileName: String) -> Bool {
    guard let chromeDataDir = getChromeDataDirectory() else {
      return false
    }

    let preferencesPath =
      chromeDataDir
      .appendingPathComponent(profileName)
      .appendingPathComponent("Preferences")

    guard let data = try? Data(contentsOf: preferencesPath),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return false
    }

    return json["NewTabPage"] != nil
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
