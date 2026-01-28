import Foundation

class GoogleAuthService {

  func fetchMasterToken(
    email: String,
    oauthToken: String
  ) async throws -> String {
    var request = URLRequest(url: URL(string: "https://android.clients.google.com/auth")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
      "Accept-Encoding": "identity",
      "Content-type": "application/x-www-form-urlencoded",
      "User-Agent": "GoogleAuth/1.4",
    ]
    request.httpBody = [
      "accountType": "HOSTED_OR_GOOGLE",
      "Email": email,
      "has_permission": 1,
      "add_account": 1,
      "ACCESS_TOKEN": 1,
      "Token": oauthToken,
      "service": "ac2dm",
      "source": "android",
      "androidId": "0123456789abcdef",
      "device_country": "us",
      "operatorCountry": "us",
      "lang": "en",
      "sdk_version": 17,
      "google_play_services_version": 240_913_000,
      "client_sig": "38918a453d07199354f8b19af05ec6562ced5788",
      "callerSig": "38918a453d07199354f8b19af05ec6562ced5788",
      "droidguard_results": "dummy123",
    ].map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard let responseText = String(data: data, encoding: .utf8) else {
      throw NSError(
        domain: "GoogleAuthService", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = self.parseResponse(responseText)

    if let masterToken = responseDict["Token"] {
      return masterToken
    } else {
      throw NSError(
        domain: "GoogleAuthService", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to get master token: \(responseDict["Error"] ?? "Unknown error")"
        ])
    }
  }

  func fetchAccessToken(
    email: String,
    masterToken: String
  ) async throws -> (String, Date) {
    var request = URLRequest(url: URL(string: "https://android.clients.google.com/auth")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
      "Accept-Encoding": "identity",
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent": "GoogleAuth/1.4",
    ]
    request.httpBody = [
      "accountType": "HOSTED_OR_GOOGLE",
      "Email": email,
      "has_permission": 1,
      "EncryptedPasswd": masterToken,
      "service":
        "oauth2:https://www.googleapis.com/auth/memento "
        + "https://www.googleapis.com/auth/reminders "
        + "https://www.googleapis.com/auth/userinfo.profile",
      "source": "android",
      "androidId": "0123456789abcdef",
      "app": "com.google.android.keep",
      "device_country": "us",
      "operatorCountry": "us",
      "lang": "en",
      "sdk_version": 17,
      "google_play_services_version": 240_913_000,
      "client_sig": "38918a453d07199354f8b19af05ec6562ced5788",
    ].map { key, value in
      let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      return "\(encodedKey)=\(encodedValue)"
    }.joined(separator: "&").data(using: .utf8)

    let (data, _) = try await URLSession.shared.data(for: request)

    guard let responseText = String(data: data, encoding: .utf8) else {
      throw NSError(
        domain: "GoogleAuthService", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = self.parseResponse(responseText)

    if let authToken = responseDict["Auth"] {
      var expiry: Date = Date(timeIntervalSince1970: 0)
      if let expiresIn = responseDict["ExpiresInDurationSec"], let seconds = Double(expiresIn) {
        expiry = Date().addingTimeInterval(seconds)
      } else if let expiryEpoch = responseDict["Expiry"], let epoch = Double(expiryEpoch) {
        expiry = Date(timeIntervalSince1970: epoch)
      }

      return (authToken, expiry)
    } else {
      throw NSError(
        domain: "GoogleAuthService", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to get access token: \(responseDict["Error"] ?? "Unknown error")"
        ])
    }
  }

  private func parseResponse(_ responseText: String) -> [String: String] {
    return responseText.split(separator: "\n").reduce(into: [String: String]()) { result, line in
      let parts = line.split(separator: "=", maxSplits: 1)
      if parts.count == 2 {
        result[String(parts[0])] = String(parts[1])
      }
    }
  }
}
