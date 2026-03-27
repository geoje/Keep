import AppKit
import Sparkle
import SwiftData
import SwiftUI
import UserNotifications
import WidgetKit

struct ContentView: View {
  let modelContainer: ModelContainer

  @State private var accounts: [Account] = []
  @State private var notes: [Note] = []
  @State private var errorMessages: [String: String] = [:]
  @State private var loadingStates: [String: Bool] = [:]
  @State private var syncTimer: Timer? = nil
  @State private var updaterController: SPUStandardUpdaterController = {
    SPUStandardUpdaterController(
      startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  }()

  private var modelContext: ModelContext {
    modelContainer.mainContext
  }

  var body: some View {
    VStack(spacing: 0) {
      // Scrollable account list
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(accounts) { account in
            HStack {
              Text(account.email)
                .font(.subheadline)
              Spacer()
              Button(action: { deleteAccount(account) }) {
                Image(systemName: "trash")
                  .foregroundStyle(.secondary)
              }
              .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Divider()
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      // Bottom dock
      HStack(spacing: 0) {
        // Add account (leftmost, person icon with menu)
        Menu {
          Button("Play Service 🔑") {
            Task { await handleAddPlayAccount() }
          }
          Button("Chrome Profiles 👤") {
            Task { await handleAddProfileAccount() }
          }
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Add Account")

        Button(action: { Task { await syncAllAccounts(notify: true) } }) {
          Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .buttonStyle(.plain)
        .help("Sync All")

        Spacer()

        Button(action: { updaterController.checkForUpdates(nil) }) {
          Image(systemName: "arrow.down.to.line.compact")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .buttonStyle(.plain)
        .help("Check for Updates")

        Button(action: { NSApplication.shared.terminate(nil) }) {
          Image(systemName: "xmark")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .buttonStyle(.plain)
        .help("Quit")
      }
      .padding(.horizontal, 4)
    }
    .frame(width: 300, height: 400)
    .onAppear {
      requestNotificationPermission()
      loadAccounts()

      ChromeProfileService.shared.onAddSuccess = { profile in
        Task {
          await handleProfileAdded(profile: profile)
        }
      }
      Task {
        await syncChromeProfiles()
      }

      syncTimer?.invalidate()
      syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
        Task {
          await syncAllAccounts(notify: false)
        }
      }
    }
    .onDisappear {
      syncTimer?.invalidate()
      syncTimer = nil
    }
  }

  private func loadAccounts() {
    do {
      accounts = try modelContext.fetch(FetchDescriptor<Account>())
      notes = try modelContext.fetch(FetchDescriptor<Note>())
    } catch {
      accounts = []
      notes = []
    }
  }

  private func syncChromeProfiles() async {
    do {
      let currentProfiles = ChromeProfileService.shared.loadChromeProfiles()
      let currentProfileEmails = Set(currentProfiles.map { $0.email })

      let existingAccounts = try modelContext.fetch(
        FetchDescriptor<Account>(predicate: #Predicate { !$0.profileName.isEmpty })
      )

      for profile in currentProfiles {
        try addOrUpdateAccount(
          email: profile.email,
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
    } catch {}
  }

  private func addOrUpdateAccount(
    email: String,
    picture: String = "",
    profileName: String = "",
    masterToken: String = ""
  ) throws {
    let existingAccounts = try modelContext.fetch(
      FetchDescriptor<Account>(predicate: #Predicate { $0.email == email })
    )

    if let existingAccount = existingAccounts.first {
      if !profileName.isEmpty {
        existingAccount.profileName = profileName
      }
      if !masterToken.isEmpty {
        existingAccount.masterToken = masterToken
      }
    } else {
      let newAccount = Account(
        email: email, profileName: profileName, masterToken: masterToken)
      modelContext.insert(newAccount)
    }

    try modelContext.save()
    loadAccounts()
  }

  private func handleAddPlayAccount() async {
    do {
      ChromePlayService.shared.onLoginSuccess = { email, oauthToken in
        Task {
          await handlePlayLoginSuccess(email: email, oauthToken: oauthToken)
        }
      }
      try await ChromePlayService.shared.startLogin()
    } catch {}
  }

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {

      let masterToken = try await GoogleApiClient.shared.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      try addOrUpdateAccount(email: email, masterToken: masterToken)
      loadAccounts()
      sendNotification(title: "Account Added", body: "\(email) has been added")
    } catch {}
  }

  private func handleAddProfileAccount() async {
    do {
      ChromeProfileService.shared.onAddSuccess = { profile in
        Task {
          await handleProfileAdded(profile: profile)
        }
      }
      try await ChromeProfileService.shared.startAdd()
    } catch {}
  }

  private func handleProfileAdded(profile: Account) async {
    do {
      try addOrUpdateAccount(
        email: profile.email,
        profileName: profile.profileName,
        masterToken: profile.masterToken
      )
      loadAccounts()
      sendNotification(title: "Account Added", body: "\(profile.email) has been added")
    } catch {}
  }

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
      granted, error in
    }
  }

  private func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    UNUserNotificationCenter.current().add(request) { error in
    }
  }

  private func deleteAccount(_ account: Account) {
    let email = account.email

    if !account.profileName.isEmpty {
      try? ChromeProfileService.shared.deleteProfile(profileName: account.profileName)
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
    sendNotification(title: "Account Deleted", body: "\(email) has been deleted")
  }

  private func syncAllAccounts(notify: Bool = true) async {
    let playAccounts = accounts.filter { !$0.masterToken.isEmpty }
    let profileAccounts = accounts.filter {
      !$0.profileName.isEmpty && $0.masterToken.isEmpty
    }

    if playAccounts.isEmpty && profileAccounts.isEmpty {
      return
    }

    let totalCount = playAccounts.count + profileAccounts.count
    if notify {
      sendNotification(
        title: "Sync Started", body: "Syncing \(totalCount) account\(totalCount > 1 ? "s" : "")")
    }

    var successCount = 0
    var failCount = 0

    for account in playAccounts {
      errorMessages[account.email] = nil
      do {
        try await GoogleApiClient.shared.syncNotes(for: account, modelContext: modelContext)
        successCount += 1
      } catch {
        errorMessages[account.email] = error.localizedDescription
        failCount += 1
      }
    }

    if !profileAccounts.isEmpty {
      for account in profileAccounts {
        errorMessages[account.email] = nil
      }

      let errors =
        await ChromeProfileService.shared.syncMultipleAccounts(
          profileAccounts,
          modelContext: modelContext
        )

      for (email, error) in errors {
        errorMessages[email] = error.localizedDescription
        failCount += 1
      }

      successCount += profileAccounts.count - errors.count
    }

    loadAccounts()
    WidgetCenter.shared.reloadAllTimelines()

    if notify {
      let title = failCount == 0 ? "Sync Successful" : "Sync Failed"
      let body = "\(successCount) success, \(failCount) failed"
      sendNotification(title: title, body: body)
    }
  }
}

