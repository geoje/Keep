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
              DispatchQueue.main.asyncAfter(deadline: .now()) {
                NSApplication.shared.terminate(self)
              }
            }
          }
      }
    }
    .modelContainer(ModelContainer.shared)
    .windowResizability(.contentSize)
  }
}
