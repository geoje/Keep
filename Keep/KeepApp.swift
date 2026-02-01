import SwiftData
import SwiftUI

@main
struct KeepApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        ContentView()
          .onOpenURL { url in
            if url.scheme == "https" {
              NSWorkspace.shared.open(url)
            }
          }
      }
    }
    .modelContainer(ModelContainer.shared)
    .windowResizability(.contentSize)
  }
}
