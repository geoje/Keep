import AppKit
import Foundation
import SwiftData
import SwiftUI

@main
struct KeepApp: App {
  init() {
    let httpServer = HttpServer(modelContainer: ModelContainer.shared)
    httpServer.start()
  }

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
