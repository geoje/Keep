import Foundation
import SwiftData

@Model
final class Account {
  var email: String
  var avatar: String = ""
  var masterToken: String = ""
  var accessToken: String = ""
  var accessTokenExpiry: Date = Date(timeIntervalSince1970: 0)

  init(
    email: String, avatar: String = "", masterToken: String = "", accessToken: String = "",
    accessTokenExpiry: Date = Date(timeIntervalSince1970: 0)
  ) {
    self.email = email
    self.avatar = avatar
    self.masterToken = masterToken
    self.accessToken = accessToken
    self.accessTokenExpiry = accessTokenExpiry
  }
}
