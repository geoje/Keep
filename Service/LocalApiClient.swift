import Foundation

struct LocalApiClient {
  static let shared = LocalApiClient()
  private let baseURL = URL(string: "http://localhost:14339")!

  func fetchNotes() async throws -> [Note] {
    let url = baseURL.appendingPathComponent("notes")
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      throw URLError(.cannotParseResponse)
    }
    return jsonArray.map { Note.decode(dict: $0) }
  }
}
