import Combine
import Foundation

@MainActor
class ChromeDriverService: ObservableObject {
  @Published var isRunning = false

  private var chromedriverProcess: Process?
  private var chromeSessionId: String?
  private var sessionMonitorTask: Task<Void, Never>?

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

    // Start ChromeDriver process if not already running
    if chromedriverProcess == nil || chromedriverProcess?.isRunning != true {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: chromedriverPath)
      process.arguments = ["--port=\(driverPort)"]

      try process.run()
      chromedriverProcess = process

      // Wait for ChromeDriver to be ready by polling status endpoint
      for _ in 0..<50 {  // Maximum 5 seconds (50 * 100ms)
        let statusURL = URL(string: "http://localhost:\(driverPort)/status")!
        if let (_, response) = try? await URLSession.shared.data(from: statusURL),
          let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
        {
          break  // ChromeDriver is ready
        }
        try await Task.sleep(for: .milliseconds(100))
      }
    }

    isRunning = true

    // Create Chrome session if not already exists
    if chromeSessionId == nil {
      let sessionId = try await createChromeSession(chromePath: chromePath)
      chromeSessionId = sessionId
      startSessionMonitoring()
    }

    // Navigate to URL using existing or newly created session
    if let sessionId = chromeSessionId {
      try await navigateToURL(sessionId: sessionId, url: url)
    }
  }

  func cleanup() {
    stopSessionMonitoring()
    closeChromeSession()
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

  private func startSessionMonitoring() {
    stopSessionMonitoring()

    sessionMonitorTask = Task { [weak self] in
      guard let self = self else { return }

      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))

        guard let sessionId = self.chromeSessionId else {
          print("Session ID lost - cleaning up")
          self.cleanup()
          return
        }

        let isValid = await self.checkSessionValidity(sessionId: sessionId)
        if !isValid {
          print("Session invalid (window closed or Chrome crashed) - cleaning up")
          self.cleanup()
          return
        }
      }
    }
  }

  private func stopSessionMonitoring() {
    sessionMonitorTask?.cancel()
    sessionMonitorTask = nil
  }

  private func checkSessionValidity(sessionId: String) async -> Bool {
    let url = URL(string: "http://localhost:\(driverPort)/sessions")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      print("Sessions check response: \(response)")

      guard let httpResponse = response as? HTTPURLResponse else {
        print("Failed to cast to HTTPURLResponse")
        return false
      }

      print("Sessions check status code: \(httpResponse.statusCode)")

      if httpResponse.statusCode == 200 {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let value = json["value"] as? [[String: Any]]
        {
          print("Active sessions: \(value)")

          // Check if our session ID is in the active sessions list
          let hasSession = value.contains { session in
            if let id = session["id"] as? String {
              return id == sessionId
            }
            return false
          }

          print("Our session (\(sessionId)) is active: \(hasSession)")
          return hasSession
        }
      }

      return false
    } catch {
      print("Sessions check error: \(error)")
      return false
    }
  }

  private func closeChromeSession() {
    if let sessionId = chromeSessionId {
      let url = URL(string: "http://localhost:\(driverPort)/session/\(sessionId)")!
      var request = URLRequest(url: url)
      request.httpMethod = "DELETE"
      request.timeoutInterval = 2.0

      let semaphore = DispatchSemaphore(value: 0)
      URLSession.shared.dataTask(with: request) { _, _, _ in
        semaphore.signal()
      }.resume()
      _ = semaphore.wait(timeout: .now() + 2.0)
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
