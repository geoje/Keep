import Combine
import Foundation

@MainActor
class ChromeDriverService: ObservableObject {
  @Published var isRunning = false

  private var chromedriverProcess: Process?
  private var chromeSessionId: String?

  private let driverPort = 9515

  func launchChrome(url: String) async throws {
    guard let chromedriverPath = Bundle.main.path(forResource: "chromedriver", ofType: nil)
    else {
      throw ChromeDriverError.chromedriverNotFound
    }

    guard
      let chromePath = Bundle.main.path(
        forResource: "Google Chrome for Testing",
        ofType: nil,
        inDirectory: "Google Chrome for Testing.app/Contents/MacOS"
      )
    else {
      throw ChromeDriverError.chromeNotFound
    }

    if chromedriverProcess == nil || chromedriverProcess?.isRunning != true {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: chromedriverPath)
      process.arguments = ["--port=\(driverPort)"]

      try process.run()
      chromedriverProcess = process

      for _ in 0..<50 {
        let statusURL = URL(string: "http://localhost:\(driverPort)/status")!
        if let (_, response) = try? await URLSession.shared.data(from: statusURL),
          let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
        {
          break
        }
        try await Task.sleep(for: .milliseconds(100))
      }
    }

    isRunning = true

    await deleteAllSessions()
    chromeSessionId = nil

    let sessionId = try await createChromeSession(chromePath: chromePath)
    chromeSessionId = sessionId

    try await navigateToURL(sessionId: sessionId, url: url)
  }

  func cleanup() async {
    await closeChromeSession()
    stopChromeDriver()
    isRunning = false
  }

  func getSessionId() -> String? {
    return chromeSessionId
  }

  private func createChromeSession(chromePath: String) async throws -> String {
    let url = URL(string: "http://localhost:\(driverPort)/session")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "capabilities": [
        "alwaysMatch": [
          "goog:chromeOptions": [
            "binary": chromePath,
            "args": [
              "--disable-blink-features=AutomationControlled",
              "--no-first-run",
              "--no-default-browser-check",
              "--disable-infobars",
              "--test-type",
            ],
            "excludeSwitches": ["enable-automation"],
          ]
        ]
      ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, _) = try await URLSession.shared.data(for: request)

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let value = json["value"] as? [String: Any],
      let sessionId = value["sessionId"] as? String
    else {
      throw ChromeDriverError.sessionCreationFailed
    }

    return sessionId
  }

  private func navigateToURL(sessionId: String, url: String) async throws {
    let navURL = URL(string: "http://localhost:\(driverPort)/session/\(sessionId)/url")!
    var request = URLRequest(url: navURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["url": url]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    _ = try await URLSession.shared.data(for: request)
  }

  private func getAllSessions() async -> [String] {
    let url = URL(string: "http://localhost:\(driverPort)/sessions")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    guard let (data, _) = try? await URLSession.shared.data(for: request),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let value = json["value"] as? [[String: Any]]
    else {
      return []
    }

    return value.compactMap { $0["id"] as? String }
  }

  private func deleteAllSessions() async {
    let sessions = await getAllSessions()
    for sessionId in sessions {
      let url = URL(string: "http://localhost:\(driverPort)/session/\(sessionId)")!
      var request = URLRequest(url: url)
      request.httpMethod = "DELETE"
      _ = try? await URLSession.shared.data(for: request)
    }
  }

  private func closeChromeSession() async {
    if let sessionId = chromeSessionId {
      let url = URL(string: "http://localhost:\(driverPort)/session/\(sessionId)")!
      var request = URLRequest(url: url)
      request.httpMethod = "DELETE"
      _ = try? await URLSession.shared.data(for: request)
    }
    chromeSessionId = nil
  }

  private func stopChromeDriver() {
    chromedriverProcess?.terminate()
    chromedriverProcess = nil
  }
}

enum ChromeDriverError: LocalizedError {
  case chromedriverNotFound
  case chromeNotFound
  case sessionCreationFailed

  var errorDescription: String? {
    switch self {
    case .chromedriverNotFound:
      return "ChromeDriver not found"
    case .chromeNotFound:
      return "Chrome browser not found"
    case .sessionCreationFailed:
      return "Failed to create Chrome session"
    }
  }
}
