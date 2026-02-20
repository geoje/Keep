import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var accounts: [Account]

  @State private var showingAddAccountOptions = false
  @State private var showingErrorAlert = false
  @State private var errorMessage = ""
  @State private var chromePlayService: ChromePlayService?
  @State private var chromeProfileService: ChromeProfileService?

  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var chromeDriverService = ChromeDriverService()

  var body: some View {
    let content: some View =
      if accounts.isEmpty {
        AnyView(EmptyAccountsView())
      } else {
        AnyView(
          AccountListView(
            accounts: accounts,
            contentViewModel: viewModel))
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
      .alert("Add Account", isPresented: $showingAddAccountOptions) {
        Button("🔑 Login Play Service") {
          Task {
            await handleAddPlayAccount()
          }
        }
        Button("👤 Add Chrome Profiles") {
          Task {
            await handleAddProfileAccount()
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Try Login Play Service first. Use Add Chrome Profiles if you have an Enterprise account or encounter issues."
        )
      }
      .alert("⚠️ Error", isPresented: $showingErrorAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
      .onAppear {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
          return
        }
        if chromeProfileService == nil {
          chromeProfileService = ChromeProfileService(
            chromeDriverService: chromeDriverService)
          chromeProfileService?.onAddProfile = { profile in
            Task {
              await handleProfileAdded(profile: profile)
            }
          }
          viewModel.chromeProfileService = chromeProfileService
          Task {
            await syncChromeProfiles()
          }
        }
      }
      .onOpenURL { url in handleOpenURL(url) }
  }

  private func syncChromeProfiles() async {
    guard let chromeProfileService = chromeProfileService else { return }

    do {
      let currentProfiles = chromeProfileService.loadChromeProfiles()
      let currentProfileEmails = Set(currentProfiles.map { $0.email })

      let existingAccounts = try modelContext.fetch(
        FetchDescriptor<Account>(predicate: #Predicate { !$0.profileName.isEmpty })
      )

      for profile in currentProfiles {
        _ = try addOrUpdateAccount(
          email: profile.email,
          picture: profile.picture,
          profileName: profile.profileName,
          masterToken: profile.masterToken
        )
      }

      for account in existingAccounts {
        if !currentProfileEmails.contains(account.email) {
          if !account.masterToken.isEmpty {
            account.profileName = ""
          } else {
            modelContext.delete(account)
          }
        }
      }

      try modelContext.save()
    } catch {
      print("Failed to sync Chrome profiles: \(error)")
    }
  }

  private func addOrUpdateAccount(
    email: String,
    picture: String = "",
    profileName: String = "",
    masterToken: String = ""
  ) throws -> Account {
    let existingAccounts = try modelContext.fetch(
      FetchDescriptor<Account>(predicate: #Predicate { $0.email == email })
    )

    if let existingAccount = existingAccounts.first {
      if !picture.isEmpty {
        existingAccount.picture = picture
      }
      if !profileName.isEmpty {
        existingAccount.profileName = profileName
      }
      if !masterToken.isEmpty {
        existingAccount.masterToken = masterToken
      }
      try modelContext.save()
      return existingAccount
    } else {
      let newAccount = Account(
        email: email, picture: picture, profileName: profileName, masterToken: masterToken)
      modelContext.insert(newAccount)
      try modelContext.save()
      return newAccount
    }
  }

  private func handleAddPlayAccount() async {
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

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {
      let authService = GoogleAuthService()
      let masterToken = try await authService.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      let account = try addOrUpdateAccount(email: email, masterToken: masterToken)
      viewModel.selectAccount(account, modelContext: modelContext)
    } catch {
      errorMessage = error.localizedDescription
      showingErrorAlert = true
    }
  }

  private func handleAddProfileAccount() async {
    do {
      if chromeProfileService == nil {
        chromeProfileService = ChromeProfileService(
          chromeDriverService: chromeDriverService)
        chromeProfileService?.onAddProfile = { profile in
          Task {
            await handleProfileAdded(profile: profile)
          }
        }
      }
      try await chromeProfileService?.startAdd()
    } catch {
      errorMessage = error.localizedDescription
      showingErrorAlert = true
    }
  }

  private func handleProfileAdded(profile: Account) async {
    do {
      let account = try addOrUpdateAccount(
        email: profile.email,
        picture: profile.picture,
        profileName: profile.profileName,
        masterToken: profile.masterToken
      )
      viewModel.selectAccount(account, modelContext: modelContext)
    } catch {
      errorMessage = error.localizedDescription
      showingErrorAlert = true
    }
  }

  private func handleOpenURL(_ url: URL) {
    if url.scheme == "https" {
      NSWorkspace.shared.open(url)
      if let fragment = url.fragment, let serverId = fragment.split(separator: "/").last {
        let serverIdString = String(serverId)
        Task {
          do {
            let note = try modelContext.fetch(
              FetchDescriptor<Note>(predicate: #Predicate { $0.serverId == serverIdString })
            ).first
            if let note = note,
              let account = accounts.first(where: { $0.email == note.email })
            {
              viewModel.selectAccount(
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

#Preview("Empty Accounts") {
  ContentView()
    .modelContainer(for: [Account.self, Note.self], inMemory: true)
}

#Preview("With Accounts") {
  let container = try! ModelContainer(
    for: Schema([Account.self, Note.self]),
    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
  )

  container.mainContext.insert(
    Account(
      email: "boy@gmail.com",
      picture: "https://cdn-icons-png.flaticon.com/128/16683/16683419.png",
      masterToken: "sample_master_token"
    )
  )
  container.mainContext.insert(
    Account(
      email: "girl@gmail.com",
      picture: "https://cdn-icons-png.flaticon.com/128/16683/16683451.png",
      profileName: "Profile 1",
      masterToken: "sample_master_token"
    )
  )

  return ContentView()
    .modelContainer(container)
}
