import SwiftData
import SwiftUI

struct AccountListView: View {
  let accounts: [Account]
  @ObservedObject var contentViewModel: ContentViewModel
  @Environment(\.modelContext) private var modelContext

  @Query private var notes: [Note]
  private var noteService: NoteService { NoteService() }

  var body: some View {
    List {
      ForEach(accounts) { account in
        let isSelected = contentViewModel.selectedAccount?.email == account.email
        let noteCount = noteService.getRootNotes(notes: notes, email: account.email).count
        AccountRowView(
          account: account,
          isSelected: isSelected,
          isLoading: contentViewModel.loadingStates[account.email] ?? false,
          errorMessage: contentViewModel.errorMessages[account.email],
          noteCount: noteCount,
          hoveredAccountEmail: $contentViewModel.hoveredEmail,
          onTap: {
            contentViewModel.selectAccount(account, modelContext: modelContext)
          }
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
