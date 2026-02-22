import Combine
import Foundation
import SwiftData

class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialProfiles: Set<String> = []
  private var currentSessionId: String?
  var onAddSuccess: ((Account) -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startAdd() async throws {
    await chromeDriverService.deleteAllSessions()
    let sessionId = try await chromeDriverService.launchChrome(
      url: "https://support.google.com/chrome/answer/2364824")
    currentSessionId = sessionId
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

        guard let sessionId = self.currentSessionId,
          await self.isSessionAlive(sessionId: sessionId)
        else {
          self.stopMonitoring()
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
            return
          }
        }
      }
    }
  }

  private func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
    currentSessionId = nil
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
      let email = firstAccount["email"] as? String, !email.isEmpty
    else {
      return nil
    }

    return Account(email: email, profileName: profileName)
  }

  func syncMultipleAccounts(_ accounts: [Account], modelContext: ModelContext) async -> [String:
    Error]
  {
    var errors: [String: Error] = [:]
    var sessionIds: [String] = []

    guard !accounts.isEmpty else { return errors }

    do {
      try await chromeDriverService.startChromeDriver()

      for account in accounts {
        do {
          let sessionId = try await chromeDriverService.launchChrome(
            url: "https://keep.google.com",
            headless: true,
            profileDirectory: account.profileName
          )
          sessionIds.append(sessionId)

          try await syncNotesForSession(
            sessionId: sessionId, account: account, modelContext: modelContext)
        } catch {
          errors[account.email] = error
        }
      }
    } catch {
      for account in accounts {
        errors[account.email] = error
      }
    }

    await chromeDriverService.cleanup()

    return errors
  }

  private func syncNotesForSession(sessionId: String, account: Account, modelContext: ModelContext)
    async throws
  {
    let html = try await chromeDriverService.getPageSource(sessionId: sessionId)

    guard let jsonString = extractLoadChunkJSON(from: html),
      let jsonData = unescapeJSONString(jsonString).data(using: .utf8),
      let rootNoteDicts = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
    else {
      throw ChromeProfileError.noteParsingFailed
    }

    let accountEmail = account.email
    let existingNotes = try modelContext.fetch(
      FetchDescriptor<Note>(predicate: #Predicate { $0.email == accountEmail })
    )
    existingNotes.forEach { modelContext.delete($0) }

    for rootNoteDict in rootNoteDicts {
      let rootNote = try Note.from(dict: rootNoteDict, email: accountEmail)
      modelContext.insert(rootNote)
    }

    try modelContext.save()
  }

  private func extractLoadChunkJSON(from html: String) -> String? {
    let pattern = #"loadChunk\(JSON\.parse\('([^']+)'\), \".*\"\)"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
      let range = Range(match.range(at: 1), in: html)
    else {
      return nil
    }

    let extracted = String(html[range])
    return extracted
  }

  private func unescapeJSONString(_ string: String) -> String {
    var result = string

    let hexPattern = #"\\x([0-9a-fA-F]{2})"#
    if let hexRegex = try? NSRegularExpression(pattern: hexPattern) {
      let matches = hexRegex.matches(in: result, range: NSRange(result.startIndex..., in: result))
      for match in matches.reversed() {
        guard let range = Range(match.range, in: result),
          let hexRange = Range(match.range(at: 1), in: result),
          let value = UInt8(result[hexRange], radix: 16)
        else { continue }

        let char = String(UnicodeScalar(value))
        result.replaceSubrange(range, with: char)
      }
    }
    result = result.replacingOccurrences(of: "\\\\", with: "\\")

    return result
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
  case noteParsingFailed

  var errorDescription: String? {
    switch self {
    case .chromeNotFound:
      return "Chrome for Testing not found"
    case .dataDirectoryNotFound:
      return "Could not create Chrome data directory"
    case .noteParsingFailed:
      return "Failed to parse notes from Keep page"
    }
  }
}
