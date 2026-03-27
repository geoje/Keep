import Observation
import SwiftData
import SwiftUI
import UserNotifications
import WidgetKit

@MainActor
@Observable
final class AccountManager {
  var accounts: [Account] = []
  var notes: [Note] = []
  var errorMessages: [String: String] = [:]
  var syncingAccounts: Set<String> = []

  private let modelContainer: ModelContainer
  private var modelContext: ModelContext { modelContainer.mainContext }

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  func setup() {
    requestNotificationPermission()
    load()

    ChromeProfileService.shared.onAddSuccess = { [weak self] profile in
      Task { await self?.handleProfileAdded(profile: profile) }
    }
    Task { await syncChromeProfiles() }
  }

  func load() {
    do {
      accounts = try modelContext.fetch(FetchDescriptor<Account>())
      notes = try modelContext.fetch(FetchDescriptor<Note>())
    } catch {
      accounts = []
      notes = []
    }
  }

  func handleAddPlayAccount() async {
    do {
      ChromePlayService.shared.onLoginSuccess = { [weak self] email, oauthToken in
        Task { await self?.handlePlayLoginSuccess(email: email, oauthToken: oauthToken) }
      }
      try await ChromePlayService.shared.startLogin()
    } catch {}
  }

  func handleAddProfileAccount() async {
    do {
      ChromeProfileService.shared.onAddSuccess = { [weak self] profile in
        Task { await self?.handleProfileAdded(profile: profile) }
      }
      try await ChromeProfileService.shared.startAdd()
    } catch {}
  }

  private func handlePlayLoginSuccess(email: String, oauthToken: String) async {
    do {
      let masterToken = try await GoogleApiClient.shared.fetchMasterToken(
        email: email, oauthToken: oauthToken)

      try addOrUpdateAccount(email: email, masterToken: masterToken)
      load()

      if let account = try? modelContext.fetch(
        FetchDescriptor<Account>(predicate: #Predicate { $0.email == email })
      ).first, account.picture.isEmpty {
        let accessToken = try? await GoogleApiClient.shared.getAccessToken(
          for: account, modelContext: modelContext)
        if let token = accessToken,
          let pictureURL = try? await GoogleApiClient.shared.fetchProfileURL(accessToken: token)
        {
          account.picture = pictureURL
          try? modelContext.save()
          load()
        }
      }

      sendNotification(title: "Account Added", body: email)
    } catch {}
  }

  private func handleProfileAdded(profile: Account) async {
    do {
      try addOrUpdateAccount(
        email: profile.email,
        picture: profile.picture,
        profileName: profile.profileName,
        masterToken: profile.masterToken
      )
      load()
      sendNotification(title: "Account Added", body: profile.email)
    } catch {}
  }

  func deleteAccount(_ account: Account) {
    if !account.profileName.isEmpty {
      try? ChromeProfileService.shared.deleteProfile(profileName: account.profileName)
    }

    let existingNotes = try? modelContext.fetch(FetchDescriptor<Note>()).filter {
      $0.email == account.email
    }
    existingNotes?.forEach { modelContext.delete($0) }

    modelContext.delete(account)
    try? modelContext.save()
    load()
  }

  func syncAllAccounts() async {
    let playAccounts = accounts.filter { !$0.masterToken.isEmpty }
    let profileAccounts = accounts.filter { !$0.profileName.isEmpty && $0.masterToken.isEmpty }

    guard !playAccounts.isEmpty || !profileAccounts.isEmpty else { return }

    for account in playAccounts {
      errorMessages[account.email] = nil
      syncingAccounts.insert(account.email)
      do {
        try await GoogleApiClient.shared.syncNotes(for: account, modelContext: modelContext)
      } catch {
        errorMessages[account.email] = error.localizedDescription
      }
      syncingAccounts.remove(account.email)
    }

    for account in profileAccounts {
      errorMessages[account.email] = nil
      syncingAccounts.insert(account.email)
      do {
        try await ChromeProfileService.shared.syncAccount(account, modelContext: modelContext)
      } catch {
        errorMessages[account.email] = error.localizedDescription
      }
      syncingAccounts.remove(account.email)
    }

    load()
    WidgetCenter.shared.reloadAllTimelines()
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
          picture: profile.picture,
          profileName: profile.profileName
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
      load()
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

    if let existing = existingAccounts.first {
      if !picture.isEmpty { existing.picture = picture }
      if !profileName.isEmpty { existing.profileName = profileName }
      if !masterToken.isEmpty { existing.masterToken = masterToken }
    } else {
      modelContext.insert(Account(email: email, profileName: profileName, masterToken: masterToken))
    }

    try modelContext.save()
    load()
  }

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
  }

  func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { _ in }
  }
}
