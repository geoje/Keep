import Combine
import Foundation
import SwiftData

@MainActor
class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []
  var onAddProfile: ((Account) -> Void)?

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
      guard let chromeDataDir = self.chromeDriverService.getChromeDataDir() else { return }

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        guard self.isChromeGuestProfileRunning() else {
          self.stopMonitoring()
          self.chromeDriverService.killAllChromeProcesses()
          return
        }

        let currentProfiles = self.getCurrentProfiles()

        let newProfiles = currentProfiles.subtracting(self.initialProfiles)
        for profileName in newProfiles where self.hasNewTabPage(profileName: profileName) {
          if let newProfile = self.parseProfileAccount(
            chromeDataDir: chromeDataDir, profileName: profileName)
          {
            self.stopMonitoring()
            self.onAddProfile?(newProfile)
            self.chromeDriverService.killAllChromeProcesses()
            return
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
    guard let chromeDataDir = chromeDriverService.getChromeDataDir(),
      let contents = try? FileManager.default.contentsOfDirectory(
        at: chromeDataDir,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return []
    }

    return Set(
      contents.compactMap { url in
        guard (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else {
          return nil
        }
        let name = url.lastPathComponent
        guard name == "Default" || name.starts(with: "Profile "),
          FileManager.default.fileExists(
            atPath: url.appendingPathComponent("Preferences").path)
        else {
          return nil
        }
        return name
      })
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

    return Account(email: email, picture: pictureUrl, profileName: profileName)
  }

  func syncNotes(for account: Account, modelContext: ModelContext) async throws {

  }

  func deleteProfile(profileName: String) throws {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir() else {
      throw ChromeProfileError.dataDirectoryNotFound
    }

    let localStatePath = chromeDataDir.appendingPathComponent("Local State")
    let profilePath = chromeDataDir.appendingPathComponent(profileName)

    if FileManager.default.fileExists(atPath: localStatePath.path) {
      let data = try Data(contentsOf: localStatePath)
      var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

      if var profile = json["profile"] as? [String: Any],
        var infoCache = profile["info_cache"] as? [String: Any]
      {
        infoCache.removeValue(forKey: profileName)
        profile["info_cache"] = infoCache
        json["profile"] = profile

        let updatedData = try JSONSerialization.data(
          withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try updatedData.write(to: localStatePath)
      }
    }

    if FileManager.default.fileExists(atPath: profilePath.path) {
      try FileManager.default.removeItem(at: profilePath)
    }
  }

  private func hasNewTabPage(profileName: String) -> Bool {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir(),
      let data = try? Data(
        contentsOf: chromeDataDir.appendingPathComponent(profileName).appendingPathComponent(
          "Preferences")),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return false
    }
    return json["NewTabPage"] != nil
  }

  nonisolated private func isChromeGuestProfileRunning() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-f", "Guest Profile"]
    process.standardOutput = Pipe()

    guard (try? process.run()) != nil else { return false }
    process.waitUntilExit()

    guard let data = (process.standardOutput as? Pipe)?.fileHandleForReading.readDataToEndOfFile(),
      let output = String(data: data, encoding: .utf8)
    else {
      return false
    }
    return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
