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

enum SelectedAccount {
  case playService(PlayAccount)
  case chromeProfile(ProfileAccount)

  var section: AccountSection {
    switch self {
    case .playService: return .playService
    case .chromeProfile: return .chromeProfile
    }
  }

  var email: String {
    switch self {
    case .playService(let account): return account.email
    case .chromeProfile(let profileAccount): return profileAccount.email
    }
  }

  var playAccount: PlayAccount? {
    switch self {
    case .playService(let account): return account
    case .chromeProfile: return nil
    }
  }

  var profileAccount: ProfileAccount? {
    switch self {
    case .playService: return nil
    case .chromeProfile(let profileAccount): return profileAccount
    }
  }
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
    _ account: PlayAccount, section: AccountSection, modelContext: ModelContext,
    completion: @escaping () -> Void = {}
  ) {
    let identifier = AccountIdentifier(section: section, email: account.email)

    if case .playService(let selectedAccount) = selectedAccount,
      selectedAccount.email == account.email
    {
      self.selectedAccount = nil
    } else {
      selectedAccount = .playService(account)
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

  func selectProfileAccount(_ profileAccount: ProfileAccount, modelContext: ModelContext) {
    let identifier = AccountIdentifier(section: .chromeProfile, email: profileAccount.email)

    if case .chromeProfile(let selectedProfileAccount) = selectedAccount,
      selectedProfileAccount.email == profileAccount.email
    {
      self.selectedAccount = nil
    } else {
      selectedAccount = .chromeProfile(profileAccount)
      errorMessages[identifier] = nil
      loadingStates[identifier] = true
      // Chrome Profile accounts don't sync notes yet
      loadingStates[identifier] = false
    }
  }

  func deleteSelectedAccount(modelContext: ModelContext) {
    guard let selected = selectedAccount else { return }

    let email = selected.email

    // Delete associated notes
    let existingNotes = try? modelContext.fetch(FetchDescriptor<Note>()).filter {
      $0.email == email
    }
    if let notes = existingNotes {
      for note in notes {
        modelContext.delete(note)
      }
    }

    // Only delete from SwiftData if it's a Play Service account
    if case .playService(let account) = selected {
      modelContext.delete(account)
    }

    selectedAccount = nil
    try? modelContext.save()
  }
}
