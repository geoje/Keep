import Foundation

class GooglePeopleService {

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
}
