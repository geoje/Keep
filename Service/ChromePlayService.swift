import Combine
import Foundation

@MainActor
class ChromePlayService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?
  var onLoginSuccess: ((String, String) -> Void)?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startLogin() async throws {
    try await chromeDriverService.launchChrome(url: "https://accounts.google.com/EmbeddedSetup")
    startMonitoring()
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

        guard let cookies = await self.getCookies(sessionId: sessionId) else {
          self.stopMonitoring()
          await self.chromeDriverService.cleanup()
          return
        }

        for cookie in cookies {
          if let name = cookie["name"] as? String,
            name == "oauth_token",
            let oauthToken = cookie["value"] as? String
          {
            guard let email = await self.extractEmail(sessionId: sessionId) else {
              self.stopMonitoring()
              await self.chromeDriverService.cleanup()
              return
            }
            self.stopMonitoring()
            await self.chromeDriverService.cleanup()
            self.onLoginSuccess?(email, oauthToken)
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

  private func extractEmail(sessionId: String) async -> String? {
    let script = """
      const emailElement = document.querySelector('[data-email]');
      return emailElement ? emailElement.getAttribute('data-email') : null;
      """
    return await executeScript(sessionId: sessionId, script: script)
  }

  private func executeScript(sessionId: String, script: String) async -> String? {
    let url = URL(string: "http://localhost:9515/session/\(sessionId)/execute/sync")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "script": script,
      "args": [],
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else { return nil }

      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let value = json["value"] as? String,
        !value.isEmpty
      {
        return value
      }
    } catch {
      return nil
    }
    return nil
  }
}
