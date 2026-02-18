import SwiftData
import SwiftUI

struct AccountListView: View {
  let playServiceAccounts: [PlayAccount]
  let chromeProfileAccounts: [ProfileAccount]
  @ObservedObject var viewModel: ContentViewModel
  @Environment(\.modelContext) private var modelContext

  @State private var isPlayServiceExpanded = true
  @State private var isChromeProfileExpanded = true

  var body: some View {
    List {
      if !playServiceAccounts.isEmpty {
        SectionHeaderView(title: "Play Service", isExpanded: $isPlayServiceExpanded)

        if isPlayServiceExpanded {
          PlayServiceAccountSectionContentView(
            accounts: playServiceAccounts,
            viewModel: viewModel,
            hoveredEmail: $viewModel.hoveredPlayServiceEmail
          )
        }
      }

      if !chromeProfileAccounts.isEmpty {
        SectionHeaderView(title: "Chrome Profile", isExpanded: $isChromeProfileExpanded)
          .padding(.top, 8)

        if isChromeProfileExpanded {
          ChromeProfileAccountSectionContentView(
            accounts: chromeProfileAccounts,
            viewModel: viewModel,
            hoveredEmail: $viewModel.hoveredChromeProfileEmail
          )
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

private struct PlayServiceAccountSectionContentView: View {
  let accounts: [PlayAccount]
  @ObservedObject var viewModel: ContentViewModel
  @Binding var hoveredEmail: String?
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ForEach(accounts) { account in
      let identifier = AccountIdentifier(section: .playService, email: account.email)
      let isSelected: Bool = {
        if case .playService(let selectedAccount) = viewModel.selectedAccount {
          return selectedAccount.email == account.email
        }
        return false
      }()
      AccountRowView(
        account: account,
        isSelected: isSelected,
        isLoading: viewModel.loadingStates[identifier] ?? false,
        errorMessage: viewModel.errorMessages[identifier],
        hoveredAccountEmail: $hoveredEmail,
        onTap: {
          viewModel.selectAccount(account, section: .playService, modelContext: modelContext)
        }
      )
    }
  }
}

private struct ChromeProfileAccountSectionContentView: View {
  let accounts: [ProfileAccount]
  @ObservedObject var viewModel: ContentViewModel
  @Binding var hoveredEmail: String?
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ForEach(accounts) { account in
      let identifier = AccountIdentifier(section: .chromeProfile, email: account.email)
      let isSelected: Bool = {
        if case .chromeProfile(let selectedAccount) = viewModel.selectedAccount {
          return selectedAccount.email == account.email
        }
        return false
      }()
      AccountRowView(
        account: account,
        isSelected: isSelected,
        isLoading: viewModel.loadingStates[identifier] ?? false,
        errorMessage: viewModel.errorMessages[identifier],
        hoveredAccountEmail: $hoveredEmail,
        onTap: {
          viewModel.selectProfileAccount(account, modelContext: modelContext)
        }
      )
    }
  }
}

private struct SectionHeaderView: View {
  let title: String
  @Binding var isExpanded: Bool

  var body: some View {
    HStack {
      Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(title)
        .font(.headline)
        .foregroundStyle(.primary)
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
    .padding(.leading, 8)
    .listRowSeparator(.hidden)
    .onTapGesture {
      withAnimation(.easeInOut(duration: 0.2)) {
        isExpanded.toggle()
      }
    }
  }
}
