import Combine
import Foundation

@MainActor
class ChromeProfileService: ObservableObject {
  private var chromeProcess: Process?

  func startAdd() async throws {
    guard
      let chromePath = Bundle.main.path(
        forResource: "Google Chrome for Testing",
        ofType: nil,
        inDirectory: "Google Chrome for Testing.app/Contents/MacOS"
      )
    else {
      throw ChromeProfileError.chromeNotFound
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [
      "-a", chromePath,
      "--args",
      "--profile-directory=Guest Profile",
    ]

    try process.run()
    chromeProcess = process

    // TODO: detect profile added and then terminate process
  }
}

enum ChromeProfileError: LocalizedError {
  case chromeNotFound

  var errorDescription: String? {
    switch self {
    case .chromeNotFound:
      return "Chrome for Testing not found"
    }
  }
}
