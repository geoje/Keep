import AppKit
import SwiftData
import SwiftUI

@main
struct KeepApp: App {
  var body: some Scene {
    MenuBarExtra {
      Text("Add Account").font(.subheadline).bold()
      Button("Play Service 🔑") {}
      Button("Chrome Profiles 👤") {}
      Divider()

      Text("chchch1213@\u{200C}gmail.com 🔑👤").font(.subheadline).bold()
      Text("3 Notes").font(.subheadline)
      Button("Delete") {}
      Divider()

      Text("chchch1215@\u{200C}gmail.com 👤").font(.subheadline).bold()
      Text("5 Notes").font(.subheadline)
      Button("Delete") {}
      Divider()

      Button(action: {}) {
        Label("Update Keep", systemImage: "arrow.down.circle")
      }
      Button(action: {}) {
        Label("Sync All", systemImage: "arrow.triangle.2.circlepath")
      }
      Button(action: {
        NSApplication.shared.terminate(nil)
      }) {
        Label("Quit", systemImage: "power")
      }
    } label: {
      if let image = NSImage(named: "MenuBarIcon") {
        Image(nsImage: image)
      } else {
        Image(systemName: "document.fill")
      }
    }
    .menuBarExtraStyle(.menu)
    .modelContainer(ModelContainer.shared)
  }
}
