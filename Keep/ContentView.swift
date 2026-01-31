import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Account.email, order: .forward) private var accounts: [Account]

  @State private var showingAddAccount = false
  @StateObject private var viewModel = ContentViewModel()

  var body: some View {
    let content: some View =
      if accounts.isEmpty {
        AnyView(EmptyAccountsView())
      } else {
        AnyView(AccountListView(accounts: accounts, viewModel: viewModel))
      }
    return
      content
      .frame(minWidth: 360, maxWidth: 360, minHeight: 240)
      .alert("Delete Account", isPresented: $viewModel.showDeleteConfirm) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          viewModel.deleteSelectedAccount(modelContext: modelContext)
        }
      } message: {
        Text("Are you sure you want to delete this account?")
      }
      .toolbar {
        if viewModel.selectedAccount != nil {
          ToolbarItem(placement: .automatic) {
            Button(action: {
              viewModel.showDeleteConfirm = true
            }) {
              Label("Delete", systemImage: "trash")
                .foregroundStyle(.red)
            }
          }
        }
        ToolbarItem(placement: .automatic) {
          Button(action: {
            showingAddAccount = true
          }) {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $showingAddAccount) {
        AddAccountView { account in
          viewModel.selectAccount(account, modelContext: modelContext)
        }
      }
  }
}

#Preview("Empty Accounts") {
  ContentView()
    .modelContainer(for: [Account.self, Note.self], inMemory: true)
}

#Preview("With Accounts") {
  let container = try! ModelContainer(
    for: Schema([Account.self, Note.self]),
    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
  )

  for account in [
    Account(email: "boy@gmail.com", picture: "https://cdn-icons-png.flaticon.com/128/16683/16683419.png"),
    Account(email: "girl@gmail.com", picture: "https://cdn-icons-png.flaticon.com/128/16683/16683451.png")
  ] {
    container.mainContext.insert(account)
  }

  return ContentView()
    .modelContainer(container)
}
