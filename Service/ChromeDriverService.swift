import Combine
import Foundation

class ChromeDriverService: ObservableObject {
  // MARK: - Properties

  private let driverPort = 9515
  private var chromedriverProcess: Process?
  private var cachedChromeVersion: String?

  // MARK: - Public API

  func launchChrome(url: String = "", headless: Bool = false, profileDirectory: String = "Default")
    async throws -> String
  {
    try await startChromeDriver()

    let sessionId = try await createChromeSession(
      headless: headless, profileDirectory: profileDirectory)

    if !url.isEmpty {
      try await navigateToURL(sessionId: sessionId, url: url)
    }

    return sessionId
  }

  // MARK: - Session Management

  func deleteSession(_ sessionId: String) async {
    try? await sendRequest(path: "/session/\(sessionId)", method: "DELETE")
  }

  func navigateToURL(sessionId: String, url: String) async throws {
    try await sendRequest(path: "/session/\(sessionId)/url", method: "POST", body: ["url": url])
  }

  func getPageSource(sessionId: String) async throws -> String {
    let response: [String: Any] = try await sendRequest(
      path: "/session/\(sessionId)/source", method: "GET")

    guard let value = response["value"] as? String else {
      throw ChromeDriverError.sessionCreationFailed
    }

    return value
  }

  // MARK: - Getters

  func getChromePath() throws -> String {
    guard
      let path = Bundle.main.path(
        forResource: "Google Chrome for Testing",
        ofType: nil,
        inDirectory: "Google Chrome for Testing.app/Contents/MacOS"
      )
    else {
      throw ChromeDriverError.chromeNotFound
    }
    return path
  }

  func getChromeDataDir() -> URL? {
    guard
      let appSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      ).first,
      let bundleIdentifier = Bundle.main.bundleIdentifier
    else {
      return nil
    }

    let chromeDataDir =
      appSupportURL
      .appendingPathComponent(bundleIdentifier)
      .appendingPathComponent("Chrome")

    try? FileManager.default.createDirectory(
      at: chromeDataDir,
      withIntermediateDirectories: true
    )

    return chromeDataDir
  }

  // MARK: - Chrome Driver Lifecycle

  func startChromeDriver() async throws {
    guard let chromedriverPath = Bundle.main.path(forResource: "chromedriver", ofType: nil)
    else {
      throw ChromeDriverError.chromedriverNotFound
    }

    if chromedriverProcess == nil || chromedriverProcess?.isRunning != true {
      if !(await checkPortInUse()) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: chromedriverPath)
        process.arguments = ["--port=\(driverPort)"]

        try process.run()
        chromedriverProcess = process

        for _ in 0..<50 {
          if await checkPortInUse() {
            break
          }
          try await Task.sleep(for: .milliseconds(100))
        }
      }
    }
  }

  private func checkPortInUse() async -> Bool {
    do {
      let _: [String: Any] = try await sendRequest(
        path: "/status",
        method: "GET"
      )
      return true
    } catch {
      return false
    }
  }

  // MARK: - Session Helpers

  private func createChromeSession(
    headless: Bool, profileDirectory: String = "Default"
  ) async throws -> String {
    let chromePath = try getChromePath()
    let chromeArgs = buildChromeArgs(headless: headless, profileDirectory: profileDirectory)
    let body: [String: Any] = [
      "capabilities": [
        "alwaysMatch": [
          "goog:chromeOptions": [
            "binary": chromePath,
            "args": chromeArgs,
            "excludeSwitches": ["enable-automation"],
          ]
        ]
      ]
    ]

    let response: [String: Any] = try await sendRequest(
      path: "/session",
      method: "POST",
      body: body
    )

    guard let value = response["value"] as? [String: Any],
      let sessionId = value["sessionId"] as? String
    else {
      throw ChromeDriverError.sessionCreationFailed
    }

    return sessionId
  }

  private func buildChromeArgs(headless: Bool, profileDirectory: String = "Default") -> [String] {
    var chromeArgs = [
      "--disable-blink-features=AutomationControlled",
      "--no-default-browser-check",
      "--disable-infobars",
      "--no-first-run",
      "--test-type",
    ]

    if headless {
      chromeArgs.append("--headless=new")
      if let version = getChromeVersion() {
        chromeArgs.append("--user-agent=Chrome/\(version)")
      }
    }

    if let chromeDataDir = getChromeDataDir() {
      chromeArgs.append("--user-data-dir=\(chromeDataDir.path)")
      chromeArgs.append("--profile-directory=\(profileDirectory)")
    }

    return chromeArgs
  }

  private func getChromeVersion() -> String? {
    if let cached = cachedChromeVersion {
      return cached
    }

    guard let chromePath = try? getChromePath() else {
      return nil
    }

    let chromeAppPath =
      ((chromePath as NSString).deletingLastPathComponent as NSString)
      .deletingLastPathComponent as NSString
    let chromeAppBundlePath = chromeAppPath.deletingLastPathComponent
    let infoPlistPath = (chromeAppBundlePath as NSString).appendingPathComponent(
      "Contents/Info.plist")

    guard let plistData = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
      let plist = try? PropertyListSerialization.propertyList(
        from: plistData, options: [], format: nil) as? [String: Any],
      let version = plist["CFBundleShortVersionString"] as? String
    else {
      return nil
    }

    let components = version.split(separator: ".")
    if components.count >= 1 {
      let result = "\(components[0]).0.0.0"
      cachedChromeVersion = result
      return result
    }

    return nil
  }

  // MARK: - HTTP Request Helper

  @discardableResult
  private func sendRequest(
    path: String,
    method: String,
    body: [String: Any]? = nil
  ) async throws -> [String: Any] {
    let url = URL(string: "http://localhost:\(driverPort)\(path)")!
    var request = URLRequest(url: url)
    request.httpMethod = method

    if let body = body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }

    let (data, _) = try await URLSession.shared.data(for: request)
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }
    return json
  }

  private func getAllSessions() async -> [String] {
    guard
      let response: [String: Any] = try? await sendRequest(
        path: "/sessions",
        method: "GET"
      ),
      let value = response["value"] as? [[String: Any]]
    else {
      return []
    }

    return value.compactMap { $0["id"] as? String }
  }

  private func deleteAllSessions() async {
    let sessions = await getAllSessions()
    for sessionId in sessions {
      await deleteSession(sessionId)
    }
  }

  // MARK: - Cleanup

  func cleanup() async {
    await deleteAllSessions()
    stopChromeDriver()
    killAllChromedrivers()
    killAllChromeProcesses()
  }

  private func stopChromeDriver() {
    if let process = chromedriverProcess, process.isRunning {
      process.terminate()
      chromedriverProcess = nil
    }
  }

  private func killAllChromedrivers() {
    killProcess("chromedriver")
  }

  private func killAllChromeProcesses() {
    killProcess("Google Chrome for Testing")
  }

  private func killProcess(_ name: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    process.arguments = ["-9", name]
    try? process.run()
    process.waitUntilExit()
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
