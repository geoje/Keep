import Foundation
import SwiftData

class AccountService {
  func getAccessToken(for account: Account, completion: @escaping (Result<String, Error>) -> Void) {
    if account.accessTokenExpiry > Date() && !account.accessToken.isEmpty {
      completion(.success(account.accessToken))
    } else {
      GoogleAuthService().getAccessToken(email: account.email, masterToken: account.masterToken) {
        result in
        DispatchQueue.main.async {
          switch result {
          case .success((let token, let expiry)):
            account.accessToken = token
            account.accessTokenExpiry = expiry
            completion(.success(token))
          case .failure(let error):
            completion(.failure(error))
          }
        }
      }
    }
  }
}
