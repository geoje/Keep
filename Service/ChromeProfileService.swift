import Combine
import Foundation

@MainActor
class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []
  var onAddSuccess: (([Account]) -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startAdd() async throws {
    guard let chromePath = chromeDriverService.getChromePath() else {
      throw ChromeProfileError.chromeNotFound
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments =
      ["-a", chromePath, "--args"]
      + chromeDriverService.buildChromeArgs(
        headless: false, profileDirectory: "Guest Profile")

    try process.run()

    startMonitoring()
  }

  func loadChromeProfiles() -> [Account] {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir() else {
      return []
    }

    return getCurrentProfiles().compactMap { profileName in
      parseProfileAccount(chromeDataDir: chromeDataDir, profileName: profileName)
    }
  }

  private func startMonitoring() {
    monitorTask?.cancel()
    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      self.initialProfiles = self.getCurrentProfiles()

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        let currentProfiles = self.getCurrentProfiles()
        let newProfiles = currentProfiles.subtracting(self.initialProfiles)
        if !newProfiles.isEmpty {
          for profileName in currentProfiles {
            if self.hasNewTabPage(profileName: profileName) {
              self.stopMonitoring()
              self.onAddSuccess?(self.loadChromeProfiles())
              self.chromeDriverService.killAllChromeProcesses()
              return
            }
          }
        }
      }
    }
  }

  private func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  private func getCurrentProfiles() -> Set<String> {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir() else {
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

  private func parseProfileAccount(chromeDataDir: URL, profileName: String) -> Account? {
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

    return Account(email: email, picture: pictureUrl)
  }

  private func hasNewTabPage(profileName: String) -> Bool {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir() else {
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
