import Combine
import SwiftData
import SwiftUI
import WidgetKit

class ContentViewModel: ObservableObject {
  @Published var hoveredAccountEmail: String?
  @Published var selectedAccount: Account?
  @Published var showDeleteConfirm = false
  @Published var isLoadingNotes = false
  @Published var loadingStates: [String: Bool] = [:]
  @Published var errorMessages: [String: String] = [:]

  private var noteService: NoteService
  private var peopleService: GooglePeopleService

  init() {
    self.noteService = NoteService()
    self.peopleService = GooglePeopleService()
  }

  func selectAccount(_ account: Account, modelContext: ModelContext) {
    if selectedAccount?.email == account.email {
      selectedAccount = nil
    } else {
      selectedAccount = account
      errorMessages[account.email] = nil
      loadingStates[account.email] = true
      Task {
        do {
          try await noteService.syncNotes(for: account, modelContext: modelContext)

          WidgetCenter.shared.reloadAllTimelines()

          if account.picture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let profileURL = try await peopleService.fetchProfileURL(
              accessToken: account.accessToken),
              !profileURL.isEmpty
            {
              account.picture = profileURL
              try modelContext.save()
            }
          }
        } catch {
          errorMessages[account.email] = error.localizedDescription
        }
        loadingStates[account.email] = false
      }
    }
  }

  func deleteSelectedAccount(modelContext: ModelContext) {
    if let account = selectedAccount {
      let existingNotes = try? modelContext.fetch(FetchDescriptor<Note>()).filter {
        $0.email == account.email
      }
      if let notes = existingNotes {
        for note in notes {
          modelContext.delete(note)
        }
      }
      modelContext.delete(account)
      selectedAccount = nil
      try modelContext.save()
    }
  }
}
