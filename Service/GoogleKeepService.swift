import Foundation
import SwiftData

class GoogleKeepService {

  func getAccessToken(
    email: String,
    masterToken: String,
    completion: @escaping (Result<(String, Date), Error>) -> Void
  ) {
    print("🔐 Fetching access token for: \(email)")
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
        "oauth2:https://www.googleapis.com/auth/memento https://www.googleapis.com/auth/reminders",
      "source": "android",
      "androidId": "0123456789abcdef",
      "app": "com.google.android.keep",
      "client_sig": "38918a453d07199354f8b19af05ec6562ced5788",
      "device_country": "us",
      "operatorCountry": "us",
      "lang": "en",
      "sdk_version": 17,
      "google_play_services_version": 240_913_000,
    ].map { key, value in
      let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      return "\(encodedKey)=\(encodedValue)"
    }.joined(separator: "&").data(using: .utf8)

    print("📤 Request URL: \(request.url?.absoluteString ?? "")")
    print("📤 Request Method: \(request.httpMethod ?? "")")
    print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
    if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
      print("📤 Request Body: \(bodyString)")
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data, let responseText = String(data: data, encoding: .utf8) else {
        completion(
          .failure(
            NSError(
              domain: "GoogleKeepService", code: 0,
              userInfo: [NSLocalizedDescriptionKey: "No data received or failed to decode response"]
            )))
        return
      }
      let responseDict = self.parseResponse(responseText)

      if let authToken = responseDict["Auth"] {
        var expiry: Date = Date(timeIntervalSince1970: 0)
        if let expiresIn = responseDict["ExpiresInDurationSec"], let seconds = Double(expiresIn) {
          expiry = Date().addingTimeInterval(seconds)
        } else if let expiryEpoch = responseDict["Expiry"], let epoch = Double(expiryEpoch) {
          expiry = Date(timeIntervalSince1970: epoch)
        }

        print("✅ Access token received: \(authToken.prefix(20))...")
        print("⏰ Expiry: \(expiry)")
        completion(.success((authToken, expiry)))
      } else {
        let errorDetail = responseDict["Error"] ?? "Unknown error"
        print("❌ Failed to get OAuth token: \(errorDetail)")
        let error = NSError(
          domain: "GoogleKeepService", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to get OAuth token: \(errorDetail)"])
        completion(.failure(error))
      }
    }.resume()
  }

  private func parseResponse(_ responseText: String) -> [String: String] {
    return responseText.split(separator: "\n").reduce(into: [String: String]()) { result, line in
      let parts = line.split(separator: "=", maxSplits: 1)
      if parts.count == 2 {
        result[String(parts[0])] = String(parts[1])
      }
    }
  }

  func fetchNotes(
    email: String,
    accessToken: String,
    completion: @escaping (Result<[Note], Error>) -> Void
  ) {
    var request = URLRequest(url: URL(string: "https://www.googleapis.com/notes/v1/changes")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
      "Authorization": "OAuth \(accessToken)",
      "Accept-Encoding": "gzip, deflate",
      "Content-Type": "application/json",
      "User-Agent": "github.com/geoje/keep",
    ]

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let requestBody: [String: Any] = [
      "nodes": [],
      "clientTimestamp": formatter.string(from: Date()),
      "requestHeader": [
        "clientSessionId": generateClientSessionId(),
        "clientPlatform": "ANDROID",
        "clientVersion": ["major": "9", "minor": "9", "build": "9", "revision": "9"],
        "capabilities": [
          ["type": "NC"], ["type": "PI"], ["type": "LB"], ["type": "AN"], ["type": "SH"],
          ["type": "DR"], ["type": "TR"], ["type": "IN"], ["type": "SNB"], ["type": "MI"],
          ["type": "CO"],
        ],
      ],
    ]

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    } catch {
      completion(.failure(error))
      return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        let error = NSError(
          domain: "GoogleAuthService", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No data received"])
        completion(.failure(error))
        return
      }

      completion(.success([]))
    }.resume()
  }

  private func generateClientSessionId() -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let randomInt = UInt32.random(in: 0...UInt32.max)
    return "s--\(timestamp)--\(randomInt)"
  }
}
