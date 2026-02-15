import Combine
import Foundation

@MainActor
class ChromeDirectLoginService: ObservableObject {
  private let chromeDriverService: ChromeDriverService
  private var monitorTask: Task<Void, Never>?

  init(chromeDriverService: ChromeDriverService) {
    self.chromeDriverService = chromeDriverService
  }

  func startLogin() async {
    do {
      try await chromeDriverService.launchChrome(
        url: "https://accounts.google.com/ServiceLogin?continue=https://myaccount.google.com")
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

        if let sessionId = self.chromeDriverService.getSessionId(),
          let currentURL = await self.getCurrentURL(sessionId: sessionId),
          currentURL.contains("myaccount.google.com")
        {

          // Extract image URL
          if let imageURL = await self.extractImageURL(sessionId: sessionId) {
            print("Image URL: \(imageURL)")
          }

          // Extract email
          if let email = await self.extractEmail(sessionId: sessionId) {
            print("Email: \(email)")
          }

          // Cleanup and stop monitoring
          self.stopMonitoring()
          self.chromeDriverService.cleanup()
          return
        }
      }
    }
  }

  private func getCurrentURL(sessionId: String) async -> String? {
    let url = URL(string: "http://localhost:9515/session/\(sessionId)/url")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else { return nil }

      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let value = json["value"] as? String
      {
        return value
      }
    } catch {
      return nil
    }
    return nil
  }

  private func extractImageURL(sessionId: String) async -> String? {
    let script = """
      const imageElement = document.querySelector('image');
      return imageElement ? imageElement.getAttributeNS('http://www.w3.org/1999/xlink', 'href') : null;
      """
    return await executeScript(sessionId: sessionId, script: script)
  }

  private func extractEmail(sessionId: String) async -> String? {
    let script = """
      const emailElement = document.querySelector('.fwyMNe');
      return emailElement ? emailElement.textContent : null;
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
