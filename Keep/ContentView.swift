import AppKit
import SwiftData
import SwiftUI
import UserNotifications
import WidgetKit

struct ContentView: View {
  let modelContainer: ModelContainer

  @StateObject private var chromeDriverService = ChromeDriverService()

  @State private var chromePlayService: ChromePlayService?
  @State private var chromeProfileService: ChromeProfileService?

  @State private var accounts: [Account] = []
  @State private var notes: [Note] = []
  @State private var errorMessages: [String: String] = [:]
  @State private var loadingStates: [String: Bool] = [:]
  @State private var hoveredEmail: String? = nil
  @State private var showDeleteConfirm: Bool = false
  @State private var syncTimer: Timer? = nil

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

    ForEach(accounts) { account in
      let noteCount = noteService.getRootNotes(notes: notes, email: account.email).count
      let hasPlayService = !account.masterToken.isEmpty
      let hasProfile = !account.profileName.isEmpty
      let icon = hasPlayService && hasProfile ? "🔑👤" : hasPlayService ? "🔑" : hasProfile ? "👤" : ""
      let errorMessage = errorMessages[account.email]

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
      Task { await syncAllAccounts(notify: true) }
    }) {
      Label("Sync All", systemImage: "arrow.trianglehead.clockwise.icloud")
    }
    Button(action: {
      NSApplication.shared.terminate(nil)
    }) {
      Label("Quit", systemImage: "xmark.rectangle")
    }

    .onAppear {
      requestNotificationPermission()
      loadAccounts()

      if chromeProfileService == nil {
        chromeProfileService = ChromeProfileService(
          chromeDriverService: chromeDriverService)
        chromeProfileService?.onAddSuccess = { profile in
          Task {
            await handleProfileAdded(profile: profile)
          }
        }
        Task {
          await syncChromeProfiles()
        }
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
    guard let chromeProfileService = chromeProfileService else { return }

    do {
      let currentProfiles = chromeProfileService.loadChromeProfiles()
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
    } catch {}
  }

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {
      let googleApiClient = GoogleApiClient()
      let masterToken = try await googleApiClient.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      try addOrUpdateAccount(email: email, masterToken: masterToken)
      loadAccounts()
      sendNotification(title: "Account Added", body: "\(email) has been added")
    } catch {}
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

    let googleApiClient = GoogleApiClient()
    for account in playAccounts {
      errorMessages[account.email] = nil
      do {
        try await googleApiClient.syncNotes(for: account, modelContext: modelContext)
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
        await chromeProfileService?.syncMultipleAccounts(
          profileAccounts,
          modelContext: modelContext
        ) ?? [:]

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
