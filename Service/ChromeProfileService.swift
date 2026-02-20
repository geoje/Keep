import Combine
import Foundation
import SwiftData

@MainActor
class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []
  var onAddSuccess: ((Account) -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startAdd() async throws {
    try await chromeDriverService.launchChrome(
      url: "https://accounts.google.com/AddSession", headless: false)
    startMonitoring()
  }

  private func startMonitoring() {
    monitorTask?.cancel()
    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      guard let chromeDataDir = self.chromeDriverService.getChromeDataDir() else {
        return
      }

      let allProfiles = self.getCurrentProfiles()
      self.initialProfiles = Set(
        allProfiles.filter { profileName in
          self.parseProfileAccount(chromeDataDir: chromeDataDir, profileName: profileName) != nil
        })

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        guard let sessionId = self.chromeDriverService.getSessionId(),
          await self.isSessionAlive(sessionId: sessionId)
        else {
          self.stopMonitoring()
          await self.chromeDriverService.cleanup()
          return
        }

        let currentProfiles = self.getCurrentProfiles()
        let newProfiles = currentProfiles.subtracting(self.initialProfiles)

        for profileName in newProfiles where self.isExplicitSignIn(profileName: profileName) {
          if let newProfile = self.parseProfileAccount(
            chromeDataDir: chromeDataDir, profileName: profileName)
          {
            self.stopMonitoring()
            self.onAddSuccess?(newProfile)
            await self.chromeDriverService.cleanup()
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

  private func isExplicitSignIn(profileName: String) -> Bool {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir(),
      let data = try? Data(
        contentsOf: chromeDataDir.appendingPathComponent(profileName).appendingPathComponent(
          "Preferences")),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let signin = json["signin"] as? [String: Any],
      let explicitBrowserSignin = signin["explicit_browser_signin"] as? Bool,
      let signinWithExplicitBrowserSigninOn = signin["signin_with_explicit_browser_signin_on"]
        as? Bool
    else {
      return false
    }
    return explicitBrowserSignin && signinWithExplicitBrowserSigninOn
  }

  func loadChromeProfiles() -> [Account] {
    guard let chromeDataDir = chromeDriverService.getChromeDataDir() else {
      return []
    }

    return getCurrentProfiles().compactMap { profileName in
      parseProfileAccount(chromeDataDir: chromeDataDir, profileName: profileName)
    }
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
    try await chromeDriverService.launchChrome(
      url: "https://keep.google.com",
      headless: true,
      profileDirectory: account.profileName
    )
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

  private func isSessionAlive(sessionId: String) async -> Bool {
    let url = URL(string: "http://localhost:9515/session/\(sessionId)/title")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else { return false }
      return httpResponse.statusCode == 200
    } catch {
      return false
    }
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
