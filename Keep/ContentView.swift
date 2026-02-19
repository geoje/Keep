import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PlayAccount.email, order: .forward) private var accounts: [PlayAccount]

  @State private var showingAddAccountOptions = false
  @State private var showingErrorAlert = false
  @State private var errorMessage = ""
  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var chromeDriverService = ChromeDriverService()
  @State private var chromePlayService: ChromePlayService?
  @State private var chromeProfileService: ChromeProfileService?
  @State private var chromeProfileAccounts: [ProfileAccount] = []

  var body: some View {
    let content: some View =
      if accounts.isEmpty {
        AnyView(EmptyAccountsView())
      } else {
        AnyView(
          AccountListView(
            playServiceAccounts: accounts, chromeProfileAccounts: chromeProfileAccounts,
            contentViewModel: viewModel))
      }
    return
      content
      .frame(minWidth: 360, maxWidth: 360, minHeight: 240)
      .alert("🗑️ Delete Account", isPresented: $viewModel.showDeleteConfirm) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          viewModel.deleteSelectedAccount(modelContext: modelContext) { profileAccount in
            chromeProfileAccounts.removeAll { $0.email == profileAccount.email }
          }
        }
      } message: {
        Text("Are you sure you want to delete this account?")
      }
      .toolbar {
        if viewModel.hasSelectedAccount {
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
        Button("Login Play Service") {
          Task {
            do {
              if chromePlayService == nil {
                chromePlayService = ChromePlayService(
                  chromeDriverService: chromeDriverService)
                chromePlayService?.onLoginSuccess = { email, oauthToken in
                  Task {
                    await handlePlayLoginSuccess(email: email, oauthToken: oauthToken)
                  }
                }
              }
              try await chromePlayService?.startLogin()
            } catch {
              errorMessage = error.localizedDescription
              showingErrorAlert = true
            }
          }
        }
        Button("Add Chrome Profile") {
          Task {
            do {
              try await chromeProfileService?.startAdd()
            } catch {
              errorMessage = error.localizedDescription
              showingErrorAlert = true
            }
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Try Login Play Service first. Use Add Chrome Profile if you have an Enterprise account or encounter issues."
        )
      }
      .alert("⚠️ Error", isPresented: $showingErrorAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
      .onAppear {
        if chromeProfileService == nil {
          chromeProfileService = ChromeProfileService(
            chromeDriverService: chromeDriverService)
          chromeProfileService?.onAddSuccess = { profiles in
            Task {
              await MainActor.run {
                chromeProfileAccounts = profiles
              }
            }
          }
        }
        chromeProfileAccounts = chromeProfileService?.loadChromeProfiles() ?? []
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
                  viewModel.selectPlayAccount(
                    account, modelContext: modelContext
                  ) {
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

      let newAccount = PlayAccount(email: email, masterToken: masterToken)
      modelContext.insert(newAccount)
      try modelContext.save()

      viewModel.selectPlayAccount(newAccount, modelContext: modelContext)
    } catch {
      errorMessage = error.localizedDescription
      showingErrorAlert = true
    }
  }

}

#Preview("Empty Accounts") {
  ContentView()
    .modelContainer(for: [PlayAccount.self, Note.self], inMemory: true)
}

#Preview("With Accounts") {
  let container = try! ModelContainer(
    for: Schema([PlayAccount.self, Note.self]),
    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
  )

  let viewModel = ContentViewModel()

  return AccountListView(
    playServiceAccounts: [
      PlayAccount(
        email: "boy@gmail.com",
        picture: "https://cdn-icons-png.flaticon.com/128/16683/16683419.png"
      )
    ],
    chromeProfileAccounts: [
      ProfileAccount(
        email: "girl@gmail.com",
        picture: "https://cdn-icons-png.flaticon.com/128/16683/16683451.png",
        profileName: "Profile 1"
      )
    ],
    contentViewModel: viewModel
  )
  .modelContainer(container)
}
