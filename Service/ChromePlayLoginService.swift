import Combine
import Foundation

@MainActor
class ChromePlayLoginService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startLogin() async {
    do {
      try await chromeDriverService.launchChrome(url: "https://accounts.google.com/EmbeddedSetup")
      startMonitoring()
    } catch {
      print("Failed to launch Chrome: \(error)")
    }
  }

  func stopMonitoring() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  private func startMonitoring() {
    monitorTask?.cancel()
    monitorTask = Task { [weak self] in
      guard let self = self else { return }

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        guard let sessionId = self.chromeDriverService.getSessionId() else {
          self.stopMonitoring()
          return
        }

        if let cookies = await self.getCookies(sessionId: sessionId) {
          for cookie in cookies {
            if let name = cookie["name"] as? String,
              name == "oauth_token",
              let value = cookie["value"] as? String
            {
              print("OAuth Token found: \(value)")

              self.stopMonitoring()
              await self.chromeDriverService.cleanup()
              return
            }
          }
        }
      }
    }
  }

  private func getCookies(sessionId: String) async -> [[String: Any]]? {
    let url = URL(string: "http://localhost:9515/session/\(sessionId)/cookie")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else { return nil }

      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let value = json["value"] as? [[String: Any]]
      {
        return value
      }
    } catch {
      return nil
    }
    return nil
  }
}
