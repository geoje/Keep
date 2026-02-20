import Combine
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
class ContentViewModel: ObservableObject {
  @Published var showDeleteConfirm = false
  @Published var selectedAccount: Account?
  @Published var hoveredEmail: String?
  @Published var loadingStates: [String: Bool] = [:]
  @Published var errorMessages: [String: String] = [:]

  var hasSelectedAccount: Bool {
    selectedAccount != nil
  }

  private var noteService: NoteService
  private var peopleService: GooglePeopleService
  var chromeProfileService: ChromeProfileService?

  init() {
    self.noteService = NoteService()
    self.peopleService = GooglePeopleService()
  }

  func selectAccount(
    _ account: Account, modelContext: ModelContext, completion: @escaping () -> Void = {}
  ) {
    if selectedAccount?.email == account.email {
      selectedAccount = nil
    } else {
      selectedAccount = account
      errorMessages[account.email] = nil
      loadingStates[account.email] = true
      Task {
        do {
          if !account.masterToken.isEmpty {
            try await noteService.syncNotes(for: account, modelContext: modelContext)
          } else if !account.profileName.isEmpty {
            try await chromeProfileService?.syncNotes(for: account, modelContext: modelContext)
          }

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
        completion()
      }
    }
  }

  func deleteSelectedAccount(modelContext: ModelContext) {
    guard let account = selectedAccount else { return }

    if !account.profileName.isEmpty {
      if let chromeProfileService = chromeProfileService {
        try? chromeProfileService.deleteProfile(profileName: account.profileName)
      }
    }

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
    try? modelContext.save()
  }
}
