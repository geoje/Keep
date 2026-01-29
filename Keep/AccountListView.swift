import SwiftData
import SwiftUI

struct AccountListView: View {
  let accounts: [Account]
  @ObservedObject var viewModel: ContentViewModel
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    List {
      ForEach(accounts) { account in
        AccountRowView(
          account: account,
          isSelected: viewModel.selectedAccount?.email == account.email,
          isLoading: viewModel.loadingStates[account.email] ?? false,
          errorMessage: viewModel.errorMessages[account.email],
          hoveredAccountEmail: $viewModel.hoveredAccountEmail,
          onTap: { viewModel.selectAccount(account, modelContext: modelContext) }
        )
      }
    }
    .listStyle(.plain)
    .safeAreaInset(edge: .bottom) {
      Rectangle()
        .frame(height: 0)
    }
  }
}
