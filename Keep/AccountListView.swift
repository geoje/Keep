import SwiftData
import SwiftUI

struct AccountListView: View {
  let playServiceAccounts: [Account]
  let chromeProfileAccounts: [Account]
  @ObservedObject var viewModel: ContentViewModel
  @Environment(\.modelContext) private var modelContext

  @State private var isPlayServiceExpanded = true
  @State private var isChromeProfileExpanded = true

  var body: some View {
    List {
      if !playServiceAccounts.isEmpty {
        HStack {
          Image(systemName: isPlayServiceExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text("Play Service")
            .font(.headline)
            .foregroundStyle(.primary)
          Spacer()
        }
        .padding(.leading, 8)
        .listRowSeparator(.hidden)
        .onTapGesture {
          withAnimation(.easeInOut(duration: 0.2)) {
            isPlayServiceExpanded.toggle()
          }
        }

        if isPlayServiceExpanded {
          ForEach(playServiceAccounts) { account in
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
      }

      if !chromeProfileAccounts.isEmpty {
        HStack {
          Image(systemName: isChromeProfileExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text("Chrome Profile")
            .font(.headline)
            .foregroundStyle(.primary)
          Spacer()
        }
        .padding(.leading, 8)
        .padding(.top, 8)
        .listRowSeparator(.hidden)
        .onTapGesture {
          withAnimation(.easeInOut(duration: 0.2)) {
            isChromeProfileExpanded.toggle()
          }
        }

        if isChromeProfileExpanded {
          ForEach(chromeProfileAccounts) { account in
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
      }
    }
    .listStyle(.plain)
    .safeAreaInset(edge: .bottom) {
      Rectangle()
        .frame(height: 0)
    }
  }
}
