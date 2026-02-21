import AppKit
import SwiftData
import SwiftUI

@main
struct KeepApp: App {
  var body: some Scene {
    MenuBarExtra {
      ContentView(modelContainer: ModelContainer.shared)
    } label: {
      if let image = NSImage(named: "MenuBarIcon") {
        Image(nsImage: image)
      } else {
        Image(systemName: "document.fill")
      }
    }
    .menuBarExtraStyle(.menu)
  }
}
