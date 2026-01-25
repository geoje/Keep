import Foundation
import SwiftData

@Model
final class Account {
  var email: String
  var avatar: String

  init(email: String, avatar: String) {
    self.email = email
    self.avatar = avatar
  }
}
