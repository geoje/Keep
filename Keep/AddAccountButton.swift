import SwiftUI

struct AddAccountButton: View {
  let onPlayService: () -> Void
  let onChromeProfile: () -> Void

  var body: some View {
    Menu {
      Button("Play Service 🔑", action: onPlayService)
      Button("Chrome Profiles 👤", action: onChromeProfile)
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
  }
}
