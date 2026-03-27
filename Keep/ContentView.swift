import AppKit
import Sparkle
import SwiftData
import SwiftUI

struct ContentView: View {
  let modelContainer: ModelContainer

  @State private var accountManager: AccountManager
  @State private var syncTimer: Timer? = nil
  @State private var updaterController: SPUStandardUpdaterController = {
    SPUStandardUpdaterController(
      startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  }()

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self._accountManager = State(
      wrappedValue: AccountManager(modelContainer: modelContainer))
  }

  var body: some View {
    VStack(spacing: 0) {
      AccountListView(
        accounts: accountManager.accounts,
        notes: accountManager.notes,
        onDelete: accountManager.deleteAccount
      )

      Divider()

      // Bottom dock
      HStack(spacing: 0) {
        AddAccountButton(
          onPlayService: { Task { await accountManager.handleAddPlayAccount() } },
          onChromeProfile: { Task { await accountManager.handleAddProfileAccount() } }
        )

        Button(action: { Task { await accountManager.syncAllAccounts(notify: true) } }) {
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
    .frame(width: 360, height: 480)
    .onAppear {
      accountManager.setup()

      syncTimer?.invalidate()
      syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
        Task { await accountManager.syncAllAccounts(notify: false) }
      }
    }
    .onDisappear {
      syncTimer?.invalidate()
      syncTimer = nil
    }
  }
}

