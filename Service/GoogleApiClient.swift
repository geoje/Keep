import AppKit
import Foundation
import SwiftData

class GoogleApiClient {
  static let shared = GoogleApiClient()

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
        domain: "GoogleApiClient", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = parseAuthResponse(responseText)

    if let masterToken = responseDict["Token"] {
      return masterToken
    } else {
      throw NSError(
        domain: "GoogleApiClient", code: 1,
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
        domain: "GoogleApiClient", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No data received"])
    }
    let responseDict = parseAuthResponse(responseText)

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
        domain: "GoogleApiClient", code: 1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to get access token: \(responseDict["Error"] ?? "Unknown error")"
        ])
    }
  }

  private func parseAuthResponse(_ responseText: String) -> [String: String] {
    return responseText.split(separator: "\n").reduce(into: [String: String]()) { result, line in
      let parts = line.split(separator: "=", maxSplits: 1)
      if parts.count == 2 {
        result[String(parts[0])] = String(parts[1])
      }
    }
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

  private func fetchNotes(
    email: String,
    accessToken: String,
    targetVersion: String? = nil,
    nodes: [[String: Any]] = []
  ) async throws -> (toVersion: String, nodes: [[String: Any]]) {
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
    var requestBody: [String: Any] = [
      "nodes": nodes,
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
    if let v = targetVersion { requestBody["targetVersion"] = v }
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    print("[fetchNotes] sending \(nodes.count) node(s), targetVersion: \(targetVersion ?? "nil")")
    if !nodes.isEmpty,
      let bodyData = request.httpBody,
      let bodyStr = String(data: bodyData, encoding: .utf8)
    {
      print("[fetchNotes] request body: \(bodyStr)")
    }

    let (data, _) = try await URLSession.shared.data(for: request)

    if let responseStr = String(data: data, encoding: .utf8) {
      print("[fetchNotes] response: \(responseStr)")
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return ("", [])
    }

    let toVersion = json["toVersion"] as? String ?? ""
    let nodesArray = json["nodes"] as? [[String: Any]] ?? []
    return (toVersion, nodesArray)
  }

  private func generateClientSessionId() -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let randomInt = UInt32.random(in: 0...UInt32.max)
    return "s--\(timestamp)--\(randomInt)"
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

  func getProfilePicture(for account: Account) async -> NSImage? {
    let fileManager = FileManager.default
    guard
      let bundleIdentifier = Bundle.main.bundleIdentifier,
      let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first
    else { return nil }
    let baseBundleIdentifier = bundleIdentifier.components(separatedBy: ".").prefix(3).joined(
      separator: ".")
    let dataDirectory = appSupportURL.appendingPathComponent(baseBundleIdentifier)
    let localURL = dataDirectory.appendingPathComponent(account.email + ".png")

    if FileManager.default.fileExists(atPath: localURL.path),
      let data = try? Data(contentsOf: localURL),
      let image = NSImage(data: data)
    {
      return image
    }

    guard !account.picture.isEmpty, let url = URL(string: account.picture) else { return nil }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let image = NSImage(data: data) else { return nil }
      try? data.write(to: localURL)
      return image
    } catch {
      return nil
    }
  }

  func syncNotes(for account: Account, modelContext: ModelContext) async throws {
    let accessToken = try await getAccessToken(for: account, modelContext: modelContext)
    let accountEmail = account.email
    let allNotes = try modelContext.fetch(
      FetchDescriptor<Note>(predicate: #Predicate { $0.email == accountEmail })
    )

    if account.syncVersion.isEmpty {
      // Full sync: fetch everything, replace local
      let (toVersion, nodesArray) = try await fetchNotes(
        email: accountEmail, accessToken: accessToken)

      for note in allNotes { modelContext.delete(note) }

      for nodeDict in nodesArray {
        let note = try Note.parse(dict: nodeDict, email: accountEmail)
        modelContext.insert(note)
      }

      account.syncVersion = toVersion
    } else {
      // Delta sync: send dirty notes, merge response
      var noteById = Dictionary(uniqueKeysWithValues: allNotes.map { ($0.id, $0) })

      var nodesToSend: [[String: Any]] = []
      var sentIds = Set<String>()

      for note in allNotes where note.isDirty && note.parentId == "root" {
        if !sentIds.contains(note.id) {
          nodesToSend.append(note.toApiDict())
          sentIds.insert(note.id)
        }
        for child in allNotes where child.parentId == note.id {
          if !sentIds.contains(child.id) {
            nodesToSend.append(child.toApiDict(parentServerId: note.serverId))
            sentIds.insert(child.id)
          }
        }
      }
      for note in allNotes where note.isDirty && note.parentId != "root" {
        if !sentIds.contains(note.id) {
          let parent = noteById[note.parentId]
          nodesToSend.append(note.toApiDict(parentServerId: parent?.serverId))
          sentIds.insert(note.id)
        }
      }

      let (toVersion, responseNodes) = try await fetchNotes(
        email: accountEmail,
        accessToken: accessToken,
        targetVersion: account.syncVersion,
        nodes: nodesToSend
      )

      for nodeDict in responseNodes {
        guard let id = nodeDict["id"] as? String else { continue }

        if let existing = noteById[id] {
          existing.update(from: nodeDict)
        } else {
          let note = try Note.parse(dict: nodeDict, email: accountEmail)
          modelContext.insert(note)
          noteById[note.id] = note
        }
      }

      for id in sentIds { noteById[id]?.isDirty = false }
      account.syncVersion = toVersion
    }

    try modelContext.save()
  }
}
