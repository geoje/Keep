import Foundation

class GoogleAuthService {
  // Google API Constants
  private let AUTH_URL = "https://android.clients.google.com/auth"
  private let USER_AGENT = "GoogleAuth/1.4"

  // HTTP Headers
  private let headers: [String: String] = [
    "Accept-Encoding": "identity",
    "Content-type": "application/x-www-form-urlencoded",
    "User-Agent": "GoogleAuth/1.4",
  ]

  /// Exchanges an OAuth token for a master token.
  /// - Parameters:
  ///   - email: Google account email address
  ///   - oauthToken: OAuth token to exchange
  ///   - androidId: Android device ID
  ///   - service: Service name (default: "ac2dm")
  ///   - completion: Completion handler with masterToken or error
  func getMasterToken(
    email: String,
    oauthToken: String,
    androidId: String,
    service: String = "ac2dm",
    completion: @escaping (String?, String?) -> Void
  ) {
    // Construct request parameters based on exchange_token method from gpsoauth
    let parameters: [String: String] = [
      "accountType": "HOSTED_OR_GOOGLE",
      "Email": email,
      "has_permission": "1",
      "add_account": "1",
      "ACCESS_TOKEN": "1",
      "Token": oauthToken,
      "service": service,
      "source": "android",
      "androidId": androidId,
      "device_country": "us",
      "operatorCountry": "us",
      "lang": "en",
      "sdk_version": "17",
      "google_play_services_version": "240913000",
      "client_sig": "38918a453d07199354f8b19af05ec6562ced5788",
      "callerSig": "38918a453d07199354f8b19af05ec6562ced5788",
      "droidguard_results": "dummy123",
    ]

    // Create URL and URLRequest
    guard let url = URL(string: AUTH_URL) else {
      completion(nil, "Invalid URL")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers

    // Encode parameters as form data (application/x-www-form-urlencoded)
    let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    request.httpBody = bodyString.data(using: .utf8)

    // Perform HTTP request to Google Auth API
    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(nil, error.localizedDescription)
        return
      }

      guard let data = data else {
        completion(nil, "No data received")
        return
      }

      guard let responseText = String(data: data, encoding: .utf8) else {
        completion(nil, "Failed to decode response")
        return
      }

      // Parse response and extract master token
      let (masterToken, errorMessage) = self.parseAuthResponse(responseText)
      print("📨 Raw response from Google Auth API: \(responseText)")
      if masterToken != nil {
        print("✅ Successfully extracted master token from response")
      } else if let errorMessage = errorMessage {
        print("⚠️ Failed to extract master token from response: \(errorMessage)")
      }
      completion(masterToken, errorMessage)
    }.resume()
  }

  /// Parses the authentication response and extracts the master token or error.
  /// - Parameter responseText: Response text received from Google authentication API
  /// - Returns: Tuple of (masterToken, errorMessage). If successful, masterToken is non-nil; if error, errorMessage is non-nil.
  private func parseAuthResponse(_ responseText: String) -> (String?, String?) {
    let lines = responseText.split(separator: "\n", omittingEmptySubsequences: true)

    for line in lines {
      let parts = line.split(separator: "=", maxSplits: 1)
      if parts.count == 2 {
        let key = parts[0]
        let value = parts[1]
        if key == "Token" {
          return (String(value), nil)
        } else if key == "Error" {
          return (nil, String(value))
        }
      }
    }

    return (nil, "Unknown error")
  }
}
