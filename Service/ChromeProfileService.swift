import Combine
import Foundation

@MainActor
class ChromeProfileService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  private var initialEmails: Set<String> = []
  var onAddSuccess: (([Account]) -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startAdd() async throws {
    try await chromeDriverService.launchChrome(
      url: "https://accounts.google.com/AddSession?authuser=0")

    guard let profileDir = chromeDriverService.getChromeDataDir()?.appendingPathComponent("Default")
    else {
      throw ChromeProfileError.profileDirectoryNotFound
    }

    initialEmails = getAccountEmails(from: profileDir)

    startMonitoring(profileDir: profileDir)
  }

  func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  func loadChromeProfiles() -> [Account] {
    guard let profileDir = chromeDriverService.getChromeDataDir()?.appendingPathComponent("Default")
    else {
      return []
    }

    let preferencesPath = profileDir.appendingPathComponent("Preferences")

    guard let data = try? Data(contentsOf: preferencesPath),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accountInfo = json["account_info"] as? [[String: Any]]
    else {
      return []
    }

    return accountInfo.compactMap { account in
      guard let email = account["email"] as? String,
        let picture = account["picture_url"] as? String,
        !picture.isEmpty
      else {
        return nil
      }

      return Account(email: email, picture: picture)
    }
  }

  private func startMonitoring(profileDir: URL) {
    monitorTask?.cancel()
    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      print("[ChromeProfileService] Monitoring started")
      print("[ChromeProfileService] Initial accounts: \(self.initialEmails)")

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        guard let sessionId = self.chromeDriverService.getSessionId() else {
          print("[ChromeProfileService] Session ID lost")
          self.stopMonitoring()
          return
        }

        guard await self.checkSessionAlive(sessionId: sessionId) else {
          print("[ChromeProfileService] Session closed, cleaning up...")
          self.stopMonitoring()
          await self.chromeDriverService.cleanup()
          return
        }

        let currentEmails = self.getAccountEmails(from: profileDir)
        let newEmails = currentEmails.subtracting(self.initialEmails)

        print("[ChromeProfileService] Current accounts: \(currentEmails)")
        print("[ChromeProfileService] New accounts detected: \(newEmails)")

        if !newEmails.isEmpty {
          let newAccountsWithPicture = self.getAccountsWithPicture(
            from: profileDir, emails: newEmails)

          if !newAccountsWithPicture.isEmpty {
            print("[ChromeProfileService] New account with picture found! Stopping monitoring...")
            self.stopMonitoring()
            await self.chromeDriverService.cleanup()
            let profiles = self.loadChromeProfiles()
            print("[ChromeProfileService] Loaded profiles: \(profiles.map { $0.email })")
            self.onAddSuccess?(profiles)
            return
          } else {
            print("[ChromeProfileService] New account found but waiting for profile picture...")
          }
        }
      }
    }
  }

  private func getAccountsWithPicture(from profileDir: URL, emails: Set<String>) -> Set<String> {
    let preferencesPath = profileDir.appendingPathComponent("Preferences")

    guard let data = try? Data(contentsOf: preferencesPath),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accountInfo = json["account_info"] as? [[String: Any]]
    else {
      return []
    }

    let emailsWithPicture = accountInfo.compactMap { account -> String? in
      guard let email = account["email"] as? String,
        emails.contains(email),
        let pictureURL = account["picture_url"] as? String,
        !pictureURL.isEmpty
      else {
        return nil
      }
      return email
    }

    return Set(emailsWithPicture)
  }

  private func checkSessionAlive(sessionId: String) async -> Bool {
    let url = URL(string: "http://localhost:9515/session/\(sessionId)/title")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else { return false }
      return true
    } catch {
      return false
    }
  }

  private func getAccountEmails(from profileDir: URL) -> Set<String> {
    let preferencesPath = profileDir.appendingPathComponent("Preferences")

    guard let data = try? Data(contentsOf: preferencesPath),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let accountInfo = json["account_info"] as? [[String: Any]]
    else {
      return []
    }

    let emails = accountInfo.compactMap { account in
      account["email"] as? String
    }

    return Set(emails)
  }
}

enum ChromeProfileError: LocalizedError {
  case profileDirectoryNotFound

  var errorDescription: String? {
    switch self {
    case .profileDirectoryNotFound:
      return "Chrome profile directory not found"
    }
  }
}
