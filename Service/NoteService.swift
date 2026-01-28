import Foundation
import SwiftData

class NoteService {
  func getNotes(for account: Account) async throws -> [Note] {
    let accountService = AccountService()
    let accessToken = try await accountService.getAccessToken(for: account)
    let keepService = GoogleKeepService()
    let notes = try await keepService.fetchNotes(email: account.email, accessToken: accessToken)
    return notes
  }
}
