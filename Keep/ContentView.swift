import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Account.email, order: .forward) private var accounts: [Account]

  @State private var showingAddAccountOptions = false
  @State private var showingErrorAlert = false
  @State private var errorMessage = ""
  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var chromeDriverService = ChromeDriverService()
  @State private var playServiceLoginService: ChromePlayLoginService?
  @State private var directLoginService: ChromeDirectLoginService?

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
      .alert("🗑️ Delete Account", isPresented: $viewModel.showDeleteConfirm) {
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
            showingAddAccountOptions = true
          }) {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .alert("➕ Add Account", isPresented: $showingAddAccountOptions) {
        Button("Google Play Service (Recommended)") {
          Task {
            do {
              if playServiceLoginService == nil {
                playServiceLoginService = ChromePlayLoginService(
                  chromeDriverService: chromeDriverService)
                playServiceLoginService?.onLoginSuccess = { email, oauthToken in
                  Task {
                    await handlePlayLoginSuccess(email: email, oauthToken: oauthToken)
                  }
                }
              }
              try await playServiceLoginService?.startLogin()
            } catch {
              errorMessage = error.localizedDescription
              showingErrorAlert = true
            }
          }
        }
        Button("Direct Google Login") {
          Task {
            do {
              if directLoginService == nil {
                directLoginService = ChromeDirectLoginService(
                  chromeDriverService: chromeDriverService)
              }
              try await directLoginService?.startLogin()
            } catch {
              errorMessage = error.localizedDescription
              showingErrorAlert = true
            }
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Try Google Play Service first. Use Direct Login if you have an Enterprise account or encounter issues."
        )
      }
      .alert("⚠️ Error", isPresented: $showingErrorAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
      .onOpenURL { url in
        if url.scheme == "https" {
          NSWorkspace.shared.open(url)
          if let fragment = url.fragment, let serverId = fragment.split(separator: "/").last {
            let serverIdString = String(serverId)
            Task {
              do {
                let note = try modelContext.fetch(
                  FetchDescriptor<Note>(predicate: #Predicate { $0.serverId == serverIdString })
                ).first
                if let note = note, let account = accounts.first(where: { $0.email == note.email })
                {
                  viewModel.selectAccount(account, modelContext: modelContext) {
                    NSApplication.shared.terminate(nil)
                  }
                }
              } catch {
                NSApplication.shared.terminate(nil)
              }
            }
          }
        }
      }
  }

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {
      let authService = GoogleAuthService()
      let masterToken = try await authService.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      let newAccount = Account(email: email, masterToken: masterToken)
      modelContext.insert(newAccount)
      try modelContext.save()

      viewModel.selectAccount(newAccount, modelContext: modelContext)
    } catch {
      errorMessage = error.localizedDescription
      showingErrorAlert = true
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
    Account(
      email: "boy@gmail.com", picture: "https://cdn-icons-png.flaticon.com/128/16683/16683419.png"),
    Account(
      email: "girl@gmail.com", picture: "https://cdn-icons-png.flaticon.com/128/16683/16683451.png"),
  ] {
    container.mainContext.insert(account)
  }

  return ContentView()
    .modelContainer(container)
}
