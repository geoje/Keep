import AppKit
import SwiftData
import SwiftUI

struct ContentView: View {
  let modelContainer: ModelContainer

  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var chromeDriverService = ChromeDriverService()

  @State private var chromePlayService: ChromePlayService?
  @State private var chromeProfileService: ChromeProfileService?

  private var noteService: NoteService { NoteService() }

  private var modelContext: ModelContext {
    modelContainer.mainContext
  }

  var body: some View {
    Text("Add Account").font(.subheadline).bold()
    Button("Play Service 🔑") {
      Task {
        await handleAddPlayAccount()
      }
    }
    Button("Chrome Profiles 👤") {
      Task {
        await handleAddProfileAccount()
      }
    }
    Divider()

    ForEach(viewModel.accounts) { account in
      let noteCount = noteService.getRootNotes(notes: viewModel.notes, email: account.email).count
      let hasPlayService = !account.masterToken.isEmpty
      let hasProfile = !account.profileName.isEmpty
      let icon = hasPlayService && hasProfile ? "🔑👤" : hasPlayService ? "🔑" : hasProfile ? "👤" : ""
      let errorMessage = viewModel.errorMessages[account.email]

      Text("\(account.email) \(icon)").font(.subheadline).bold()
      if let error = errorMessage {
        Text(error).font(.subheadline).foregroundStyle(.orange)
      } else {
        Text("\(noteCount) Notes").font(.subheadline)
      }
      Button("Delete") {
        deleteAccount(account)
      }
      Divider()
    }

    Button(action: {}) {
      Label("Update Keep", systemImage: "arrow.down.circle")
    }
    Button(action: {
      Task { await syncAllAccounts() }
    }) {
      Label("Sync All", systemImage: "arrow.trianglehead.clockwise.icloud")
    }
    Button(action: {
      NSApplication.shared.terminate(nil)
    }) {
      Label("Quit", systemImage: "xmark.rectangle")
    }

    .onAppear {
      loadAccounts()

      if chromeProfileService == nil {
        chromeProfileService = ChromeProfileService(
          chromeDriverService: chromeDriverService)
        chromeProfileService?.onAddSuccess = { profile in
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
  }

  private func loadAccounts() {
    do {
      viewModel.accounts = try modelContext.fetch(FetchDescriptor<Account>())
      viewModel.notes = try modelContext.fetch(FetchDescriptor<Note>())
    } catch {
      viewModel.accounts = []
      viewModel.notes = []
    }
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
      loadAccounts()
    } catch {
      // Silently ignore sync errors
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
      loadAccounts()
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
      // Silently ignore login errors
    }
  }

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {
      let googleApiService = GoogleApiService()
      let masterToken = try await googleApiService.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      _ = try addOrUpdateAccount(email: email, masterToken: masterToken)
      loadAccounts()
    } catch {
      // Silently ignore errors
    }
  }

  private func handleAddProfileAccount() async {
    do {
      if chromeProfileService == nil {
        chromeProfileService = ChromeProfileService(
          chromeDriverService: chromeDriverService)
        chromeProfileService?.onAddSuccess = { profile in
          Task {
            await handleProfileAdded(profile: profile)
          }
        }
      }
      try await chromeProfileService?.startAdd()
    } catch {
      // Silently ignore errors
    }
  }

  private func handleProfileAdded(profile: Account) async {
    do {
      try addOrUpdateAccount(
        email: profile.email,
        picture: profile.picture,
        profileName: profile.profileName,
        masterToken: profile.masterToken
      )
      loadAccounts()
    } catch {
      // Silently ignore errors
    }
  }

  private func deleteAccount(_ account: Account) {
    if !account.profileName.isEmpty {
      if let chromeProfileService = chromeProfileService {
        try? chromeProfileService.deleteProfile(profileName: account.profileName)
      }
    }

    let existingNotes = try? modelContext.fetch(FetchDescriptor<Note>()).filter {
      $0.email == account.email
    }
    if let notes = existingNotes {
      for note in notes {
        modelContext.delete(note)
      }
    }

    modelContext.delete(account)
    try? modelContext.save()
    loadAccounts()
  }

  private func syncAllAccounts() async {
    for account in viewModel.accounts {
      viewModel.selectedAccount = account
      viewModel.errorMessages[account.email] = nil
      do {
        let googleApiService = GoogleApiService()
        if !account.masterToken.isEmpty {
          try await googleApiService.syncNotes(for: account, modelContext: modelContext)
        } else if !account.profileName.isEmpty {
          try await chromeProfileService?.syncNotes(for: account, modelContext: modelContext)
        }
      } catch {
        viewModel.errorMessages[account.email] = error.localizedDescription
      }
    }
  }
}
