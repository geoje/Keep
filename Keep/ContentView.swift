import AppKit
import Sparkle
import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var syncTimer: Timer? = nil
  @State private var syncRotation: Double = 0
  @AppStorage(SyncInterval.userDefaultsKey) private var syncIntervalRaw: String =
    SyncInterval.defaultValue.rawValue
  @State private var updaterController: SPUStandardUpdaterController = {
    SPUStandardUpdaterController(
      startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  }()

  var body: some View {
    let isSyncing = !AccountService.shared.syncingAccounts.isEmpty
    VStack(spacing: 0) {
      AccountListView()

      Divider()

      // Bottom dock
      HStack(spacing: 4) {
        Menu {
          Button("Play Service") { Task { await AccountService.shared.handleAddPlayAccount() } }
          Button("Chrome Profiles") {
            Task { await AccountService.shared.handleAddProfileAccount() }
          }
        } label: {
          Image(systemName: "plus")
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .padding(.vertical, 4)
        .help("Add Account")

        Menu {
          Button("Sync now") { Task { await AccountService.shared.syncAllAccounts() } }
            .disabled(isSyncing)

          Divider()

          ForEach(SyncInterval.allCases, id: \.self) { interval in
            Button {
              syncIntervalRaw = interval.rawValue
            } label: {
              if interval.rawValue == syncIntervalRaw {
                Label(interval.title, systemImage: "checkmark")
              } else {
                Text(interval.title)
              }
            }
          }
        } label: {
          Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(syncRotation))
        }
        .onChange(of: isSyncing) { _, syncing in
          if syncing {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
              syncRotation = 360
            }
          } else {
            withAnimation(.default) {
              syncRotation = 0
            }
          }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .padding(.vertical, 4)
        .help("Sync")

        Spacer()

        Button(action: { updaterController.checkForUpdates(nil) }) {
          Image(systemName: "arrow.down.to.line.compact")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(4)
        .help("Check for Updates")

        Button(action: { NSApplication.shared.terminate(nil) }) {
          Image(systemName: "xmark")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(4)
        .help("Quit")
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
    .modelContainer(ModelContainer.shared)
    .onAppear {
      AccountService.shared.setup()
      startSyncTimer()
    }
    .onChange(of: syncIntervalRaw) {
      startSyncTimer()
    }
    .onDisappear {
      syncTimer?.invalidate()
      syncTimer = nil
    }
  }

  private func startSyncTimer() {
    syncTimer?.invalidate()
    syncTimer = nil
    let interval = SyncInterval(rawValue: syncIntervalRaw) ?? SyncInterval.defaultValue
    guard let seconds = interval.seconds else { return }
    syncTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { _ in
      Task { await AccountService.shared.syncAllAccounts() }
    }
  }
}
