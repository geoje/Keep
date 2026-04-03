import AppKit
import Sparkle
import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var syncTimer: Timer? = nil
  @State private var syncRotation: Double = 0
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
      HStack(spacing: 0) {
        Menu {
          Button("Play Service") { Task { await AccountService.shared.handleAddPlayAccount() } }
          Button("Chrome Profiles") {
            Task { await AccountService.shared.handleAddProfileAccount() }
          }
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .padding(.leading, 4)
        .help("Add Account")

        Button(action: { Task { await AccountService.shared.syncAllAccounts() } }) {
          Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .padding(8)
            .rotationEffect(.degrees(syncRotation))
        }
        .buttonStyle(.plain)
        .disabled(isSyncing)
        .help("Sync All")
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
    .modelContainer(ModelContainer.shared)
    .onAppear {
      AccountService.shared.setup()

      syncTimer?.invalidate()
      syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { _ in
        Task { await AccountService.shared.syncAllAccounts() }
      }
    }
    .onDisappear {
      syncTimer?.invalidate()
      syncTimer = nil
    }
  }
}
