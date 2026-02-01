import Foundation
import SwiftData

class GoogleKeepService {

  func syncNotes(
    email: String,
    accessToken: String,
    modelContext: ModelContext
  ) async throws {
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
      return
    }

    let notes = try nodesArray.map { nodeDict in
      return try Note.from(dict: nodeDict, email: email)
    }

    let existingNotes = try modelContext.fetch(FetchDescriptor<Note>()).filter {
      $0.email == email
    }
    for note in existingNotes {
      modelContext.delete(note)
    }

    for note in notes {
      modelContext.insert(note)
    }

    try modelContext.save()
  }

  private func generateClientSessionId() -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let randomInt = UInt32.random(in: 0...UInt32.max)
    return "s--\(timestamp)--\(randomInt)"
  }
}
