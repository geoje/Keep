import Foundation
import SwiftData

class AccountService {
  func getAccessToken(for account: Account) async throws -> String {
    if !account.isAccessTokenExpired() && !account.accessToken.isEmpty {
      return account.accessToken
    } else {
      let (token, expiry) = try await GoogleAuthService().fetchAccessToken(
        email: account.email, masterToken: account.masterToken)
      account.accessToken = token
      account.setAccessTokenExpiry(date: expiry)
      return token
    }
  }
}
