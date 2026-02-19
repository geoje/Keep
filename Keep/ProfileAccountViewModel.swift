import Combine
import SwiftData
import SwiftUI

@MainActor
class ProfileAccountViewModel: ObservableObject {
  @Published var selectedAccount: Account?
  @Published var hoveredEmail: String?
  @Published var loadingStates: [String: Bool] = [:]
  @Published var errorMessages: [String: String] = [:]

  func selectAccount(_ account: Account) {
    if selectedAccount?.email == account.email {
      selectedAccount = nil
    } else {
      selectedAccount = account
      errorMessages[account.email] = nil
      loadingStates[account.email] = true

      // TODO: Launch headless Chrome and parse notes
      // For now, just mark as loaded
      loadingStates[account.email] = false
    }
  }

  func clearSelection() {
    selectedAccount = nil
  }

  func deleteAccount(modelContext: ModelContext, onDelete: @escaping (Account) -> Void) {
    guard let account = selectedAccount else { return }

    // TODO: Delete Chrome profile folder
    // Remove from memory list
    onDelete(account)

    selectedAccount = nil
    try? modelContext.save()
  }
}
