import AppKit
import FirebaseAnalytics
import FirebaseCore
import Foundation
import SwiftData
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    HttpServer(modelContainer: ModelContainer.shared).start()
    FirebaseApp.configure()
    Analytics.setAnalyticsCollectionEnabled(true)
  }
}

@main
struct KeepApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

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
