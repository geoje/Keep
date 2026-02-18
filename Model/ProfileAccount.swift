import Foundation

class ProfileAccount: Account, Identifiable {
  let id = UUID()
  var email: String
  var picture: String
  var profileName: String

  init(email: String, picture: String = "", profileName: String) {
    self.email = email
    self.picture = picture
    self.profileName = profileName
  }
}
