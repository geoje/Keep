import Combine
import SwiftData
import SwiftUI
import WidgetKit

enum AccountSection {
  case playService
  case chromeProfile
}

struct AccountIdentifier: Hashable {
  let section: AccountSection
  let email: String
}

struct SelectedAccount {
  let section: AccountSection
  let account: Account
}

class ContentViewModel: ObservableObject {
  @Published var hoveredPlayServiceEmail: String?
  @Published var hoveredChromeProfileEmail: String?
  @Published var selectedAccount: SelectedAccount?
  @Published var showDeleteConfirm = false
  @Published var isLoadingNotes = false
  @Published var loadingStates: [AccountIdentifier: Bool] = [:]
  @Published var errorMessages: [AccountIdentifier: String] = [:]

  private var noteService: NoteService
  private var peopleService: GooglePeopleService

  init() {
    self.noteService = NoteService()
    self.peopleService = GooglePeopleService()
  }

  func selectAccount(
    _ account: Account, section: AccountSection, modelContext: ModelContext,
    completion: @escaping () -> Void = {}
  ) {
    let identifier = AccountIdentifier(section: section, email: account.email)

    if selectedAccount?.section == section && selectedAccount?.account.email == account.email {
      selectedAccount = nil
    } else {
      selectedAccount = SelectedAccount(section: section, account: account)
      errorMessages[identifier] = nil
      loadingStates[identifier] = true
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
          errorMessages[identifier] = error.localizedDescription
        }
        loadingStates[identifier] = false
        completion()
      }
    }
  }

  func deleteSelectedAccount(modelContext: ModelContext) {
    guard let selected = selectedAccount else { return }

    let account = selected.account

    // Delete associated notes
    let existingNotes = try? modelContext.fetch(FetchDescriptor<Note>()).filter {
      $0.email == account.email
    }
    if let notes = existingNotes {
      for note in notes {
        modelContext.delete(note)
      }
    }

    // Only delete from SwiftData if it's a Play Service account
    if selected.section == .playService {
      modelContext.delete(account)
    }

    selectedAccount = nil
    try? modelContext.save()
  }
}
