import SwiftData

@Model
final class Account {
  var email: String
  var avatar: String = ""
  var masterToken: String = ""

  init(email: String, avatar: String = "", masterToken: String = "") {
    self.email = email
    self.avatar = avatar
    self.masterToken = masterToken
  }
}
