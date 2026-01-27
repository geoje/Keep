import Foundation

class GoogleAuthService {

  func getMasterToken(
    email: String,
    oauthToken: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
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
      "has_permission": "1",
      "add_account": "1",
      "ACCESS_TOKEN": "1",
      "Token": oauthToken,
      "service": "ac2dm",
      "source": "android",
      "androidId": "0123456789abcdef",
      "device_country": "us",
      "operatorCountry": "us",
      "lang": "en",
      "sdk_version": "17",
      "google_play_services_version": "240913000",
      "client_sig": "38918a453d07199354f8b19af05ec6562ced5788",
      "callerSig": "38918a453d07199354f8b19af05ec6562ced5788",
      "droidguard_results": "dummy123",
    ].map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data, let responseText = String(data: data, encoding: .utf8) else {
        completion(
          .failure(
            NSError(
              domain: "GoogleAuthService", code: 0,
              userInfo: [NSLocalizedDescriptionKey: "No data received or failed to decode response"]
            )))
        return
      }

      let responseDict = self.parseResponse(responseText)
      if let masterToken = responseDict["Token"] {
        completion(.success(masterToken))
      } else {
        let errorDetail = responseDict["Error"] ?? "Unknown error"
        let error = NSError(
          domain: "GoogleAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: errorDetail])
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
}
