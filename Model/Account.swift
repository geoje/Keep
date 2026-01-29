import Foundation
import SwiftData

@Model
final class Account {
  var email: String
  var picture: String = ""
  var masterToken: String = ""
  var accessToken: String = ""
  var accessTokenExpiry: String = ""

  init(
    email: String, picture: String = "", masterToken: String = "", accessToken: String = "",
    accessTokenExpiry: String = ""
  ) {
    self.email = email
    self.picture = picture
    self.masterToken = masterToken
    self.accessToken = accessToken
    self.accessTokenExpiry = accessTokenExpiry
  }

  func isAccessTokenExpired() -> Bool {
    guard !accessTokenExpiry.isEmpty else { return true }
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let expiryDate = dateFormatter.date(from: accessTokenExpiry) else { return true }
    return Date() > expiryDate
  }

  func setAccessTokenExpiry(date: Date) {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    self.accessTokenExpiry = dateFormatter.string(from: date)
  }
}
