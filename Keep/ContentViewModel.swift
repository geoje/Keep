import Combine
import SwiftData
import SwiftUI
import WidgetKit

enum AccountSection {
  case playService
  case chromeProfile
}

@MainActor
class ContentViewModel: ObservableObject {
  @Published var showDeleteConfirm = false
  @Published var hasSelectedAccount = false

  let playAccountViewModel = PlayAccountViewModel()
  let profileAccountViewModel = ProfileAccountViewModel()

  private var cancellables = Set<AnyCancellable>()

  init() {
    // Observe changes in both view models
    playAccountViewModel.$selectedAccount
      .combineLatest(profileAccountViewModel.$selectedAccount)
      .map { playAccount, profileAccount in
        playAccount != nil || profileAccount != nil
      }
      .assign(to: &$hasSelectedAccount)
  }

  func selectPlayAccount(
    _ account: PlayAccount, modelContext: ModelContext, completion: @escaping () -> Void = {}
  ) {
    profileAccountViewModel.clearSelection()
    playAccountViewModel.selectAccount(account, modelContext: modelContext, completion: completion)
  }

  func selectProfileAccount(_ account: ProfileAccount) {
    playAccountViewModel.clearSelection()
    profileAccountViewModel.selectAccount(account)
  }

  func deleteSelectedAccount(
    modelContext: ModelContext, onDeleteProfile: @escaping (ProfileAccount) -> Void
  ) {
    if playAccountViewModel.selectedAccount != nil {
      playAccountViewModel.deleteAccount(modelContext: modelContext)
    } else if profileAccountViewModel.selectedAccount != nil {
      profileAccountViewModel.deleteAccount(modelContext: modelContext, onDelete: onDeleteProfile)
    }
  }
}
