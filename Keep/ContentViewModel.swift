import Combine
import SwiftData
import SwiftUI

class ContentViewModel: ObservableObject {
  @Published var hoveredAccountEmail: String?
  @Published var selectedAccount: Account?
  @Published var showDeleteConfirm = false
  @Published var isLoadingNotes = false
  @Published var loadingStates: [String: Bool] = [:]
  @Published var errorMessages: [String: String] = [:]

  private var noteService: NoteService

  init() {
    self.noteService = NoteService()
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
          let fetchedNotes = try await noteService.getNotes(for: account)
          let existingNotes = try modelContext.fetch(FetchDescriptor<Note>()).filter {
            $0.email == account.email
          }
          for note in existingNotes {
            modelContext.delete(note)
          }
          for note in fetchedNotes {
            modelContext.insert(note)
          }
          try modelContext.save()
        } catch {
          errorMessages[account.email] = error.localizedDescription
        }
        loadingStates[account.email] = false
      }
    }
  }

  func deleteSelectedAccount(modelContext: ModelContext) {
    if let account = selectedAccount {
      modelContext.delete(account)
      selectedAccount = nil
    }
  }
}
