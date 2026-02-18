import SwiftData
import SwiftUI

struct AccountListView: View {
  let playServiceAccounts: [PlayAccount]
  let chromeProfileAccounts: [ProfileAccount]
  @ObservedObject var contentViewModel: ContentViewModel
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
            contentViewModel: contentViewModel
          )
        }
      }

      if !chromeProfileAccounts.isEmpty {
        SectionHeaderView(title: "Chrome Profile", isExpanded: $isChromeProfileExpanded)
          .padding(.top, 8)

        if isChromeProfileExpanded {
          ChromeProfileAccountSectionContentView(
            accounts: chromeProfileAccounts,
            contentViewModel: contentViewModel
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
  @ObservedObject var contentViewModel: ContentViewModel
  @ObservedObject var playAccountViewModel: PlayAccountViewModel
  @Environment(\.modelContext) private var modelContext

  @Query private var notes: [Note]
  private var noteService: NoteService { NoteService() }

  init(accounts: [PlayAccount], contentViewModel: ContentViewModel) {
    self.accounts = accounts
    self.contentViewModel = contentViewModel
    self.playAccountViewModel = contentViewModel.playAccountViewModel
  }

  var body: some View {
    ForEach(accounts) { account in
      let isSelected = playAccountViewModel.selectedAccount?.email == account.email
      let noteCount = noteService.getRootNotes(notes: notes, email: account.email).count
      AccountRowView(
        account: account,
        isSelected: isSelected,
        isLoading: playAccountViewModel.loadingStates[account.email] ?? false,
        errorMessage: playAccountViewModel.errorMessages[account.email],
        noteCount: noteCount,
        hoveredAccountEmail: $playAccountViewModel.hoveredEmail,
        onTap: {
          contentViewModel.selectPlayAccount(account, modelContext: modelContext)
        }
      )
    }
  }
}

private struct ChromeProfileAccountSectionContentView: View {
  let accounts: [ProfileAccount]
  @ObservedObject var contentViewModel: ContentViewModel
  @ObservedObject var profileAccountViewModel: ProfileAccountViewModel

  init(accounts: [ProfileAccount], contentViewModel: ContentViewModel) {
    self.accounts = accounts
    self.contentViewModel = contentViewModel
    self.profileAccountViewModel = contentViewModel.profileAccountViewModel
  }

  var body: some View {
    ForEach(accounts) { account in
      let isSelected = profileAccountViewModel.selectedAccount?.email == account.email
      AccountRowView(
        account: account,
        isSelected: isSelected,
        isLoading: profileAccountViewModel.loadingStates[account.email] ?? false,
        errorMessage: profileAccountViewModel.errorMessages[account.email],
        noteCount: 0,
        hoveredAccountEmail: $profileAccountViewModel.hoveredEmail,
        onTap: {
          contentViewModel.selectProfileAccount(account)
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
