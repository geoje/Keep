import Foundation
import SwiftData

class GoogleApiService {
  func fetchMasterToken(email: String, oauthToken: String) async throws -> String {
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
        domain: "GoogleApiService", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = parseResponse(responseText)

    if let masterToken = responseDict["Token"] {
      return masterToken
    } else {
      throw NSError(
        domain: "GoogleApiService", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to get master token: \(responseDict["Error"] ?? "Unknown error")"
        ])
    }
  }

  func fetchAccessToken(email: String, masterToken: String) async throws -> (String, Date) {
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
        domain: "GoogleApiService", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = parseResponse(responseText)

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
        domain: "GoogleApiService", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to get access token: \(responseDict["Error"] ?? "Unknown error")"
        ])
    }
  }

  func fetchProfileURL(accessToken: String) async throws -> String? {
    let url = URL(string: "https://www.googleapis.com/oauth2/v1/userinfo")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = [
      "Authorization": "OAuth \(accessToken)",
      "Accept-Encoding": "gzip, deflate",
      "User-Agent": "github.com/geoje/keep",
    ]

    let (data, _) = try await URLSession.shared.data(for: request)

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let urlString = json["picture"] as? String
    else {
      return nil
    }

    return urlString
  }

  func fetchKeepNotes(email: String, accessToken: String) async throws -> [[String: Any]] {
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
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    let (data, _) = try await URLSession.shared.data(for: request)

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let nodesArray = json["nodes"] as? [[String: Any]]
    else {
      return []
    }

    return nodesArray
  }

  func syncNotes(for account: Account, modelContext: ModelContext) async throws {
    let accessToken = try await getAccessToken(for: account, modelContext: modelContext)
    let nodesArray = try await fetchKeepNotes(email: account.email, accessToken: accessToken)

    let accountEmail = account.email
    let existingNotes = try modelContext.fetch(
      FetchDescriptor<Note>(predicate: #Predicate { $0.email == accountEmail })
    )

    for note in existingNotes {
      modelContext.delete(note)
    }

    let notes = try nodesArray.map { nodeDict in
      return try Note.from(dict: nodeDict, email: account.email)
    }

    for note in notes {
      modelContext.insert(note)
    }

    try modelContext.save()
  }

  func getAccessToken(for account: Account, modelContext: ModelContext) async throws -> String {
    if !account.isAccessTokenExpired() && !account.accessToken.isEmpty {
      return account.accessToken
    } else {
      let (token, expiry) = try await fetchAccessToken(
        email: account.email, masterToken: account.masterToken)
      account.accessToken = token
      account.setAccessTokenExpiry(date: expiry)
      try modelContext.save()
      return token
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

  private func generateClientSessionId() -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let randomInt = UInt32.random(in: 0...UInt32.max)
    return "s--\(timestamp)--\(randomInt)"
  }
}
