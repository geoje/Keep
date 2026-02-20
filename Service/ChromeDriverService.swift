import Combine
import Foundation

@MainActor
class ChromeDriverService: ObservableObject {
  private let driverPort = 9515
  private var chromedriverProcess: Process?
  private var sessionId: String?
  private var cachedChromeVersion: String?

  func launchChrome(url: String, headless: Bool = false, profileDirectory: String = "Default")
    async throws
  {
    guard let chromedriverPath = Bundle.main.path(forResource: "chromedriver", ofType: nil)
    else {
      throw ChromeDriverError.chromedriverNotFound
    }

    guard let chromePath = getChromePath() else {
      throw ChromeDriverError.chromeNotFound
    }

    try await startChromeDriver(chromedriverPath: chromedriverPath)
    await deleteAllSessions()

    let sessionId = try await createChromeSession(
      chromePath: chromePath, headless: headless, profileDirectory: profileDirectory)
    self.sessionId = sessionId

    try await navigateToURL(sessionId: sessionId, url: url)
  }

  func getSessionId() -> String? {
    return sessionId
  }

  func getChromePath() -> String? {
    return Bundle.main.path(
      forResource: "Google Chrome for Testing",
      ofType: nil,
      inDirectory: "Google Chrome for Testing.app/Contents/MacOS"
    )
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

  private func startChromeDriver(chromedriverPath: String) async throws {
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

  private func createChromeSession(
    chromePath: String, headless: Bool, profileDirectory: String = "Default"
  ) async throws -> String {
    let url = URL(string: "http://localhost:\(driverPort)/session")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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

  func buildChromeArgs(headless: Bool, profileDirectory: String = "Default") -> [String] {
    var chromeArgs = [
      "--disable-blink-features=AutomationControlled",
      "--no-default-browser-check",
      "--disable-infobars",
      "--no-first-run",
      "--test-type",
    ]

    if headless {
      chromeArgs.append("--headless=new")
      chromeArgs.append("--remote-debugging-port=9222")
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

    guard let chromePath = getChromePath() else {
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

  private func navigateToURL(sessionId: String, url: String) async throws {
    let navURL = URL(string: "http://localhost:\(driverPort)/session/\(sessionId)/url")!
    var request = URLRequest(url: navURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = ["url": url]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    _ = try await URLSession.shared.data(for: request)
  }

  private func checkPortInUse() async -> Bool {
    let statusURL = URL(string: "http://localhost:\(driverPort)/status")!
    if let (_, response) = try? await URLSession.shared.data(from: statusURL),
      let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    {
      return true
    }
    return false
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
    sessionId = nil
  }

  func cleanup() async {
    await deleteAllSessions()
    stopChromeDriver()
    killAllChromeProcesses()
  }

  private func stopChromeDriver() {
    if let process = chromedriverProcess, process.isRunning {
      process.terminate()
      chromedriverProcess = nil
    } else {
      killAllChromedrivers()
    }
  }

  private func killAllChromedrivers() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    process.arguments = ["-9", "chromedriver"]
    try? process.run()
    process.waitUntilExit()
  }

  func killAllChromeProcesses() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    process.arguments = ["-9", "Google Chrome for Testing"]
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
