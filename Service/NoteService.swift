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

  func getRootNotes(notes: [Note], email: String) -> [Note] {
    notes.filter {
      $0.email == email && $0.parentId == "root" && !$0.isArchived
        && $0.trashed.first != Character("2")
    }
  }

  func getRootCount(notes: [Note], email: String) -> Int {
    getRootNotes(notes: notes, email: email).count
  }
}
